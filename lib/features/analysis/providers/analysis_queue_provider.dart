// Analiz kuyruğu state'i: bekleyen screenshot'ları profile'a göre (seri ya da
// paralel worker havuzu) Gemini'ye gönderir, ilerlemeyi yayınlar, free
// limitini, günlük kotayı ve iptali ele alır.
import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/constants/ai_constants.dart';
import '../../../core/constants/ai_rate_profile.dart';
import '../../../core/models/screenshot_category.dart';
import '../../../core/models/screenshot_entry.dart';
import '../../../core/services/daily_quota_tracker.dart';
import '../../../core/services/entitlement_service.dart';
import '../../gallery/data/screenshot_repository.dart';
import '../data/analysis_exceptions.dart';
import '../data/analysis_result.dart';
import '../data/screenshot_analyzer.dart';

/// Kuyruğun yaşam döngüsü durumları.
enum AnalysisQueueStatus {
  /// Kuyruk boşta; bekleyen varsa banner "analiz et" önerir.
  idle,

  /// Analiz sürüyor; ilerleme [AnalysisQueueState.done]/[AnalysisQueueState.total].
  running,

  /// Tur bitti (ya da iptal edildi); banner özet gösterir.
  completed,

  /// Denenen tüm istekler başarısız oldu (ağ/servis sorunu olasılığı yüksek).
  failed,

  /// Free analiz hakkı doldu; paywall önerilir.
  limitReached,

  /// Ücretsiz katmanın günlük istek tavanına ulaşıldı; yarın devam eder.
  dailyCapReached,
}

/// Başarıyla analiz edilen tek öğe — UI'daki "uçan thumbnail" animasyonunu
/// ve kategori yığın sayaçlarını besler.
class AnalyzedItem {
  const AnalyzedItem({required this.assetId, required this.category});

  final String assetId;
  final ScreenshotCategory category;
}

/// Kuyruğun anlık görünümü (immutable).
class AnalysisQueueState {
  const AnalysisQueueState({
    this.status = AnalysisQueueStatus.idle,
    this.done = 0,
    this.failed = 0,
    this.total = 0,
    this.recent = const [],
    this.categoryCounts = const {},
    this.freeQuotaExhausted = false,
  });

  /// [recent] listesinde tutulan en fazla öğe sayısı — animasyon için
  /// yalnız son tamamlananlar gerekir, sınırsız büyüme istenmez.
  static const int maxRecentItems = 16;

  final AnalysisQueueStatus status;

  /// Bu turda başarıyla analiz edilen sayı.
  final int done;

  /// Bu turda hata alan sayı.
  final int failed;

  /// Bu turda hedeflenen toplam (free'de kalan hakla sınırlı).
  final int total;

  /// Bu turda son tamamlanan öğeler (en eski → en yeni, en fazla
  /// [maxRecentItems]). UI diff'leyerek yeni tamamlananları animasyonla oynatır.
  final List<AnalyzedItem> recent;

  /// Bu turda kategori başına başarı sayısı (kategori yığınları için).
  final Map<ScreenshotCategory, int> categoryCounts;

  /// Tur [AnalysisQueueStatus.limitReached] ile bittiğinde haftalık free
  /// kotanın gerçekten tükendiğini ayırt eder (trial sınırı / kotasız
  /// başlama durumlarından farklı) — milestone sayfası yalnız bunda açılır.
  final bool freeQuotaExhausted;

  bool get isRunning => status == AnalysisQueueStatus.running;

  /// Başarılı bir analiz sonrası yeni state: sayaç, sınırlı [recent] listesi
  /// ve kategori sayacı birlikte güncellenir (saf, test edilebilir).
  AnalysisQueueState afterSuccess(AnalyzedItem item) {
    final List<AnalyzedItem> appended = [...recent, item];
    return copyWith(
      done: done + 1,
      recent: appended.length > maxRecentItems
          ? appended.sublist(appended.length - maxRecentItems)
          : appended,
      categoryCounts: {
        ...categoryCounts,
        item.category: (categoryCounts[item.category] ?? 0) + 1,
      },
    );
  }

  AnalysisQueueState copyWith({
    AnalysisQueueStatus? status,
    int? done,
    int? failed,
    int? total,
    List<AnalyzedItem>? recent,
    Map<ScreenshotCategory, int>? categoryCounts,
    bool? freeQuotaExhausted,
  }) {
    return AnalysisQueueState(
      status: status ?? this.status,
      done: done ?? this.done,
      failed: failed ?? this.failed,
      total: total ?? this.total,
      recent: recent ?? this.recent,
      categoryCounts: categoryCounts ?? this.categoryCounts,
      freeQuotaExhausted: freeQuotaExhausted ?? this.freeQuotaExhausted,
    );
  }
}

/// Tekil analiz denemesinin sonucu (detay ekranındaki "şimdi analiz et").
enum SingleAnalysisOutcome { success, limitReached, failed }

final analysisQueueProvider =
    NotifierProvider<AnalysisQueueNotifier, AnalysisQueueState>(
      AnalysisQueueNotifier.new,
    );

class AnalysisQueueNotifier extends Notifier<AnalysisQueueState> {
  bool _cancelRequested = false;

  /// Aktif turun kimliği: `reset()` bunu artırır, böylece arka planda süren
  /// eski `start()`/`simulate()` sıfırlamadan sonra state'i EZEMEZ (çarpı →
  /// "Sıfırla" anında ve kalıcı temizlenir).
  int _runId = 0;

  /// Ücretsiz katmanın günlük istek tavanına bu turda ulaşıldı mı.
  bool _dailyCapHit = false;

  /// Worker'lar arası paylaşılan global tempo saati (`minRequestGap`).
  DateTime _nextRequestSlot = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  AnalysisQueueState build() => const AnalysisQueueState();

  /// Bekleyen tüm screenshot'ları [AiConfig.activeProfile] tempo/eşzamanlılık
  /// ayarıyla analiz eder. Free kullanıcıda kalan hak kadar işlenir; hak
  /// biterse [limitReached], günlük kota dolarsa [dailyCapReached].
  Future<void> start() async {
    if (state.isRunning) return;

    final ScreenshotRepository repo = ref.read(screenshotRepositoryProvider);
    final List<ScreenshotEntry> pending = repo
        .sortedEntries()
        .where((entry) => entry.isPending)
        .toList();
    if (pending.isEmpty) return;

    // 7 gün boşta kalan kullanıcı taze haftalık kotayla başlasın.
    ref.read(entitlementProvider.notifier).ensureWeeklyWindow();
    final EntitlementState entitlement = ref.read(entitlementProvider);
    if (!entitlement.canAnalyze) {
      state = AnalysisQueueState(
        status: AnalysisQueueStatus.limitReached,
        freeQuotaExhausted: _isFreeQuotaExhausted(entitlement),
      );
      return;
    }
    // Trial penceresindeki Pro kullanıcı sınırlı; kalıcı Pro sınırsız.
    final int budget = switch (entitlement) {
      EntitlementState(isInTrialWindow: true) => min(
        pending.length,
        entitlement.remainingTrialAnalysis + entitlement.analysisCredits,
      ),
      EntitlementState(isPro: true) => pending.length,
      _ => min(pending.length, entitlement.totalRemainingAnalysis),
    };

    _cancelRequested = false;
    _dailyCapHit = false;
    _nextRequestSlot = DateTime.now();
    final int runId = ++_runId;
    state = AnalysisQueueState(
      status: AnalysisQueueStatus.running,
      total: budget,
    );

    final AiRateProfile profile = AiConfig.activeProfile;
    final Queue<ScreenshotEntry> queue = Queue.of(pending.take(budget));
    await Future.wait([
      for (int i = 0; i < profile.concurrency; i++)
        _worker(repo, queue, profile, runId),
    ]);

    // Tur sıfırlandıysa (reset) bitiş state'ini yazma.
    if (_runId != runId) return;
    final AnalysisQueueStatus finalStatus = _finalStatus(pending.length);
    state = state.copyWith(
      status: finalStatus,
      freeQuotaExhausted:
          finalStatus == AnalysisQueueStatus.limitReached &&
          _isFreeQuotaExhausted(ref.read(entitlementProvider)),
    );
  }

  /// Haftalık free kota bu turda gerçekten tükendi mi (milestone tetiği).
  bool _isFreeQuotaExhausted(EntitlementState entitlement) =>
      !entitlement.isPro && entitlement.remainingFreeAnalysis == 0;

  /// Ortak kuyruktan öğe çekip işleyen bir worker; havuzdaki eşzamanlılık
  /// kadar paralel çalışır. Kota/iptal koşullarında sessizce durur.
  Future<void> _worker(
    ScreenshotRepository repo,
    Queue<ScreenshotEntry> queue,
    AiRateProfile profile,
    int runId,
  ) async {
    final DailyQuotaTracker quota = ref.read(dailyQuotaTrackerProvider);
    while (_runId == runId &&
        !_cancelRequested &&
        !_dailyCapHit &&
        queue.isNotEmpty) {
      if (!quota.canRequest(profile.dailyCap)) {
        _dailyCapHit = true;
        return;
      }
      final ScreenshotEntry entry = queue.removeFirst();
      await _waitForSlot(profile.minRequestGap);
      await _analyzeEntry(repo, entry, quota, runId);
    }
  }

  /// Global tempo penceresini bekler; `minRequestGap` sıfırsa anında döner.
  Future<void> _waitForSlot(Duration gap) async {
    if (gap == Duration.zero) return;
    final DateTime now = DateTime.now();
    final DateTime slot = _nextRequestSlot.isAfter(now)
        ? _nextRequestSlot
        : now;
    _nextRequestSlot = slot.add(gap);
    final Duration wait = slot.difference(now);
    if (wait > Duration.zero) await Future<void>.delayed(wait);
  }

  /// Kuyruktaki tek öğeyi işler; hata sayaçlara yansır, akış devam eder.
  Future<void> _analyzeEntry(
    ScreenshotRepository repo,
    ScreenshotEntry entry,
    DailyQuotaTracker quota,
    int runId,
  ) async {
    final AssetEntity? asset = repo.assetFor(entry.assetId);
    if (asset == null) {
      if (_runId == runId) state = state.copyWith(failed: state.failed + 1);
      return;
    }
    try {
      await quota.register();
      final AnalysisResult result = await ref
          .read(screenshotAnalyzerProvider)
          .analyze(asset);
      await repo.saveAnalysis(
        assetId: entry.assetId,
        category: result.category,
        tags: result.tags,
        ocrText: result.ocrText,
      );
      await ref.read(entitlementProvider.notifier).registerAnalysis(1);
      // Sıfırlandıysa analizi kaydettik ama state'i güncelleme.
      if (_runId != runId) return;
      state = state.afterSuccess(
        AnalyzedItem(assetId: entry.assetId, category: result.category),
      );
    } on AnalysisRateLimitException catch (error) {
      debugPrint('Günlük kota hatası (${entry.assetId}): $error');
      _dailyCapHit = true;
    } catch (error, stackTrace) {
      debugPrint('Analiz hatası (${entry.assetId}): $error\n$stackTrace');
      if (_runId == runId) state = state.copyWith(failed: state.failed + 1);
    }
  }

  /// Tur sonunda banner'da gösterilecek durumu belirler.
  AnalysisQueueStatus _finalStatus(int pendingCount) {
    if (_dailyCapHit) return AnalysisQueueStatus.dailyCapReached;
    if (state.done == 0 && state.failed > 0) return AnalysisQueueStatus.failed;
    final bool moreLeft = pendingCount > state.done + state.failed;
    if (moreLeft && !ref.read(entitlementProvider).canAnalyze) {
      return AnalysisQueueStatus.limitReached;
    }
    return AnalysisQueueStatus.completed;
  }

  /// Detay ekranından tek screenshot analizi. Kuyruk çalışıyorsa reddedilir.
  Future<SingleAnalysisOutcome> analyzeSingle(String assetId) async {
    if (state.isRunning) return SingleAnalysisOutcome.failed;
    ref.read(entitlementProvider.notifier).ensureWeeklyWindow();
    if (!ref.read(entitlementProvider).canAnalyze) {
      return SingleAnalysisOutcome.limitReached;
    }

    final ScreenshotRepository repo = ref.read(screenshotRepositoryProvider);
    final AssetEntity? asset = repo.assetFor(assetId);
    if (asset == null) return SingleAnalysisOutcome.failed;

    try {
      final AnalysisResult result = await ref
          .read(screenshotAnalyzerProvider)
          .analyze(asset);
      await repo.saveAnalysis(
        assetId: assetId,
        category: result.category,
        tags: result.tags,
        ocrText: result.ocrText,
      );
      await ref.read(entitlementProvider.notifier).registerAnalysis(1);
      return SingleAnalysisOutcome.success;
    } catch (error, stackTrace) {
      debugPrint('Tekil analiz hatası ($assetId): $error\n$stackTrace');
      return SingleAnalysisOutcome.failed;
    }
  }

  /// DEBUG: API/quota harcamadan analiz animasyonunu denemek için sahte bir
  /// tur oynatır — Gemini'yi çağırmaz, entitlement/kota tüketmez, veriyi
  /// değiştirmez; yalnız state akışını (running → afterSuccess'ler → completed)
  /// gerçekçi, düzensiz bir kadansla taklit eder. Gerçek asset id'leri kullanır
  /// ki uçan thumbnail'lar doğru görselle çizilsin.
  Future<void> simulate({int count = 12}) async {
    assert(kDebugMode, 'simulate yalnız debug modunda çağrılmalıdır');
    if (state.isRunning) return;

    final ScreenshotRepository repo = ref.read(screenshotRepositoryProvider);
    final List<ScreenshotEntry> entries = repo.sortedEntries();
    if (entries.isEmpty) return;

    final Random random = Random();
    // Yalnız halihazırda kartı görünen (dolu) kategorilere ata ki uçan
    // thumbnail'lar ekranda gerçekten var olan karolara insin; hiç yoksa
    // tüm kategorilere düş (ilk kurulum senaryosu).
    final List<ScreenshotCategory> visibleCategories = [
      for (final category in ScreenshotCategory.values)
        if (entries.any((entry) => entry.category == category)) category,
    ];
    final List<ScreenshotCategory> categories = visibleCategories.isNotEmpty
        ? visibleCategories
        : ScreenshotCategory.values;
    final int total = min(count, entries.length);

    _cancelRequested = false;
    final int runId = ++_runId;
    state = AnalysisQueueState(
      status: AnalysisQueueStatus.running,
      total: total,
    );

    for (int i = 0; i < total && !_cancelRequested && _runId == runId; i++) {
      // Gemini dönüşlerinin düzensiz temposunu taklit eden gecikme.
      await Future<void>.delayed(
        Duration(milliseconds: 250 + random.nextInt(450)),
      );
      if (_cancelRequested || _runId != runId) break;
      state = state.afterSuccess(
        AnalyzedItem(
          assetId: entries[i].assetId,
          category: categories[random.nextInt(categories.length)],
        ),
      );
    }

    if (_runId != runId) return;
    state = state.copyWith(status: AnalysisQueueStatus.completed);
  }

  /// Koşan kuyruğu nazikçe durdurur (aktif istek biter, yenisi başlamaz);
  /// şimdiye inen fotoğraflarla özet gösterilir.
  void cancel() => _cancelRequested = true;

  /// Turu tamamen sıfırlar: arka planda süren tur da state'i ezemez, kart
  /// anında boşta duruma döner. Çarpı → "Sıfırla" bunu çağırır.
  void reset() {
    _cancelRequested = true;
    _runId++;
    state = const AnalysisQueueState();
  }

  /// Tur sonucu banner'ını kapatır.
  void dismiss() {
    if (!state.isRunning) state = const AnalysisQueueState();
  }
}

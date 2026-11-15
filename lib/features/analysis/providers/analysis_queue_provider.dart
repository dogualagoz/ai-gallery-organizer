// Analiz kuyruğu state'i: bekleyen screenshot'ları profile'a göre (seri ya da
// paralel worker havuzu) Gemini'ye gönderir, ilerlemeyi yayınlar, free
// limitini, günlük kotayı ve iptali ele alır.
import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/constants/ai_constants.dart';
import '../../../core/constants/ai_rate_profile.dart';
import '../../../core/models/screenshot_category.dart';
import '../../../core/models/screenshot_entry.dart';
import '../../../core/services/category_priors_service.dart';
import '../../../core/services/daily_quota_tracker.dart';
import '../../../core/services/entitlement_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../gallery/data/screenshot_repository.dart';
import '../data/analysis_exceptions.dart';
import '../data/analysis_result.dart';
import '../data/screenshot_analyzer.dart';
import 'analysis_queue_simulator.dart';
import 'analysis_queue_state.dart';

export 'analysis_queue_state.dart';

final analysisQueueProvider =
    NotifierProvider<AnalysisQueueNotifier, AnalysisQueueState>(
      AnalysisQueueNotifier.new,
    );

class AnalysisQueueNotifier extends Notifier<AnalysisQueueState> {
  bool _cancelRequested = false;

  /// Son tur kullanıcı tarafından durduruldu/sıfırlandı mı; yeni tur
  /// başlayınca temizlenir (bkz. [stoppedByUser]).
  bool _stoppedByUser = false;

  /// Aktif turun kimliği: `reset()` bunu artırır, böylece arka planda süren
  /// eski `start()`/`simulate()` sıfırlamadan sonra state'i EZEMEZ (çarpı →
  /// "Sıfırla" anında ve kalıcı temizlenir).
  int _runId = 0;

  /// Detay ekranından tek tek analiz edilen id'ler; kuyruk bunları atlar
  /// (aynı screenshot için çift Gemini çağrısı ve çift kredi düşümü olmasın).
  final Set<String> _inFlightSingles = {};

  /// Ücretsiz katmanın günlük istek tavanına bu turda ulaşıldı mı.
  bool _dailyCapHit = false;

  /// Worker'lar arası paylaşılan global tempo saati (`minRequestGap`).
  DateTime _nextRequestSlot = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  AnalysisQueueState build() => const AnalysisQueueState();

  /// [assetIds] kayıtlarını yeniden analize hazırlar ve turu yalnız onlarla
  /// başlatır ("yeniden analiz et"). Kayıtlar işaretlenince döner; tur arka
  /// planda sürer, ilerleme durum modülünde izlenir.
  Future<void> reanalyze(List<String> assetIds) async {
    await ref.read(screenshotRepositoryProvider).markManyPending(assetIds);
    unawaited(start(onlyAssetIds: assetIds));
  }

  /// Bekleyen screenshot'ları [AiConfig.activeProfile] tempo/eşzamanlılık
  /// ayarıyla analiz eder. Free kullanıcıda kalan hak kadar işlenir; hak
  /// biterse [limitReached], günlük kota dolarsa [dailyCapReached].
  ///
  /// [onlyAssetIds] verilirse yalnız o id'lerdeki bekleyen kayıtlar işlenir
  /// (kategori içinde "yeniden analiz et"); verilmezse tüm bekleyen galeri.
  Future<void> start({Iterable<String>? onlyAssetIds}) async {
    if (state.isRunning) return;
    _stoppedByUser = false;

    final ScreenshotRepository repo = ref.read(screenshotRepositoryProvider);
    final List<ScreenshotEntry> pending = _pendingFor(repo, onlyAssetIds);
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
    final int budget = _budgetFor(entitlement, pending.length);

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

  /// Turda işlenecek bekleyenler: tekil analizi sürenler hariç, [onlyAssetIds]
  /// verildiyse yalnız onlar.
  List<ScreenshotEntry> _pendingFor(
    ScreenshotRepository repo,
    Iterable<String>? onlyAssetIds,
  ) {
    final Set<String>? scope = onlyAssetIds?.toSet();
    return repo
        .pendingEntries()
        .where((entry) => !_inFlightSingles.contains(entry.assetId))
        .where((entry) => scope == null || scope.contains(entry.assetId))
        .toList();
  }

  /// Bu turda analiz edilebilecek sayı: trial penceresindeki Pro sınırlı,
  /// kalıcı Pro sınırsız, free kalan hak + kredi kadar.
  int _budgetFor(EntitlementState entitlement, int pendingCount) =>
      switch (entitlement) {
        EntitlementState(isInTrialWindow: true) => min(
          pendingCount,
          entitlement.remainingTrialAnalysis + entitlement.analysisCredits,
        ),
        EntitlementState(isPro: true) => pendingCount,
        _ => min(pendingCount, entitlement.totalRemainingAnalysis),
      };

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
      state = state.copyWith(active: [...state.active, entry.assetId]);
      await _waitForSlot(profile.minRequestGap);
      // Tempo beklerken tur iptal/sıfırlandıysa istek atılmaz (kota/maliyet).
      if (_runId != runId || _cancelRequested) return;
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
      _settle(entry.assetId, runId, failed: true);
      return;
    }
    try {
      await quota.register();
      // "Yarıda kes" (cancel) ya da "Sıfırla" (reset) turu geçersiz kılar:
      // durdurma anında dönen in-flight sonuç kaydedilmez, kredi harcanmaz.
      final ScreenshotCategory? refined = await _analyzeAndPersist(
        repo,
        asset,
        entry.assetId,
        isStale: () => _runId != runId,
      );
      // Kayıt sürerken sıfırlandıysa analiz kaydedildi ama state'e dokunma.
      if (refined == null || _runId != runId) return;
      state = state.afterSuccess(
        AnalyzedItem(assetId: entry.assetId, category: refined),
      );
    } on AnalysisRateLimitException catch (error, stackTrace) {
      logError('Günlük kota hatası (${entry.assetId})', error, stackTrace);
      _dailyCapHit = true;
      _settle(entry.assetId, runId);
    } catch (error, stackTrace) {
      logError('Analiz hatası (${entry.assetId})', error, stackTrace);
      _settle(entry.assetId, runId, failed: true);
    }
  }

  /// Başarısız/yarıda kalan öğe işlenenlerden düşer; [failed] ise sayılır.
  void _settle(String assetId, int runId, {bool failed = false}) {
    if (_runId != runId) return;
    state = state.copyWith(
      failed: failed ? state.failed + 1 : null,
      active: state.withoutActive(assetId),
    );
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

  /// Detay ekranından tek screenshot analizi. Kuyruk çalışıyorsa ya da aynı
  /// screenshot zaten analiz ediliyorsa reddedilir.
  Future<SingleAnalysisOutcome> analyzeSingle(String assetId) async {
    if (state.isRunning) return SingleAnalysisOutcome.failed;
    ref.read(entitlementProvider.notifier).ensureWeeklyWindow();
    if (!ref.read(entitlementProvider).canAnalyze) {
      return SingleAnalysisOutcome.limitReached;
    }

    final ScreenshotRepository repo = ref.read(screenshotRepositoryProvider);
    final AssetEntity? asset = repo.assetFor(assetId);
    if (asset == null) return SingleAnalysisOutcome.failed;
    if (!_inFlightSingles.add(assetId)) return SingleAnalysisOutcome.failed;

    try {
      await ref.read(dailyQuotaTrackerProvider).register();
      await _analyzeAndPersist(repo, asset, assetId);
      return SingleAnalysisOutcome.success;
    } on AnalysisRateLimitException catch (error, stackTrace) {
      logError('Günlük kota hatası ($assetId)', error, stackTrace);
      return SingleAnalysisOutcome.failed;
    } catch (error, stackTrace) {
      logError('Tekil analiz hatası ($assetId)', error, stackTrace);
      return SingleAnalysisOutcome.failed;
    } finally {
      _inFlightSingles.remove(assetId);
    }
  }

  /// Analiz → cihaz içi kişiselleştirme → kayıt → kredi düşümü zinciri.
  /// Kaydedilen kategoriyi döner; [isStale] analiz bittiğinde true ise (tur
  /// iptal/sıfırlandı) hiçbir şey kaydedilmez ve null döner.
  Future<ScreenshotCategory?> _analyzeAndPersist(
    ScreenshotRepository repo,
    AssetEntity asset,
    String assetId, {
    bool Function()? isStale,
  }) async {
    final AnalysisResult result = await ref
        .read(screenshotAnalyzerProvider)
        .analyze(asset);
    if (isStale?.call() ?? false) return null;
    // Cihaz içi kişiselleşme: kullanıcı düzeltmelerinden öğrenilen net bir
    // sinyal varsa AI kararını güncelle, yoksa AI'ınkini koru.
    final ScreenshotCategory refined =
        ref.read(categoryPriorsProvider.notifier).suggest(result.tags) ??
        result.category;
    await repo.saveAnalysis(
      assetId: assetId,
      category: refined,
      aiCategory: result.category,
      tags: result.tags,
      ocrText: result.ocrText,
    );
    await ref.read(entitlementProvider.notifier).registerAnalysis(1);
    return refined;
  }

  /// DEBUG: API/quota harcamadan analiz animasyonunu denemek için sahte bir
  /// tur oynatır — Gemini'yi çağırmaz, entitlement/kota tüketmez, veriyi
  /// değiştirmez; yalnız state akışını (running → afterSuccess'ler → completed)
  /// gerçekçi, düzensiz bir kadansla taklit eder. Gerçek asset id'leri kullanır
  /// ki uçan thumbnail'lar doğru görselle çizilsin.
  Future<void> simulate({int count = 12}) async {
    assert(kDebugMode, 'simulate yalnız debug modunda çağrılmalıdır');
    if (state.isRunning) return;

    final Random random = Random();
    final List<AnalyzedItem> items = simulatedRun(
      ref.read(screenshotRepositoryProvider).sortedEntries(),
      count: count,
      random: random,
    );
    if (items.isEmpty) return;

    _cancelRequested = false;
    final int runId = ++_runId;
    state = AnalysisQueueState(
      status: AnalysisQueueStatus.running,
      total: items.length,
    );

    for (final AnalyzedItem item in items) {
      await Future<void>.delayed(simulatedDelay(random));
      if (_cancelRequested || _runId != runId) break;
      state = state.afterSuccess(item);
    }

    if (_runId != runId) return;
    state = state.copyWith(status: AnalysisQueueStatus.completed);
  }

  /// Koşan kuyruğu nazikçe durdurur (aktif istek biter, yenisi başlamaz);
  /// şimdiye inen fotoğraflarla özet gösterilir. Turu hemen tamamlanmış sayar
  /// ve `_runId`'yi artırır: arka planda süren `start()` ile in-flight
  /// istekler sonradan state'i EZEMEZ (özet kapatılsa bile kart geri gelmez).
  void cancel() {
    _cancelRequested = true;
    _stoppedByUser = true;
    _runId++;
    if (state.isRunning) {
      // Dönen sonuçlar artık kaydedilmez: işlenenler listesi de boşalır.
      state = state.copyWith(
        status: AnalysisQueueStatus.completed,
        active: const [],
      );
    }
  }

  /// Turu tamamen sıfırlar: arka planda süren tur da state'i ezemez, kart
  /// anında boşta duruma döner. Çarpı → "Sıfırla" bunu çağırır.
  void reset() {
    _cancelRequested = true;
    _stoppedByUser = true;
    _runId++;
    state = const AnalysisQueueState();
  }

  /// Son tur kullanıcı tarafından durduruldu/sıfırlandı mı (auto-sort bunu
  /// görürse turu kendiliğinden yeniden başlatmaz). Yeni `start()` temizler.
  bool get stoppedByUser => _stoppedByUser;

  /// Tur sonucu banner'ını kapatır.
  void dismiss() {
    if (!state.isRunning) state = const AnalysisQueueState();
  }
}

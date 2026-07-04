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

/// Kuyruğun anlık görünümü (immutable).
class AnalysisQueueState {
  const AnalysisQueueState({
    this.status = AnalysisQueueStatus.idle,
    this.done = 0,
    this.failed = 0,
    this.total = 0,
  });

  final AnalysisQueueStatus status;

  /// Bu turda başarıyla analiz edilen sayı.
  final int done;

  /// Bu turda hata alan sayı.
  final int failed;

  /// Bu turda hedeflenen toplam (free'de kalan hakla sınırlı).
  final int total;

  bool get isRunning => status == AnalysisQueueStatus.running;

  AnalysisQueueState copyWith({
    AnalysisQueueStatus? status,
    int? done,
    int? failed,
    int? total,
  }) {
    return AnalysisQueueState(
      status: status ?? this.status,
      done: done ?? this.done,
      failed: failed ?? this.failed,
      total: total ?? this.total,
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

    final EntitlementState entitlement = ref.read(entitlementProvider);
    if (!entitlement.canAnalyze) {
      state = const AnalysisQueueState(
        status: AnalysisQueueStatus.limitReached,
      );
      return;
    }
    final int budget = entitlement.isPro
        ? pending.length
        : min(pending.length, entitlement.totalRemainingAnalysis);

    _cancelRequested = false;
    _dailyCapHit = false;
    _nextRequestSlot = DateTime.now();
    state = AnalysisQueueState(
      status: AnalysisQueueStatus.running,
      total: budget,
    );

    final AiRateProfile profile = AiConfig.activeProfile;
    final Queue<ScreenshotEntry> queue = Queue.of(pending.take(budget));
    await Future.wait([
      for (int i = 0; i < profile.concurrency; i++) _worker(repo, queue, profile),
    ]);

    state = state.copyWith(status: _finalStatus(pending.length));
  }

  /// Ortak kuyruktan öğe çekip işleyen bir worker; havuzdaki eşzamanlılık
  /// kadar paralel çalışır. Kota/iptal koşullarında sessizce durur.
  Future<void> _worker(
    ScreenshotRepository repo,
    Queue<ScreenshotEntry> queue,
    AiRateProfile profile,
  ) async {
    final DailyQuotaTracker quota = ref.read(dailyQuotaTrackerProvider);
    while (!_cancelRequested && !_dailyCapHit && queue.isNotEmpty) {
      if (!quota.canRequest(profile.dailyCap)) {
        _dailyCapHit = true;
        return;
      }
      final ScreenshotEntry entry = queue.removeFirst();
      await _waitForSlot(profile.minRequestGap);
      await _analyzeEntry(repo, entry, quota);
    }
  }

  /// Global tempo penceresini bekler; `minRequestGap` sıfırsa anında döner.
  Future<void> _waitForSlot(Duration gap) async {
    if (gap == Duration.zero) return;
    final DateTime now = DateTime.now();
    final DateTime slot = _nextRequestSlot.isAfter(now) ? _nextRequestSlot : now;
    _nextRequestSlot = slot.add(gap);
    final Duration wait = slot.difference(now);
    if (wait > Duration.zero) await Future<void>.delayed(wait);
  }

  /// Kuyruktaki tek öğeyi işler; hata sayaçlara yansır, akış devam eder.
  Future<void> _analyzeEntry(
    ScreenshotRepository repo,
    ScreenshotEntry entry,
    DailyQuotaTracker quota,
  ) async {
    final AssetEntity? asset = repo.assetFor(entry.assetId);
    if (asset == null) {
      state = state.copyWith(failed: state.failed + 1);
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
      state = state.copyWith(done: state.done + 1);
    } on AnalysisRateLimitException catch (error) {
      debugPrint('Günlük kota hatası (${entry.assetId}): $error');
      _dailyCapHit = true;
    } catch (error, stackTrace) {
      debugPrint('Analiz hatası (${entry.assetId}): $error\n$stackTrace');
      state = state.copyWith(failed: state.failed + 1);
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

  /// Koşan kuyruğu nazikçe durdurur (aktif istek biter, yenisi başlamaz).
  void cancel() => _cancelRequested = true;

  /// Tur sonucu banner'ını kapatır.
  void dismiss() {
    if (!state.isRunning) state = const AnalysisQueueState();
  }
}

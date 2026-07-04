// Analiz kuyruğu state'i: bekleyen screenshot'ları sırayla Gemini'ye gönderir,
// ilerlemeyi yayınlar, free limiti ve iptali ele alır.
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/constants/ai_constants.dart';
import '../../../core/models/screenshot_entry.dart';
import '../../../core/services/entitlement_service.dart';
import '../../gallery/data/screenshot_repository.dart';
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

  @override
  AnalysisQueueState build() => const AnalysisQueueState();

  /// Bekleyen tüm screenshot'ları sırayla analiz eder.
  /// Free kullanıcıda kalan hak kadar işlenir; hak biterse [limitReached].
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
        : min(pending.length, entitlement.remainingAnalysis);

    _cancelRequested = false;
    state = AnalysisQueueState(
      status: AnalysisQueueStatus.running,
      total: budget,
    );

    for (final ScreenshotEntry entry in pending.take(budget)) {
      if (_cancelRequested) break;
      await _analyzeEntry(repo, entry);
      // Son öğeden sonra beklemeye gerek yok; aradakiler rate limit için yavaşlar.
      if (state.done + state.failed < budget && !_cancelRequested) {
        await Future<void>.delayed(AiConfig.activeProfile.minRequestGap);
      }
    }

    state = state.copyWith(status: _finalStatus(pending.length));
  }

  /// Kuyruktaki tek öğeyi işler; hata sayaçlara yansır, akış devam eder.
  Future<void> _analyzeEntry(
    ScreenshotRepository repo,
    ScreenshotEntry entry,
  ) async {
    final AssetEntity? asset = repo.assetFor(entry.assetId);
    if (asset == null) {
      state = state.copyWith(failed: state.failed + 1);
      return;
    }
    try {
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
    } catch (error, stackTrace) {
      debugPrint('Analiz hatası (${entry.assetId}): $error\n$stackTrace');
      state = state.copyWith(failed: state.failed + 1);
    }
  }

  /// Tur sonunda banner'da gösterilecek durumu belirler.
  AnalysisQueueStatus _finalStatus(int pendingCount) {
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

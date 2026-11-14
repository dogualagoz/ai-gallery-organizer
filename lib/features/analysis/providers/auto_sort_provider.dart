// Pro kullanıcılar için yeni screenshot geldiğinde analiz kuyruğunu otomatik başlatır.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/screenshot_entry.dart';
import '../../../core/services/entitlement_service.dart';
import '../../../core/services/preferences_service.dart';
import '../../gallery/providers/gallery_provider.dart';
import 'analysis_queue_provider.dart';

/// Ana ekranda watch edilerek yaşatılır. Tetik "galeri değişti" değil, "bekleyen
/// sayısı ARTTI"dır: kullanıcının durdurduğu tur ya da başarısız öğeler
/// kendiliğinden yeniden başlamaz. Tur sürerken gelen yeni screenshot'lar tur
/// doğal biterse ardından işlenir; kullanıcı durdurduysa işlenmez. Pro + auto-sort
/// açık + kota var + kuyruk boşta koşulları her tetikte kontrol edilir.
final autoSortControllerProvider = Provider<void>((ref) {
  int? lastPending;
  bool deferred = false;

  int pendingNow() =>
      ref
          .read(galleryProvider)
          .value
          ?.where((ScreenshotEntry entry) => entry.isPending)
          .length ??
      0;

  bool canAutoStart() {
    final EntitlementState entitlement = ref.read(entitlementProvider);
    return entitlement.isPro &&
        entitlement.canAnalyze &&
        ref.read(autoSortEnabledProvider) &&
        !ref.read(analysisQueueProvider).isRunning;
  }

  void tryStart() {
    if (pendingNow() == 0) return;
    // Tur sürerken Pro'ya geçiş/auto-sort açılışı tur bitince karşılanır.
    if (ref.read(analysisQueueProvider).isRunning) {
      deferred = true;
      return;
    }
    if (!canAutoStart()) return;
    ref.read(analysisQueueProvider.notifier).start();
  }

  ref.listen<AsyncValue<List<ScreenshotEntry>>>(galleryProvider, (_, next) {
    final List<ScreenshotEntry>? entries = next.value;
    if (entries == null) return;
    final int pending = entries.where((entry) => entry.isPending).length;
    final bool grew = pending > (lastPending ?? 0);
    lastPending = pending;
    if (!grew) return;
    if (ref.read(analysisQueueProvider).isRunning) {
      deferred = true;
      return;
    }
    tryStart();
  });

  // Tur doğal bittiğinde, sürerken gelen yeni screenshot'lar için yeniden dene.
  ref.listen<AnalysisQueueState>(analysisQueueProvider, (previous, next) {
    if (previous?.isRunning != true || next.isRunning || !deferred) return;
    deferred = false;
    if (next.status != AnalysisQueueStatus.completed) return;
    if (ref.read(analysisQueueProvider.notifier).stoppedByUser) return;
    tryStart();
  });

  // Pro'ya geçiş ya da auto-sort'u açma: o ana kadar biriken bekleyenleri al.
  ref.listen<bool>(
    entitlementProvider.select((EntitlementState state) => state.isPro),
    (_, isPro) {
      if (isPro) tryStart();
    },
  );
  ref.listen<bool>(autoSortEnabledProvider, (_, enabled) {
    if (enabled) tryStart();
  });
});

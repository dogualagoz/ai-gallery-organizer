// Pro kullanıcılar için galeri eşitlemesi sonrası analiz kuyruğunu otomatik başlatır.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/screenshot_entry.dart';
import '../../../core/services/entitlement_service.dart';
import '../../../core/services/preferences_service.dart';
import '../../gallery/providers/gallery_provider.dart';
import 'analysis_queue_provider.dart';

/// Ana ekranda watch edilerek yaşatılır. Galeri verisi her güncellendiğinde
/// (sync ya da Hive değişikliği) koşulları kontrol eder: Pro + auto-sort
/// açık + bekleyen screenshot var + kuyruk boşta ise analizi başlatır.
/// `AnalysisQueueNotifier.start()` zaten çalışan bir turu no-op yaptığı için
/// tekrar tetiklenmesi (ör. her başarılı kayıtta) güvenlidir.
final autoSortControllerProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<List<ScreenshotEntry>>>(galleryProvider, (
    _,
    next,
  ) {
    final List<ScreenshotEntry>? entries = next.value;
    if (entries == null) return;
    if (!ref.read(entitlementProvider).isPro) return;
    if (!ref.read(autoSortEnabledProvider)) return;
    if (ref.read(analysisQueueProvider).isRunning) return;
    if (!entries.any((entry) => entry.isPending)) return;

    ref.read(analysisQueueProvider.notifier).start();
  });
});

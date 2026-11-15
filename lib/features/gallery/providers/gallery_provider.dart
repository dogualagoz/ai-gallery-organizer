// Galeri state'i: Hive'daki kayıt listesi + cihaz kütüphanesi eşitleme aksiyonu.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/screenshot_entry.dart';
import '../../../core/services/photo_permission_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/debounced_listen.dart';
import '../data/screenshot_repository.dart';

/// Galeri listesi. İlk açılışta cihazla otomatik eşitler; sonrasında
/// box değişikliklerini dinleyerek güncel kalır (AI analizi yazınca vs.).
/// Fotoğraf erişimi yoksa [PhotoAccessDeniedException] ile hata durumuna
/// geçer (boş galeri gibi görünmez); erişim düzeyi değişince yeniden eşitler.
final galleryProvider =
    AsyncNotifierProvider<GalleryNotifier, List<ScreenshotEntry>>(
      GalleryNotifier.new,
    );

class GalleryNotifier extends AsyncNotifier<List<ScreenshotEntry>> {
  @override
  Future<List<ScreenshotEntry>> build() async {
    final ScreenshotRepository repo = ref.watch(screenshotRepositoryProvider);

    // Toplu yazımlarda (sync/analiz) her put ayrı olay üretir; liste olaylar
    // durulunca tek seferde yenilenir.
    listenDebounced(
      ref,
      repo.watchChanges(),
      () => state = AsyncData(repo.sortedEntries()),
    );

    final PhotoAccess access = await ref.watch(photoAccessProvider.future);
    if (access == PhotoAccess.denied) throw const PhotoAccessDeniedException();

    // Açılışta cihazla eşitle: yeni screenshot'lar pending olarak gelir.
    // Diğer hatalarda mevcut local veriyle devam edilir (offline dostu).
    try {
      await repo.syncLibrary();
    } on PhotoAccessDeniedException {
      rethrow;
    } catch (error, stackTrace) {
      logError('Galeri eşitleme hatası', error, stackTrace);
    }
    return repo.sortedEntries();
  }

  /// Kullanıcının tetiklediği manuel eşitleme (pull-to-refresh / buton).
  /// İzin bu arada kaldırıldıysa erişim yeniden okunur; galeri izin
  /// durumuna kendiliğinden geçer.
  Future<void> sync() async {
    final ScreenshotRepository repo = ref.read(screenshotRepositoryProvider);
    try {
      await repo.syncLibrary();
    } on PhotoAccessDeniedException {
      await ref.read(photoAccessProvider.notifier).recheck();
      return;
    }
    state = AsyncData(repo.sortedEntries());
  }
}

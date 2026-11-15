// Cihaz fotoğraf kütüphanesinden ekran görüntüsü asset'lerini çeken kaynak
// (photo_manager); depo bunu Hive ile eşitler. Testlerde sahtesiyle değişir.
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/services/photo_permission_service.dart';
import '../../../core/utils/app_logger.dart';

/// iOS "Screenshots" akıllı albümünü okuyan kaynak.
class PhotoLibrarySource {
  const PhotoLibrarySource();

  /// Akıllı albümdeki tüm asset'leri döner. Erişim yoksa
  /// [PhotoAccessDeniedException] fırlatır.
  Future<List<AssetEntity>> fetchScreenshots() async {
    final PermissionState permission =
        await PhotoManager.requestPermissionExtend();
    // Boş liste dönülmez: erişimsizlik "hiç ekran görüntüsü yok" sanılmasın.
    if (!permission.hasAccess) throw const PhotoAccessDeniedException();

    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );

    // iOS, screenshot'ları sistem tarafında akıllı albümde toplar —
    // subtype filtresi yazmaya gerek yok, albümün kendisi filtredir.
    AssetPathEntity? screenshotAlbum;
    for (final AssetPathEntity path in paths) {
      if (path.albumTypeEx?.darwin?.subtype ==
          PMDarwinAssetCollectionSubtype.smartAlbumScreenshots) {
        screenshotAlbum = path;
        break;
      }
    }
    if (screenshotAlbum != null) {
      final int count = await screenshotAlbum.assetCountAsync;
      if (count > 0) {
        return screenshotAlbum.getAssetListRange(start: 0, end: count);
      }
    }

    // Simülatörde `simctl addmedia` ile eklenen görseller gerçek screenshot
    // olarak sınıflanmadığından Screenshots albümü boş kalır; debug'da tüm
    // görsellere düşülür ki AI akışı test edilebilsin.
    if (kDebugMode && paths.isNotEmpty) {
      logInfo('ScreenshotRepository: debug fallback — tüm görseller');
      final AssetPathEntity fallback = paths.first;
      final int count = await fallback.assetCountAsync;
      if (count == 0) return const [];
      return fallback.getAssetListRange(start: 0, end: count);
    }

    logInfo('ScreenshotRepository: Screenshots albümü bulunamadı/boş');
    return const [];
  }
}

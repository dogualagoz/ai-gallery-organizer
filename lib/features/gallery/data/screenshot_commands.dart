// Ekran görüntüsü yazma komutları (taşı, geri al, sil): onay, bildirim ve
// navigasyondan bağımsız; UI katmanı yalnız bunları çağırıp sonucu gösterir.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/models/screenshot_category.dart';
import '../../../core/models/screenshot_entry.dart';
import '../../../core/utils/app_logger.dart';
import 'screenshot_repository.dart';

final screenshotCommandsProvider = Provider<ScreenshotCommands>((ref) {
  return ScreenshotCommands(ref.watch(screenshotRepositoryProvider));
});

/// Galeri kayıtları ve fotoğraf kütüphanesi üzerindeki kullanıcı komutları.
class ScreenshotCommands {
  ScreenshotCommands(this._repo);

  final ScreenshotRepository _repo;

  /// [assetIds] kayıtlarını [category]'ye ya da (null ise) [boardId] panosuna
  /// taşır ([boardId] de null ise panodan çıkarır). Geri alma için taşıma
  /// öncesi yerleşimleri döndürür. Yarıda kalırsa taşınanlar geri sarılır ve
  /// hata yeniden fırlatılır: bir kısmı taşınmış halde kalmaz.
  Future<List<ScreenshotPlacement>> move(
    List<String> assetIds, {
    ScreenshotCategory? category,
    String? boardId,
  }) async {
    final List<ScreenshotPlacement> before = [
      for (final String assetId in assetIds)
        if (_repo.entryFor(assetId) case final ScreenshotEntry entry)
          ScreenshotPlacement.of(entry),
    ];
    try {
      if (category != null) {
        // Kategori değişimi kayıt başına düzeltme sinyali üretir; tek tek
        // yazılır.
        for (final String assetId in assetIds) {
          await _repo.setCategory(assetId, category);
        }
      } else {
        await _repo.assignManyToBoard(assetIds, boardId);
      }
    } catch (_) {
      await _rollBack(before);
      rethrow;
    }
    return before;
  }

  /// Kayıtları [move]'un döndürdüğü yerleşimlere geri yazar ("Geri al").
  Future<void> undoMove(List<ScreenshotPlacement> before) =>
      _repo.restorePlacements(before);

  /// Fotoğraf kütüphanesinden siler (onayı iOS'un kendi diyaloğu ister) ve
  /// silinenlerin kayıtlarını düşer. Silinenlerin kimliklerini döndürür; boş
  /// liste vazgeçildi demektir (kısmi silmede yalnız silinenler).
  Future<List<String>> delete(List<String> assetIds) async {
    final List<String> deleted = await PhotoManager.editor.deleteWithIds(
      assetIds,
    );
    await _repo.removeEntries(deleted);
    return deleted;
  }

  /// Yarıda kalan taşımayı geri sarar; geri sarma hatası asıl hatayı
  /// gölgelemesin diye yalnız loglanır.
  Future<void> _rollBack(List<ScreenshotPlacement> before) async {
    try {
      await undoMove(before);
    } catch (error, stackTrace) {
      logError('Taşıma geri alınamadı', error, stackTrace);
    }
  }
}

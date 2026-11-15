// Galeri listesinden tek geçişte türetilen görünümler: kategori/pano grupları,
// bekleyen sayısı ve içerikli kategoriler. Ekranlar galeriyi kendisi taramaz.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/screenshot_category.dart';
import '../../../core/models/screenshot_entry.dart';
import '../../../core/services/category_order_service.dart';
import 'gallery_provider.dart';

/// Galeri kayıtları (galeri sırasıyla); henüz yüklenmediyse boş.
final galleryEntriesProvider = Provider<List<ScreenshotEntry>>((ref) {
  return ref.watch(galleryProvider).value ?? const [];
});

/// Kategori → o kategorideki kayıtlar (galeri sırasıyla). Yalnız en az bir
/// kaydı olan kategoriler anahtar olarak bulunur.
///
/// Kayıtlar yerinde güncellendiği için map her galeri yayınında yeniden
/// kurulur (galeri listesinin kimliği her yayında değişir).
final entriesByCategoryProvider =
    Provider<Map<ScreenshotCategory, List<ScreenshotEntry>>>((ref) {
      final Map<ScreenshotCategory, List<ScreenshotEntry>> grouped = {};
      for (final ScreenshotEntry entry in ref.watch(galleryEntriesProvider)) {
        final ScreenshotCategory? category = entry.category;
        if (category == null) continue;
        (grouped[category] ??= []).add(entry);
      }
      return grouped;
    });

/// Pano id → o panoya atanmış kayıtlar (galeri sırasıyla).
final entriesByBoardProvider = Provider<Map<String, List<ScreenshotEntry>>>((
  ref,
) {
  final Map<String, List<ScreenshotEntry>> grouped = {};
  for (final ScreenshotEntry entry in ref.watch(galleryEntriesProvider)) {
    final String? boardId = entry.boardId;
    if (boardId == null) continue;
    (grouped[boardId] ??= []).add(entry);
  }
  return grouped;
});

/// Analiz bekleyen kayıt sayısı. Sayı değişmedikçe dinleyenler yenilenmez.
final pendingCountProvider = Provider<int>((ref) {
  int pending = 0;
  for (final ScreenshotEntry entry in ref.watch(galleryEntriesProvider)) {
    if (entry.isPending) pending++;
  }
  return pending;
});

/// İçeriği olan sistem kategorileri, kullanıcının kayıtlı sırasıyla.
final visibleCategoriesProvider = Provider<List<ScreenshotCategory>>((ref) {
  final Map<ScreenshotCategory, List<ScreenshotEntry>> byCategory = ref.watch(
    entriesByCategoryProvider,
  );
  return [
    for (final ScreenshotCategory category in ref.watch(
      orderedCategoriesProvider,
    ))
      if (byCategory.containsKey(category)) category,
  ];
});

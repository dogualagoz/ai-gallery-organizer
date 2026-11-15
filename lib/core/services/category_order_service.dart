// Kullanıcının sistem kategorilerine verdiği görüntülenme sırasını saklar.
// Enum sabit kalır; burada tüm kategorilerin index'lerinden oluşan tam bir
// sıra listesi tutulur. Yalnız içerikli (görünür) kategoriler ekranda
// sürüklense de görünmeyenlerin yeri korunur.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../constants/app_constants.dart';
import '../models/screenshot_category.dart';
import 'hive_service.dart';

final categoryOrderProvider =
    NotifierProvider<CategoryOrderNotifier, List<int>>(
      CategoryOrderNotifier.new,
    );

/// Tüm sistem kategorileri, kullanıcının kayıtlı sırasıyla. Ekranlar
/// görünür alt kümeyi bu listeyi süzerek alır (sıralama tek yerde).
final orderedCategoriesProvider = Provider<List<ScreenshotCategory>>((ref) {
  const List<ScreenshotCategory> all = ScreenshotCategory.values;
  final Set<int> seen = {};
  return [
    for (final int index in ref.watch(categoryOrderProvider))
      // Enum'dan kalkmış ya da yinelenen kayıtlı index'ler atlanır.
      if (index >= 0 && index < all.length && seen.add(index)) all[index],
  ];
});

class CategoryOrderNotifier extends Notifier<List<int>> {
  Box<dynamic> get _box => HiveService.settings;

  @override
  List<int> build() => _read();

  /// Tüm kategori index'lerini içeren tam sıra; eksik/yeni index'ler enum
  /// sırasıyla sona eklenir (yeni kategori eklenirse bozulmaz).
  List<int> _read() {
    final List<int> enumOrder = [
      for (final ScreenshotCategory c in ScreenshotCategory.values) c.index,
    ];
    final dynamic stored = _box.get(HiveBoxes.categoryOrderKey);
    if (stored is! List) return enumOrder;
    final List<int> saved = [
      for (final dynamic v in stored)
        if (v is int) v,
    ];
    final List<int> missing = [
      for (final int i in enumOrder)
        if (!saved.contains(i)) i,
    ];
    return [...saved, ...missing];
  }

  /// Görünür kategorilerin yeni sırasını ([newVisibleOrder]) kalıcılaştırır.
  /// Görünmeyen kategorilerin tam sıradaki konumları değişmez: yalnız görünür
  /// olanların işgal ettiği "slotlara" yeni sıra yerleştirilir.
  Future<void> reorderVisible(List<ScreenshotCategory> newVisibleOrder) async {
    final List<int> full = [...state];
    final Set<int> visibleIndexes = {
      for (final ScreenshotCategory c in newVisibleOrder) c.index,
    };
    final List<int> slots = [
      for (int i = 0; i < full.length; i++)
        if (visibleIndexes.contains(full[i])) i,
    ];
    for (int i = 0; i < slots.length; i++) {
      full[slots[i]] = newVisibleOrder[i].index;
    }
    await _box.put(HiveBoxes.categoryOrderKey, full);
    state = full;
  }
}

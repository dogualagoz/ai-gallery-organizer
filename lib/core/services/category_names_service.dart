// Kullanıcının sistem kategorilerine verdiği özel adları saklayan servis.
// Enum + çeviri sabit kalır; burada yalnız kategori index → görüntülenen ad
// eşlemesi tutulur. Ad yoksa çağıran taraf çeviri etiketine düşer.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../models/screenshot_category.dart';
import 'hive_service.dart';

final categoryNamesProvider =
    NotifierProvider<CategoryNamesNotifier, Map<int, String>>(
      CategoryNamesNotifier.new,
    );

class CategoryNamesNotifier extends Notifier<Map<int, String>> {
  Box<String> get _box => HiveService.categoryNames;

  @override
  Map<int, String> build() => _read();

  Map<int, String> _read() => {
    for (final dynamic key in _box.keys)
      if (key is int) key: _box.get(key)!,
  };

  /// [category] için özel ad; yoksa null.
  String? nameFor(ScreenshotCategory category) => state[category.index];

  /// Özel ad ayarlar; boş/yalnızca boşluk ise override'ı temizler.
  Future<void> setName(ScreenshotCategory category, String name) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      await clear(category);
      return;
    }
    await _box.put(category.index, trimmed);
    state = _read();
  }

  /// Özel adı kaldırır (çeviri etiketine döner).
  Future<void> clear(ScreenshotCategory category) async {
    await _box.delete(category.index);
    state = _read();
  }
}

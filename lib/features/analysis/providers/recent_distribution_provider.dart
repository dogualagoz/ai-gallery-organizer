// Son analiz turlarında hangi kategoriye kaç YENİ screenshot dağıtıldığını
// kalıcı tutar: analiz kartındaki özet kapansa ve kullanıcı ekranlar arasında
// gezinse bile rozet durur. Kullanıcı ilgili panoyu açınca o kategori temizlenir.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/screenshot_category.dart';

/// Kategori → henüz görülmemiş yeni screenshot sayısı. Boş = rozet yok.
final recentDistributionProvider =
    NotifierProvider<RecentDistributionNotifier, Map<ScreenshotCategory, int>>(
      RecentDistributionNotifier.new,
    );

class RecentDistributionNotifier
    extends Notifier<Map<ScreenshotCategory, int>> {
  @override
  Map<ScreenshotCategory, int> build() => const {};

  /// Tamamlanan bir analiz turunun kategori dağılımını mevcut rozetlere ekler
  /// (birikimli): iki tur üst üste analiz edilirse sayaçlar toplanır, böylece
  /// arada pano açılmadıysa "kaç yeni geldi" bilgisi kaybolmaz.
  void record(Map<ScreenshotCategory, int> counts) {
    if (counts.isEmpty) return;
    final Map<ScreenshotCategory, int> merged = {...state};
    counts.forEach((category, count) {
      if (count <= 0) return;
      merged[category] = (merged[category] ?? 0) + count;
    });
    state = merged;
  }

  /// Kullanıcı [category] panosunu açtığında o kategorinin rozetini kaldırır.
  void clear(ScreenshotCategory category) {
    if (!state.containsKey(category)) return;
    final Map<ScreenshotCategory, int> next = {...state}..remove(category);
    state = next;
  }

  /// Tüm rozetleri temizler.
  void clearAll() {
    if (state.isEmpty) return;
    state = const {};
  }
}

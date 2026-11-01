// Sekme çubuğunu geçici olarak gizleme isteği: seçim modu gibi ekranlar kendi
// araç çubuğunu aynı yere koyar. Kabuk bu durumu izleyip çubuğu söndürür.
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// true iken kabuktaki yüzen sekme çubuğu (pil + Ara) gizlenir.
final tabBarHiddenProvider = NotifierProvider<TabBarHiddenNotifier, bool>(
  TabBarHiddenNotifier.new,
);

/// Birden çok sahip gizleme isteyebilir; çubuk hepsi bırakınca geri gelir.
/// Böylece geç kalan bir bırakma başka ekranın isteğini ezmez.
class TabBarHiddenNotifier extends Notifier<bool> {
  final Set<Object> _owners = {};

  @override
  bool build() => false;

  /// [owner] adına çubuğu gizler (aynı sahip tekrar çağırırsa etkisiz).
  void hide(Object owner) {
    _owners.add(owner);
    state = true;
  }

  /// [owner]'ın isteğini kaldırır; başka sahip kalmadıysa çubuk görünür.
  void release(Object owner) {
    _owners.remove(owner);
    state = _owners.isNotEmpty;
  }
}

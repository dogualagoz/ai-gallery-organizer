// Paywall'ın alt CTA görünürlük kuralı: paket bölümü tamamen ekrandayken
// abonelik çağrısı katlanır; ölçüm kare çizildikten sonra yapılır.
import 'package:flutter/widgets.dart';

/// Alt CTA aboneliği satın alır. Paket bölümü (kendi fiyat butonlarıyla)
/// tamamen ekrandayken "7 gün ücretsiz" çağrısı paketlere aitmiş gibi
/// okunmasın diye [ctaVisible] false olur; plan kartları da tamamen
/// görünüyorsa (her şeyin sığdığı uzun ekran) seçim yapılabilsin diye true
/// kalır. Kullanan state [listKey], [plansKey] ve [packsKey]'i ilgili
/// widget'lara bağlar, kaydırma ve yerleşim değişiminde [scheduleCtaSync]'i
/// çağırır.
mixin CtaVisibility<T extends StatefulWidget> on State<T> {
  final GlobalKey listKey = GlobalKey();
  final GlobalKey plansKey = GlobalKey();
  final GlobalKey packsKey = GlobalKey();

  bool get ctaVisible => _ctaVisible;
  bool _ctaVisible = true;
  bool _syncScheduled = false;

  /// Ölçüm kare çizildikten sonra yapılır: kaydırma bildirimi layout
  /// sırasında da gelebilir, o anda konumlar henüz kesin değildir.
  void scheduleCtaSync() {
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (mounted) _syncCta();
    });
  }

  void _syncCta() {
    final Rect? view = _rectOf(listKey);
    final bool plansFullyShown = _contains(view, _rectOf(plansKey));
    final bool packsFullyShown = _contains(view, _rectOf(packsKey));
    final bool visible = plansFullyShown || !packsFullyShown;
    if (visible != _ctaVisible) setState(() => _ctaVisible = visible);
  }

  static bool _contains(Rect? view, Rect? box) =>
      view != null &&
      box != null &&
      box.top >= view.top &&
      box.bottom <= view.bottom;

  /// [key]'in ekrandaki dikdörtgeni; tembel liste onu henüz kurmadıysa ya da
  /// görünümden uzaklaştığı için attıysa null.
  static Rect? _rectOf(GlobalKey key) {
    final RenderObject? box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}

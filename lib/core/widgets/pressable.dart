// Basış geri bildirimi: dokunuşun ilk karesinde yaylı küçülme, kayma
// başlayınca iptal — InkWell/GestureDetector tap'lerinin iOS karşılığı.
import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../constants/motion_constants.dart';
import '../services/haptic_service.dart';
import '../utils/motion_physics.dart';

/// Dokunulabilir öğe sarmalayıcısı.
///
/// Görsel tepki [Listener] ile pointer-down anında başlar (tap tanıyıcının
/// ~100ms kararını beklemez); eylem ise [GestureDetector] ile parmak kalkıp
/// jest arenası kazanılınca çalışır — kaydırma başlarsa tap iptal olur.
/// Parmak [kTouchSlop]'tan fazla kayarsa basılı görünüm de kalkar; böylece
/// "basılı görünüyor ama bırakınca çalışmıyor" tutarsızlığı oluşmaz.
/// Kaydırılabilir içerikte basılı görünüm [AppMotion.scrollPressDelay] kadar
/// gecikir (kaydırma niyetiyle değen parmak karoyu kırpıştırmasın); hızlı
/// dokunuşta yine kısa süre görünür. Yalnız ilk parmak izlenir.
/// Reduce Motion açıkken ölçek yerine opaklık kullanılır.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.haptic = false,
    this.semanticLabel,
    this.scale = AppMotion.pressScale,
  });

  final Widget child;

  /// Dokunma eylemi; null ise öğe pasiftir (geri bildirim de yok).
  final VoidCallback? onPressed;

  /// Uzun basma eylemi (ör. bağlam menüsü).
  final VoidCallback? onLongPress;

  /// true ise eylem anında hafif seçim titreşimi verilir ([Haptics.tap]).
  final bool haptic;

  /// VoiceOver etiketi; null ise alt ağaçtaki metinler birleşip okunur.
  final String? semanticLabel;

  /// Tam basılı ölçek (büyük karolarda daha az küçülme istenebilir).
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  /// 0 = serbest, 1 = tam basılı. Her yay o anki değer ve hızdan başlar;
  /// basıp hemen bırakmak animasyonu yarıda yakalayıp geri çevirir.
  late final AnimationController _press = AnimationController.unbounded(
    vsync: this,
  );

  bool _pressed = false;

  /// İzlenen (ilk) parmak ve değdiği nokta; kayma eşiği aşılınca null olur.
  int? _pointer;
  Offset? _downPosition;

  /// Kaydırılabilir bir atanın içinde mi (basış gecikmesi kararı).
  bool _inScrollable = false;

  Timer? _pressDelay;
  Timer? _flash;

  bool get _enabled => widget.onPressed != null || widget.onLongPress != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _inScrollable = Scrollable.maybeOf(context) != null;
  }

  @override
  void didUpdateWidget(Pressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) _release();
  }

  @override
  void dispose() {
    _pressDelay?.cancel();
    _flash?.cancel();
    _press.dispose();
    super.dispose();
  }

  void _setPressed(bool pressed) {
    if (_pressed == pressed) return;
    _pressed = pressed;
    _press.animateWith(
      SpringSimulation(
        pressed ? AppSprings.press : AppSprings.snappy,
        _press.value,
        pressed ? 1 : 0,
        _press.velocity,
      ),
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!_enabled || _pointer != null) return;
    _flash?.cancel();
    _pointer = event.pointer;
    _downPosition = event.position;
    if (!_inScrollable) {
      _setPressed(true);
      return;
    }
    _pressDelay = Timer(AppMotion.scrollPressDelay, () => _setPressed(true));
  }

  void _onPointerMove(PointerMoveEvent event) {
    final Offset? origin = _downPosition;
    if (event.pointer != _pointer || origin == null) return;
    // Tap tanıyıcı da bu eşikte vazgeçer; görünüm onunla aynı kararı verir.
    if ((event.position - origin).distance > kTouchSlop) _release();
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer != _pointer) return;
    final bool quickTap =
        (_pressDelay?.isActive ?? false) && _downPosition != null;
    _release();
    if (!quickTap) return;
    // Gecikme dolmadan biten dokunuş: geri bildirim yine bir an görünsün.
    _setPressed(true);
    _flash = Timer(AppMotion.pressFlash, () => _setPressed(false));
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer == _pointer) _release();
  }

  void _release() {
    _pressDelay?.cancel();
    _pointer = null;
    _downPosition = null;
    _setPressed(false);
  }

  void _handleTap() {
    if (widget.haptic) Haptics.tap();
    widget.onPressed?.call();
  }

  void _handleLongPress() {
    _release();
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = context.reduceMotion;
    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: _enabled,
        label: widget.semanticLabel,
        child: Listener(
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onPressed == null ? null : _handleTap,
            onTapCancel: _release,
            onLongPress: widget.onLongPress == null ? null : _handleLongPress,
            child: AnimatedBuilder(
              animation: _press,
              builder: (context, child) {
                final double t = _press.value;
                if (reduceMotion) {
                  return Opacity(
                    opacity: lerpDouble(
                      1,
                      AppMotion.pressedOpacity,
                      t,
                    )!.clamp(0.0, 1.0),
                    child: child,
                  );
                }
                return Transform.scale(
                  scale: lerpDouble(1, widget.scale, t),
                  child: child,
                );
              },
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

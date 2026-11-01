// Alt çubukları yerinde değiştiren yaylı görünürlük: sönerken hafifçe küçülür,
// belirirken aynı yoldan büyür. Gizliyken dokunuş ve VoiceOver'dan çıkar.
import 'dart:ui' show lerpDouble;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../constants/motion_constants.dart';
import '../utils/motion_physics.dart';

/// [visible] değişince [child]'ı opaklık + ölçek yayıyla gösterir/gizler.
/// Çocuk hep ağaçta kalır (state korunur); tam gizliyken hiç boyanmaz, cam
/// bulanıklığı da hesaplanmaz. Reduce Motion'da yalnız kısa çapraz geçiş.
class SpringVisibility extends StatefulWidget {
  const SpringVisibility({
    super.key,
    required this.visible,
    required this.child,
    this.collapse = false,
  });

  final bool visible;
  final Widget child;

  /// true ise gizlenirken yüksekliği de sıfıra iner: Column'daki alt çubuk
  /// giderken yerinde boşluk kalmaz, üstteki içerik aşağı uzar.
  final bool collapse;

  @override
  State<SpringVisibility> createState() => _SpringVisibilityState();
}

class _SpringVisibilityState extends State<SpringVisibility>
    with SingleTickerProviderStateMixin {
  /// 0 = gizli, 1 = görünür. Yay o anki değer ve hızdan başlar; hızlı aç-kapa
  /// animasyonu yarıda yakalayıp geri çevirir.
  late final AnimationController _shown = AnimationController.unbounded(
    vsync: this,
    value: widget.visible ? 1 : 0,
  );

  @override
  void didUpdateWidget(SpringVisibility oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible == widget.visible) return;
    final double target = widget.visible ? 1 : 0;
    if (context.reduceMotion) {
      _shown.animateTo(target, duration: AppMotion.reducedCrossfade);
      return;
    }
    _shown.animateWith(
      SpringSimulation(
        AppSprings.snappy,
        _shown.value,
        target,
        _shown.velocity,
      ),
    );
  }

  @override
  void dispose() {
    _shown.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = context.reduceMotion;
    return IgnorePointer(
      ignoring: !widget.visible,
      child: ExcludeSemantics(
        excluding: !widget.visible,
        child: AnimatedBuilder(
          animation: _shown,
          child: widget.child,
          builder: (context, child) {
            final double t = _shown.value.clamp(0.0, 1.0);
            final Widget faded = Opacity(
              opacity: t,
              child: Transform.scale(
                scale: reduceMotion
                    ? 1
                    : lerpDouble(AppMotion.chromeHiddenScale, 1, t),
                child: child,
              ),
            );
            if (!widget.collapse) return faded;
            return ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: t,
                child: faded,
              ),
            );
          },
        ),
      ),
    );
  }
}

// iOS ana ekran "düzenleme modu" titreşimi: [enabled] iken çocuğu hafifçe
// sağa-sola yalpalatır. Komşu karolar ters fazda sallansın diye [seed] parite'si
// dönüş yönünü ters çevirir; böylece ızgara daha organik görünür.
import 'package:flutter/material.dart';

/// Titreşimin tepe açısı (radyan) — ~1.4°.
const double _kJiggleAngle = 0.025;

class Jiggle extends StatefulWidget {
  const Jiggle({
    super.key,
    required this.child,
    required this.enabled,
    this.seed = 0,
  });

  final Widget child;

  /// true iken titreşir; false iken çocuk hareketsiz gösterilir.
  final bool enabled;

  /// Komşu karolar arasında faz farkı için (genelde ızgara index'i).
  final int seed;

  @override
  State<Jiggle> createState() => _JiggleState();
}

class _JiggleState extends State<Jiggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    // Her karo biraz farklı hızda sallanır — mekanik senkron kırılsın.
    duration: Duration(milliseconds: 160 + (widget.seed % 3) * 30),
  );

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant Jiggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    // Komşu karolar ters yönde başlasın.
    final double direction = widget.seed.isEven ? 1 : -1;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // reverse:true ile değer 0→1→0 gider; -1..1'e taşıyıp açıya çevir.
        return Transform.rotate(
          angle: _kJiggleAngle * direction * (_controller.value * 2 - 1),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

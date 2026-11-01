// iOS düzenleme modu titreşimi: yumuşak sinüs yalpalaması. Genlik açılışta ve
// kapanışta yayla büyüyüp söner (ani başlama/durma yok); Reduce Motion'da hiç
// titremez. Ağaç yapısı hep aynı kalır, çocuğun state'i sıfırlanmaz.
import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../constants/motion_constants.dart';
import '../utils/motion_physics.dart';

class Jiggle extends StatefulWidget {
  const Jiggle({
    super.key,
    required this.child,
    required this.enabled,
    this.seed = 0,
  });

  final Widget child;

  /// true iken titreşir; false iken genlik yayla sıfıra iner.
  final bool enabled;

  /// Komşu karolar arasında faz/yön farkı için (genelde ızgara index'i).
  final int seed;

  @override
  State<Jiggle> createState() => _JiggleState();
}

class _JiggleState extends State<Jiggle> with TickerProviderStateMixin {
  /// Sürekli dönen faz: periyot başına 0→1 bir tur.
  late final AnimationController _phase = AnimationController(
    vsync: this,
    duration: AppMotion.jigglePeriod,
  );

  /// Genlik zarfı (0 = durgun, 1 = tam titreşim).
  late final AnimationController _amplitude = AnimationController.unbounded(
    vsync: this,
  );

  late final Listenable _animation = Listenable.merge([_phase, _amplitude]);

  bool get _active => widget.enabled && !context.reduceMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(Jiggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) _sync();
  }

  @override
  void dispose() {
    _phase.dispose();
    _amplitude.dispose();
    super.dispose();
  }

  /// Genliği hedefe yaylar; sönünce faz döngüsü de durur (boşta ticker yok).
  void _sync() {
    final bool active = _active;
    if (active && !_phase.isAnimating) _phase.repeat();
    final double target = active ? 1 : 0;
    if (_amplitude.value == target && !_amplitude.isAnimating) {
      if (!active) _phase.stop();
      return;
    }
    _amplitude
        .animateWith(
          SpringSimulation(
            AppSprings.standard,
            _amplitude.value,
            target,
            _amplitude.velocity,
          ),
        )
        .whenCompleteOrCancel(() {
          if (mounted && !_active) _phase.stop();
        });
  }

  @override
  Widget build(BuildContext context) {
    // Komşular ters yönde ve farklı fazda başlar: ızgara mekanik görünmez.
    final double direction = widget.seed.isEven ? 1 : -1;
    final double offset = (widget.seed * AppMotion.jigglePhaseSpread) % 1;
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) => Transform.rotate(
        angle:
            AppMotion.jiggleAngle *
            direction *
            _amplitude.value *
            math.sin(2 * math.pi * (_phase.value + offset)),
        child: child,
      ),
    );
  }
}

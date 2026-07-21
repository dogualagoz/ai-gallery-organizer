// Analiz sahnesinin particle katmanları: sürekli süzülen ambient alan ve
// kartların şeride inişinde merkezinden saçılıp sönen kısa ömürlü patlama.
import 'dart:math';

import 'package:flutter/material.dart';

/// Ambient alandaki toplam zerre sayısı — premium his için yeterli, ama
/// performans için düşük (widget başına particle YOK, hepsi tek painter'da).
const int _ambientCount = 28;

/// Sahne arkasında yavaşça yükselip yanıp sönen ışık zerreleri.
class SceneAmbientParticles extends StatefulWidget {
  const SceneAmbientParticles({super.key, required this.color});

  final Color color;

  @override
  State<SceneAmbientParticles> createState() => _SceneAmbientParticlesState();
}

class _SceneAmbientParticlesState extends State<SceneAmbientParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  late final List<_AmbientDot> _dots;

  @override
  void initState() {
    super.initState();
    final Random random = Random();
    _dots = List<_AmbientDot>.generate(
      _ambientCount,
      (_) => _AmbientDot.random(random),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _AmbientPainter(
            dots: _dots,
            progress: _controller.value,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}

/// Tek bir ambient zerresinin sabit parametreleri.
class _AmbientDot {
  _AmbientDot({
    required this.x,
    required this.speed,
    required this.phase,
    required this.radius,
  });

  /// 0..1 yatay konum.
  final double x;

  /// Dikey döngü hız çarpanı.
  final double speed;

  /// 0..1 başlangıç faz kayması.
  final double phase;
  final double radius;

  factory _AmbientDot.random(Random r) => _AmbientDot(
    x: r.nextDouble(),
    speed: 0.6 + r.nextDouble() * 0.8,
    phase: r.nextDouble(),
    radius: 1.0 + r.nextDouble() * 2.0,
  );
}

class _AmbientPainter extends CustomPainter {
  _AmbientPainter({
    required this.dots,
    required this.progress,
    required this.color,
  });

  final List<_AmbientDot> dots;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    for (final _AmbientDot dot in dots) {
      final double t = (progress * dot.speed + dot.phase) % 1.0;
      final double y = size.height * (1 - t); // aşağıdan yukarı süzülür
      final double x = size.width * dot.x;
      final double fade = sin(t * pi); // uçlarda görünmez, ortada belirgin
      paint.color = color.withValues(alpha: 0.16 * fade);
      canvas.drawCircle(Offset(x, y), dot.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_AmbientPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Kart bir şeride indiğinde merkezinden dışa saçılıp sönen zerreler.
/// Kendi controller'ıyla bir kez oynar ve [onDone] ile kendini kaldırır.
class LandingBurst extends StatefulWidget {
  const LandingBurst({super.key, required this.color, required this.onDone});

  final Color color;
  final VoidCallback onDone;

  @override
  State<LandingBurst> createState() => _LandingBurstState();
}

class _LandingBurstState extends State<LandingBurst>
    with SingleTickerProviderStateMixin {
  static const int _dotCount = 8;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  )..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _BurstPainter(
          progress: _controller.value,
          color: widget.color,
          count: _dotCount,
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({
    required this.progress,
    required this.color,
    required this.count,
  });

  final double progress;
  final Color color;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double eased = Curves.easeOut.transform(progress);
    final double dist = 4 + eased * 24;
    final Paint paint = Paint()
      ..color = color.withValues(alpha: (1 - progress).clamp(0, 1) * 0.9);
    for (int i = 0; i < count; i++) {
      final double angle = (2 * pi / count) * i;
      final Offset p = center + Offset(cos(angle), sin(angle)) * dist;
      canvas.drawCircle(p, 2.2 * (1 - eased) + 0.6, paint);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

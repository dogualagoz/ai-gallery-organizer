// Analiz sahnesinin particle katmanları: tabandan yükselen nabızlı mor ışıma,
// sürekli süzülen ambient zerre alanı, alttan yukarı süzülen yumuşak "duman"
// katmanı ve kartların şeride inişinde merkezinden saçılıp sönen patlama.
import 'dart:math';

import 'package:flutter/material.dart';

/// Ambient alandaki varsayılan zerre sayısı — premium his için yeterli, ama
/// performans için düşük (widget başına particle YOK, hepsi tek painter'da).
const int _defaultAmbientCount = 28;

/// Zerrenin en belirgin (orta) anındaki varsayılan opaklığı.
const double _defaultAmbientAlpha = 0.16;

/// Duman katmanındaki puf sayısı — her puf bulanık olduğundan az sayı yeter.
const int _defaultSmokeCount = 14;

/// Duman pufunun en belirgin anındaki opaklık tavanı.
const double _defaultSmokeAlpha = 0.22;

/// Sahne arkasında yavaşça yükselip yanıp sönen ışık zerreleri.
class SceneAmbientParticles extends StatefulWidget {
  const SceneAmbientParticles({
    super.key,
    required this.color,
    this.count = _defaultAmbientCount,
    this.maxAlpha = _defaultAmbientAlpha,
  });

  final Color color;

  /// Aynı anda süzülen zerre sayısı (anasayfada abartısız tutmak için düşük).
  final int count;

  /// Zerrenin en belirgin anındaki opaklık tavanı.
  final double maxAlpha;

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
      widget.count,
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
            maxAlpha: widget.maxAlpha,
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
    required this.maxAlpha,
  });

  final List<_AmbientDot> dots;
  final double progress;
  final Color color;
  final double maxAlpha;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    for (final _AmbientDot dot in dots) {
      final double t = (progress * dot.speed + dot.phase) % 1.0;
      final double y = size.height * (1 - t); // aşağıdan yukarı süzülür
      final double x = size.width * dot.x;
      final double fade = sin(t * pi); // uçlarda görünmez, ortada belirgin
      paint.color = color.withValues(alpha: maxAlpha * fade);
      canvas.drawCircle(Offset(x, y), dot.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_AmbientPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.maxAlpha != maxAlpha;
}

/// Analiz sürerken alttan yukarı süzülen yumuşak duman katmanı: bulanık,
/// hafifçe yalpalayan puflar yükselirken büyür ve seyrelir — "bir şeyler
/// pişiyor" hissi. Ambient zerre alanının ek katmanı olarak kullanılır.
class SceneRisingSmoke extends StatefulWidget {
  const SceneRisingSmoke({
    super.key,
    required this.color,
    this.count = _defaultSmokeCount,
    this.maxAlpha = _defaultSmokeAlpha,
  });

  final Color color;

  /// Aynı anda yükselen puf sayısı.
  final int count;

  /// Pufun en belirgin anındaki opaklık tavanı.
  final double maxAlpha;

  @override
  State<SceneRisingSmoke> createState() => _SceneRisingSmokeState();
}

class _SceneRisingSmokeState extends State<SceneRisingSmoke>
    with SingleTickerProviderStateMixin {
  // Ambient'ten yavaş: ağır, tembel duman temposu.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  late final List<_SmokePuff> _puffs;

  @override
  void initState() {
    super.initState();
    final Random random = Random();
    _puffs = List<_SmokePuff>.generate(
      widget.count,
      (_) => _SmokePuff.random(random),
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
          painter: _SmokePainter(
            puffs: _puffs,
            progress: _controller.value,
            color: widget.color,
            maxAlpha: widget.maxAlpha,
          ),
        ),
      ),
    );
  }
}

/// Tek bir duman pufunun sabit parametreleri.
class _SmokePuff {
  _SmokePuff({
    required this.x,
    required this.speed,
    required this.phase,
    required this.radius,
    required this.sway,
  });

  /// 0..1 taban yatay konum.
  final double x;

  /// Dikey yükseliş hız çarpanı.
  final double speed;

  /// 0..1 başlangıç faz kayması.
  final double phase;

  /// Taban yarıçap (px); yükseldikçe büyür.
  final double radius;

  /// Yatay yalpalama genliği (ekran genişliği oranı).
  final double sway;

  factory _SmokePuff.random(Random r) => _SmokePuff(
    x: r.nextDouble(),
    speed: 0.5 + r.nextDouble() * 0.6,
    phase: r.nextDouble(),
    radius: 14.0 + r.nextDouble() * 22.0,
    sway: 0.02 + r.nextDouble() * 0.05,
  );
}

class _SmokePainter extends CustomPainter {
  _SmokePainter({
    required this.puffs,
    required this.progress,
    required this.color,
    required this.maxAlpha,
  });

  final List<_SmokePuff> puffs;
  final double progress;
  final Color color;
  final double maxAlpha;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    for (final _SmokePuff puff in puffs) {
      final double t = (progress * puff.speed + puff.phase) % 1.0;
      // Yükseldikçe genleşen yarıçap → duman büyümesi.
      final double radius = puff.radius * (0.7 + t * 1.1);
      // Tabandan (ekran altı) başlayıp yukarı süzülür.
      final double y = size.height * (1 - t) + radius;
      // Yükseliş boyunca yumuşak sinüs yalpalaması.
      final double swayX = sin((t * 2 + puff.phase) * pi) * puff.sway;
      final double x = size.width * (puff.x + swayX);
      // Altta yoğun, üste doğru seyrelir; iki uçta da tamamen görünmez.
      final double fade = sin(t * pi) * (1 - t * 0.5);
      paint
        ..color = color.withValues(alpha: maxAlpha * fade)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.6);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_SmokePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.maxAlpha != maxAlpha;
}

/// Analiz sürerken ekranın tabanından yükselen, nefes alır gibi nabızlanan mor
/// gradient ışıma — Siri'nin çalışırkenki parıltısı gibi, "yapay zeka büyük bir
/// işi işliyor" hissi verir. En arka katman olarak kullanılır.
class SceneAiGlow extends StatefulWidget {
  const SceneAiGlow({super.key, required this.color});

  final Color color;

  @override
  State<SceneAiGlow> createState() => _SceneAiGlowState();
}

class _SceneAiGlowState extends State<SceneAiGlow>
    with SingleTickerProviderStateMixin {
  // Nefes temposu: yumuşak gidip gelen nabız.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

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
          painter: _AiGlowPainter(
            progress: Curves.easeInOut.transform(_controller.value),
            color: widget.color,
          ),
        ),
      ),
    );
  }
}

class _AiGlowPainter extends CustomPainter {
  _AiGlowPainter({required this.progress, required this.color});

  /// 0..1 nabız (ileri-geri): ışımanın yoğunluğunu ve boyunu salındırır.
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Nabız: taban yoğunluğu ile tepe arasında yumuşak salınım.
    final double pulse = 0.7 + 0.3 * progress;

    // 1) Tabandan yukarı sönen dikey ışıma bandı (ana mor perde). Üst kenarı
    // düz değil; ortada yükselen hafif bir kavisle (telefonun alt kavisi gibi)
    // kırpılır — kenarlarda daha alçak, merkezde daha yüksek.
    final double bandHeight = size.height * (0.5 + 0.06 * progress);
    final double topY = size.height - bandHeight;
    final Path arch = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, topY + bandHeight * 0.30)
      ..quadraticBezierTo(
        size.width / 2,
        topY - bandHeight * 0.10,
        size.width,
        topY + bandHeight * 0.30,
      )
      ..lineTo(size.width, size.height)
      ..close();
    final Rect band = Rect.fromLTWH(0, topY, size.width, bandHeight);
    canvas.save();
    canvas.clipPath(arch);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            color.withValues(alpha: 0.45 * pulse),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(band),
    );
    canvas.restore();

    // 2) Taban merkezinde daha parlak, nefes alan çekirdek (radyal kubbe).
    final double coreR = size.width * (0.75 + 0.08 * progress);
    final Offset coreCenter = Offset(size.width / 2, size.height + coreR * 0.3);
    canvas.drawCircle(
      coreCenter,
      coreR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.55 * pulse),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: coreCenter, radius: coreR)),
    );
  }

  @override
  bool shouldRepaint(_AiGlowPainter oldDelegate) =>
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

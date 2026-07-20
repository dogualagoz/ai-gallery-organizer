// Analiz sürerken alt kenardan yukarı süzülen ince/ambient mor particle alanı;
// "bir şeyler yaşanıyor" hissini per-item olaylardan bağımsız, sürekli verir.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Aynı anda ekranda tutulan particle sayısı — ince his için bilinçle düşük.
const int _particleCount = 18;

/// Zarf (fade-in/out) süresi; running'e girip çıkarken pop olmasın.
const double _envelopeFadeSeconds = 0.45;

/// Bir frame'de izin verilen en büyük dt — arka plandan dönüşte sıçrama olmasın.
const double _maxFrameSeconds = 1 / 20;

/// Particle üst kenarı bu kadar aşınca (px) alttan yeniden doğar.
const double _topMargin = 24;

/// Analiz `active` iken çalışan, aşağıdan yukarı yükselen mor zerre alanı.
/// `active` false olunca zarf yumuşakça söner ve ticker durur.
class AnalysisParticleField extends StatefulWidget {
  const AnalysisParticleField({super.key, required this.active});

  /// Analiz koşuyor mu — true iken particle üretir, false iken söner.
  final bool active;

  @override
  State<AnalysisParticleField> createState() => _AnalysisParticleFieldState();
}

class _AnalysisParticleFieldState extends State<AnalysisParticleField>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _FieldData _data = _FieldData();
  final Random _random = Random();

  /// CustomPaint'i her frame yeniden boyar; widget ağacını rebuild etmez.
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);

  Duration _lastElapsed = Duration.zero;
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (widget.active) _ticker.start();
  }

  @override
  void didUpdateWidget(AnalysisParticleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // active→true olduğunda ticker'ı başlat. false→ durdurma _onTick içinde,
    // zarf 0'a inince yapılır ki söniş yumuşak olsun. (_lastElapsed her stop'ta
    // sıfırlandığı için restart'ta dt patlaması olmaz.)
    if (widget.active && !_ticker.isActive) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final double dt =
        ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0, _maxFrameSeconds);
    _lastElapsed = elapsed;
    if (dt <= 0) return;

    // Zarf: hedefe (active?1:0) doğrusal yaklaş.
    final double target = widget.active ? 1 : 0;
    final double step = dt / _envelopeFadeSeconds;
    _data.envelope = (_data.envelope + (target > _data.envelope ? step : -step))
        .clamp(0, 1);

    if (_size != Size.zero) {
      // Aktifken sayıyı hedefte tut; sönerken yeni doğurma, mevcutlar yükselsin.
      while (widget.active && _data.particles.length < _particleCount) {
        _data.particles.add(_spawn(fromBottom: true));
      }
      _advanceParticles(dt);
    }

    // Sönme bitti ve artık aktif değilse: temizle ve ticker'ı durdur.
    if (!widget.active && _data.envelope == 0) {
      _data.particles.clear();
      _ticker.stop();
      _lastElapsed = Duration.zero;
    }

    _frame.value++;
  }

  void _advanceParticles(double dt) {
    for (final _Particle p in _data.particles) {
      p.y -= p.speed * dt;
      p.age += dt;
    }
    if (!widget.active) {
      _data.particles.removeWhere((p) => p.y < -_topMargin);
      return;
    }
    // Aktifken üstten çıkanı alttan yeniden doğur — kesintisiz akış.
    for (int i = 0; i < _data.particles.length; i++) {
      if (_data.particles[i].y < -_topMargin) {
        _data.particles[i] = _spawn(fromBottom: true);
      }
    }
  }

  _Particle _spawn({required bool fromBottom}) {
    final double y = fromBottom
        ? _size.height + _random.nextDouble() * _topMargin
        : _random.nextDouble() * _size.height;
    return _Particle(
      dx: _random.nextDouble(),
      y: y,
      speed: 12 + _random.nextDouble() * 22, // px/s — yavaş yükseliş
      radius: 1.5 + _random.nextDouble() * 1.5,
      baseAlpha: 0.08 + _random.nextDouble() * 0.14,
      driftAmp: 6 + _random.nextDouble() * 10,
      driftFreq: 0.5 + _random.nextDouble() * 0.7,
      phase: _random.nextDouble() * pi * 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).colorScheme.secondary;
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          _size = constraints.biggest;
          return CustomPaint(
            size: Size.infinite,
            painter: _ParticlePainter(
              data: _data,
              color: color,
              repaint: _frame,
            ),
          );
        },
      ),
    );
  }
}

/// Painter'ın her frame okuduğu paylaşımlı, yerinde güncellenen veri.
class _FieldData {
  final List<_Particle> particles = [];
  double envelope = 0;
}

/// Tek bir yükselen zerre. Konum/ömür her tick'te yerinde güncellenir.
class _Particle {
  _Particle({
    required this.dx,
    required this.y,
    required this.speed,
    required this.radius,
    required this.baseAlpha,
    required this.driftAmp,
    required this.driftFreq,
    required this.phase,
  });

  final double dx; // 0..1 yatay taban konumu
  double y; // px, alttan yukarı azalır
  final double speed;
  final double radius;
  final double baseAlpha;
  final double driftAmp;
  final double driftFreq;
  final double phase;
  double age = 0;
}

/// Zerreleri boyar; yoğunluk altta, üste doğru söner (verticalFade).
class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.data,
    required this.color,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final _FieldData data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.envelope <= 0 || size.isEmpty) return;
    final Paint paint = Paint()..style = PaintingStyle.fill;
    for (final _Particle p in data.particles) {
      // Üste yükseldikçe (norm 1→0) sön; en güçlü altta.
      final double norm = (p.y / size.height).clamp(0, 1);
      final double alpha = p.baseAlpha * norm * data.envelope;
      if (alpha <= 0.005) continue;
      final double x = p.dx * size.width + sin(p.phase + p.age * p.driftFreq) * p.driftAmp;
      paint.color = color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, p.y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => oldDelegate.color != color;
}

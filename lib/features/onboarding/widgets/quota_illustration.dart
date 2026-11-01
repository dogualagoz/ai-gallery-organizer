// Onboarding kota sayfası illüstrasyonu: mini kartlar halkaya süzülür,
// sayaç 100'e tıklar; hafta dönünce halka tazelenir — döngülü sahne.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/ui_constants.dart';
import 'illustration_loop.dart';

/// Kota halkası: çap, çizgi kalınlığı ve çizginin kenardan içeri payı.
const double _ringSize = 168;
const double _ringStroke = 10;
const double _ringInset = _ringStroke / 2 + 1;

/// Halkaya süzülen mini kartın boyutu ve hafta çipindeki ikon.
const Size _miniCardSize = Size(44, 76);
const double _weekIcon = 22;

/// Döngü koreografisi (0-1 döngü oranı): halka dolumu ve hafta dönüşü.
const double _fillBegin = 0.05;
const double _fillEnd = 0.50;
const double _resetBegin = 0.62;
const double _resetEnd = 0.82;

/// Hareket azaltıldığında gösterilen kare: halka dolu, kartlar emilmiş
/// (tazelenme fazından hemen önce).
const double _stillFrame = 0.61;

/// Kart uçuşları: ilk kartın aralığı ve kartlar arası kademe.
const double _cardBegin = 0.06;
const double _cardEnd = 0.36;
const double _cardStagger = 0.07;

/// Kart uçuşunun son çeyreğinde halkaya emilir gibi söner, yarıya küçülür;
/// başlangıçtaki eğiklik (radyan) varışta düzelir.
const double _cardFadeFrom = 0.75;
const double _cardShrink = 0.5;
const double _cardTiltEven = 0.25;
const double _cardTiltOdd = -0.2;

/// Hafta çipinin dikey konumu (Alignment y; halkanın altında).
const double _weekChipY = 0.92;

/// Mini kartın içi: gölge, görsel bloğu ve metin çizgileri.
const double _miniShadowAlpha = 0.08;
const double _miniShadowBlur = 8;
const Offset _miniShadowOffset = Offset(0, 3);
const double _miniImageHeight = 22;
const double _miniImageAlpha = 0.25;
const double _miniLineHeight = 3;
const double _miniLineAlpha = 0.3;

/// Çizgi genişliği: taban + karta/satıra göre sözde rastgele ek.
const double _miniLineBase = 20;
const int _miniLineVariance = 14;

class QuotaIllustration extends StatefulWidget {
  const QuotaIllustration({super.key});

  @override
  State<QuotaIllustration> createState() => _QuotaIllustrationState();
}

class _QuotaIllustrationState extends State<QuotaIllustration>
    with SingleTickerProviderStateMixin, IllustrationLoop<QuotaIllustration> {
  static const int _cardCount = 5;

  /// Kartların sahne kenarlarındaki başlangıç konumları (0-1 oran).
  static const List<Offset> _cardStarts = [
    Offset(0.04, 0.10),
    Offset(0.80, 0.04),
    Offset(0.06, 0.62),
    Offset(0.86, 0.58),
    Offset(0.44, 0.02),
  ];

  late final AnimationController _controller = AnimationController(
    vsync: this,
    // Tek yönlü döngü: dolum → duraklama → hafta dönüşü → tazelenme.
    duration: AppDurations.scene * 3,
  );

  @override
  AnimationController get controller => _controller;

  @override
  double get stillValue => _stillFrame;

  @override
  void play() => _controller.repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// [begin]-[end] aralığını 0-1'e normalleyip eğri uygular.
  double _phase(
    double begin,
    double end, {
    Curve curve = Curves.easeInOutCubic,
  }) {
    final double t = ((_controller.value - begin) / (end - begin)).clamp(0, 1);
    return curve.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final Size area = constraints.biggest;
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final double fill = _phase(_fillBegin, _fillEnd);
            final double reset = _phase(_resetBegin, _resetEnd);
            return Stack(
              alignment: Alignment.center,
              children: [
                for (int i = 0; i < _cardCount; i++) _buildCard(i, area),
                _QuotaRing(fill: fill, reset: reset),
                _buildWeekChip(context, reset),
              ],
            );
          },
        );
      },
    );
  }

  /// Kenarlardan halkanın merkezine süzülüp kaybolan tek mini kart.
  Widget _buildCard(int index, Size area) {
    final double delay = index * _cardStagger;
    final double t = _phase(_cardBegin + delay, _cardEnd + delay);
    final Offset start = Offset(
      _cardStarts[index].dx * area.width,
      _cardStarts[index].dy * area.height,
    );
    final Offset center = area.center(Offset.zero);
    final Offset pos = Offset.lerp(start, center, t)!;

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: Opacity(
        // Halkaya varırken emilir gibi söner.
        opacity: t < _cardFadeFrom
            ? 1
            : 1 - (t - _cardFadeFrom) / (1 - _cardFadeFrom),
        child: Transform.scale(
          scale: 1 - _cardShrink * t,
          child: Transform.rotate(
            angle: (index.isEven ? _cardTiltEven : _cardTiltOdd) * (1 - t),
            child: _MiniCard(seed: index),
          ),
        ),
      ),
    );
  }

  /// Hafta dönüşünü anlatan takvim çipi — tazelenme fazında tam tur döner.
  Widget _buildWeekChip(BuildContext context, double reset) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: const Alignment(0, _weekChipY),
      child: Transform.rotate(
        angle: reset * 2 * math.pi,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            AppIcons.sync,
            size: _weekIcon,
            color: scheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}

/// Dolum yayı + merkez sayaç. Tazelenme fazında yay tam tur süpürülür.
class _QuotaRing extends StatelessWidget {
  const _QuotaRing({required this.fill, required this.reset});

  final double fill;
  final double reset;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final int count = (fill * FreeLimits.aiAnalysis).round();

    return SizedBox(
      width: _ringSize,
      height: _ringSize,
      child: CustomPaint(
        painter: _RingPainter(
          fill: fill,
          sweepShift: reset * 2 * math.pi,
          trackColor: scheme.outlineVariant,
          fillColor: scheme.primary,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: Theme.of(context).textTheme.headlineLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                '/ ${FreeLimits.aiAnalysis}',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.fill,
    required this.sweepShift,
    required this.trackColor,
    required this.fillColor,
  });

  final double fill;
  final double sweepShift;
  final Color trackColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ringStroke
      ..color = trackColor;
    final Paint arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ringStroke
      ..strokeCap = StrokeCap.round
      ..color = fillColor;

    canvas.drawArc(rect.deflate(_ringInset), 0, 2 * math.pi, false, track);
    canvas.drawArc(
      rect.deflate(_ringInset),
      -math.pi / 2 + sweepShift,
      2 * math.pi * fill,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.sweepShift != sweepShift;
}

/// Screenshot'ı andıran, çizgi dolgulu küçük kart.
class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.seed});

  final int seed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: _miniCardSize.width,
      height: _miniCardSize.height,
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: scheme.outline),
        boxShadow: [
          BoxShadow(
            color: scheme.onSurface.withValues(alpha: _miniShadowAlpha),
            blurRadius: _miniShadowBlur,
            offset: _miniShadowOffset,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (seed.isEven)
            Container(
              height: _miniImageHeight,
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: _miniImageAlpha),
                borderRadius: BorderRadius.circular(AppRadius.sm / 2),
              ),
            ),
          for (int line = 0; line < 2; line++)
            Container(
              height: _miniLineHeight,
              width: _miniLineBase + (seed * 7 + line * 5) % _miniLineVariance,
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              decoration: BoxDecoration(
                color: scheme.onSurfaceVariant.withValues(
                  alpha: _miniLineAlpha,
                ),
                borderRadius: BorderRadius.circular(_miniLineHeight / 2),
              ),
            ),
        ],
      ),
    );
  }
}

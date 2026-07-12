// Onboarding kota sayfası illüstrasyonu: mini kartlar halkaya süzülür,
// sayaç 100'e tıklar; hafta dönünce halka tazelenir — döngülü sahne.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/ui_constants.dart';

class QuotaIllustration extends StatefulWidget {
  const QuotaIllustration({super.key});

  @override
  State<QuotaIllustration> createState() => _QuotaIllustrationState();
}

class _QuotaIllustrationState extends State<QuotaIllustration>
    with SingleTickerProviderStateMixin {
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
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// [begin]-[end] aralığını 0-1'e normalleyip eğri uygular.
  double _phase(double begin, double end, {Curve curve = Curves.easeInOutCubic}) {
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
            final double fill = _phase(0.05, 0.50);
            final double reset = _phase(0.62, 0.82);
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
    final double t = _phase(0.06 + index * 0.07, 0.36 + index * 0.07);
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
        opacity: t < 0.75 ? 1 : 1 - (t - 0.75) / 0.25,
        child: Transform.scale(
          scale: 1 - 0.5 * t,
          child: Transform.rotate(
            angle: (index.isEven ? 0.25 : -0.2) * (1 - t),
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
      alignment: const Alignment(0, 0.92),
      child: Transform.rotate(
        angle: reset * 2 * math.pi,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.event_repeat_outlined,
            size: 22,
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
      width: 168,
      height: 168,
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
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '/ ${FreeLimits.aiAnalysis}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
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
      ..strokeWidth = 10
      ..color = trackColor;
    final Paint arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = fillColor;

    canvas.drawArc(rect.deflate(6), 0, 2 * math.pi, false, track);
    canvas.drawArc(
      rect.deflate(6),
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
      width: 44,
      height: 76,
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: scheme.outline),
        boxShadow: [
          BoxShadow(
            color: scheme.onSurface.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (seed.isEven)
            Container(
              height: 22,
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(AppRadius.sm / 2),
              ),
            ),
          for (int line = 0; line < 2; line++)
            Container(
              height: 3,
              width: 20 + (seed * 7 + line * 5) % 14,
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              decoration: BoxDecoration(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
        ],
      ),
    );
  }
}

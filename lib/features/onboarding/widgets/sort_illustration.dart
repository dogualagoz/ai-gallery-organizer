// Onboarding 1. sayfa illüstrasyonu: dağınık screenshot kartlarının
// düzenli bir ızgaraya süzülmesini gösteren döngülü animasyon.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/ui_constants.dart';

/// Tek bir mini kartın dağınık ve düzenli konum/rotasyon çifti.
class _CardPose {
  const _CardPose({
    required this.scattered,
    required this.scatteredAngle,
    required this.tidy,
  });

  /// Dağınık konum (illüstrasyon alanına oranla 0-1).
  final Offset scattered;

  /// Dağınık dururkenki açı (radyan).
  final double scatteredAngle;

  /// Düzenli ızgaradaki konum (0-1).
  final Offset tidy;
}

class SortIllustration extends StatefulWidget {
  const SortIllustration({super.key});

  @override
  State<SortIllustration> createState() => _SortIllustrationState();
}

class _SortIllustrationState extends State<SortIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Kart oranı ~ iPhone ekranı; ızgara 3 sütun x 2 satır.
  static const double _cardAspect = 9 / 16;
  static const List<_CardPose> _poses = [
    _CardPose(
      scattered: Offset(0.05, 0.12),
      scatteredAngle: -0.35,
      tidy: Offset(0.06, 0.06),
    ),
    _CardPose(
      scattered: Offset(0.55, 0.02),
      scatteredAngle: 0.28,
      tidy: Offset(0.38, 0.06),
    ),
    _CardPose(
      scattered: Offset(0.30, 0.30),
      scatteredAngle: 0.10,
      tidy: Offset(0.70, 0.06),
    ),
    _CardPose(
      scattered: Offset(0.68, 0.42),
      scatteredAngle: -0.22,
      tidy: Offset(0.06, 0.52),
    ),
    _CardPose(
      scattered: Offset(0.10, 0.55),
      scatteredAngle: 0.40,
      tidy: Offset(0.38, 0.52),
    ),
    _CardPose(
      scattered: Offset(0.45, 0.62),
      scatteredAngle: -0.12,
      tidy: Offset(0.70, 0.52),
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Sürekli git-gel: dağınık <-> düzenli. Sakin bir tempo için uzun süre.
    _controller = AnimationController(vsync: this, duration: AppDurations.scene * 2)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;
        final double cardWidth = width * 0.24;
        final double cardHeight = cardWidth / _cardAspect;

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              children: [
                for (int i = 0; i < _poses.length; i++)
                  _buildCard(i, width, height, cardWidth, cardHeight),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCard(
    int index,
    double areaWidth,
    double areaHeight,
    double cardWidth,
    double cardHeight,
  ) {
    final _CardPose pose = _poses[index];
    // Kartlar sırayla harekete başlasın diye hafif kaydırılmış aralıklar.
    final double t = CurvedAnimation(
      parent: _controller,
      curve: Interval(index * 0.05, 1, curve: Curves.easeInOutCubic),
    ).value;

    final Offset position = Offset.lerp(pose.scattered, pose.tidy, t)!;
    final double angle = pose.scatteredAngle * (1 - t);

    return Positioned(
      left: position.dx * areaWidth,
      top: position.dy * areaHeight,
      child: Transform.rotate(
        angle: angle,
        child: _MiniScreenshotCard(
          width: cardWidth,
          height: cardHeight,
          seed: index,
        ),
      ),
    );
  }
}

/// Screenshot'ı andıran içerik çizgili mini kart.
class _MiniScreenshotCard extends StatelessWidget {
  const _MiniScreenshotCard({
    required this.width,
    required this.height,
    required this.seed,
  });

  final double width;
  final double height;

  /// Kartlar birbirinin kopyası görünmesin diye içerik varyasyonu üretir.
  final int seed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final math.Random random = math.Random(seed);

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: scheme.outline),
        boxShadow: [
          BoxShadow(
            color: scheme.onSurface.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Görsel bloğu: bazı kartlarda büyük, bazılarında yok.
          if (seed.isEven)
            Container(
              height: height * 0.35,
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              decoration: BoxDecoration(
                color: (seed % 4 == 0 ? scheme.primary : scheme.secondary)
                    .withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          // Metin satırlarını andıran çizgiler.
          for (int line = 0; line < 3; line++)
            Container(
              height: 4,
              width: width * (0.4 + random.nextDouble() * 0.4),
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              decoration: BoxDecoration(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}

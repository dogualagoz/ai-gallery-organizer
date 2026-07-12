// Milestone kutlama animasyonu: elastik büyüyen onay rozeti + süzülen mini kartlar.
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/constants/ui_constants.dart';

/// Haftalık kota tamamlandığında gösterilen el yapımı kutlama sahnesi.
/// Confetti paketi yerine onboarding illüstrasyonlarıyla aynı desen:
/// tek seferlik rozet girişi + sürekli hafif süzülen mini screenshot kartları.
class MilestoneCelebration extends StatefulWidget {
  const MilestoneCelebration({super.key});

  @override
  State<MilestoneCelebration> createState() => _MilestoneCelebrationState();
}

class _MilestoneCelebrationState extends State<MilestoneCelebration>
    with TickerProviderStateMixin {
  static const int _cardCount = 6;
  static const double _sceneHeight = 220;
  static const double _orbitRadius = 88;

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: AppDurations.slow,
  )..forward();

  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: AppDurations.scene * 2,
  )..repeat(reverse: true);

  /// Kart poz varyasyonları sabit tohumla üretilir — her açılışta aynı sahne.
  final Random _random = Random(7);
  late final List<double> _phases = List.generate(
    _cardCount,
    (_) => _random.nextDouble() * 2 * pi,
  );

  @override
  void dispose() {
    _intro.dispose();
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _sceneHeight,
      child: AnimatedBuilder(
        animation: Listenable.merge([_intro, _drift]),
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            for (int i = 0; i < _cardCount; i++) _buildCard(context, i),
            _buildBadge(context),
          ],
        ),
      ),
    );
  }

  /// Rozet çevresinde yörüngede süzülen tek mini kart.
  Widget _buildCard(BuildContext context, int index) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double angle = 2 * pi * index / _cardCount;
    final double wobble = sin(_drift.value * 2 * pi + _phases[index]);
    final double radius = _orbitRadius + wobble * 8;
    // Kartlar rozetle birlikte sahneye girer (dışa doğru açılırlar).
    final double spread = Curves.easeOutCubic.transform(_intro.value);

    return Transform.translate(
      offset: Offset(cos(angle) * radius * spread, sin(angle) * radius * spread),
      child: Transform.rotate(
        angle: wobble * 0.12,
        child: Opacity(
          opacity: spread,
          child: Container(
            width: 30,
            height: 52,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: scheme.outlineVariant),
            ),
          ),
        ),
      ),
    );
  }

  /// Elastik ölçekle giren merkez onay rozeti.
  Widget _buildBadge(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double scale = Curves.elasticOut.transform(
      _intro.value.clamp(0.0, 1.0),
    );

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.primaryContainer,
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.25),
              blurRadius: 32,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Icon(
          Icons.check_rounded,
          size: 52,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

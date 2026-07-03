// Onboarding 2. sayfa illüstrasyonu: gizlilik vurgusu — kalkan ikonu
// etrafında yumuşakça genişleyip sönen halkalar.
import 'package:flutter/material.dart';

import '../../../core/constants/ui_constants.dart';

class PrivacyIllustration extends StatefulWidget {
  const PrivacyIllustration({super.key});

  @override
  State<PrivacyIllustration> createState() => _PrivacyIllustrationState();
}

class _PrivacyIllustrationState extends State<PrivacyIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.scene * 2,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // İki halka yarım tur arayla genişler; ikincisi faz kaydırmalı.
              _PulseRing(progress: _controller.value, scheme: scheme),
              _PulseRing(
                progress: (_controller.value + 0.5) % 1.0,
                scheme: scheme,
              ),
              child!,
            ],
          );
        },
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.shield_outlined, size: 64, color: scheme.primary),
        ),
      ),
    );
  }
}

/// Dışa doğru genişlerken şeffaflaşan tek halka.
class _PulseRing extends StatelessWidget {
  const _PulseRing({required this.progress, required this.scheme});

  /// 0-1 arası döngü konumu.
  final double progress;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final double size = 140 + progress * 120;
    final double opacity = (1 - progress) * 0.35;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: scheme.primary.withValues(alpha: opacity),
          width: 2,
        ),
      ),
    );
  }
}

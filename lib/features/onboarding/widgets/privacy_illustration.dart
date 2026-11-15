// Onboarding 2. sayfa illüstrasyonu: gizlilik vurgusu — kalkan ikonu
// etrafında yumuşakça genişleyip sönen halkalar.
import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/feature/onboarding_constants.dart';
import 'illustration_loop.dart';

class PrivacyIllustration extends StatefulWidget {
  const PrivacyIllustration({super.key});

  @override
  State<PrivacyIllustration> createState() => _PrivacyIllustrationState();
}

class _PrivacyIllustrationState extends State<PrivacyIllustration>
    with SingleTickerProviderStateMixin, IllustrationLoop<PrivacyIllustration> {
  late final AnimationController _controller;

  @override
  AnimationController get controller => _controller;

  @override
  double get stillValue => PrivacyArt.stillFrame;

  @override
  void play() => _controller.repeat();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: PrivacyArt.loop);
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
                progress: (_controller.value + PrivacyArt.ringPhase) % 1.0,
                scheme: scheme,
              ),
              child!,
            ],
          );
        },
        child: Container(
          width: PrivacyArt.hubSize,
          height: PrivacyArt.hubSize,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: PrivacyArt.hubTint),
            shape: BoxShape.circle,
          ),
          child: Icon(
            AppIcons.shield,
            size: PrivacyArt.shieldSize,
            color: scheme.primary,
          ),
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
    final double size = PrivacyArt.hubSize + progress * PrivacyArt.ringGrowth;
    final double opacity = (1 - progress) * PrivacyArt.ringAlpha;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: scheme.primary.withValues(alpha: opacity),
          width: PrivacyArt.ringWidth,
        ),
      ),
    );
  }
}

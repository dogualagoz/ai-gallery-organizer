// Onboarding 2. sayfa illüstrasyonu: gizlilik vurgusu — kalkan ikonu
// etrafında yumuşakça genişleyip sönen halkalar.
import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/ui_constants.dart';
import 'illustration_loop.dart';

/// Kalkan dairesi, içindeki glif ve zemin tonu.
const double _hubSize = 140;
const double _shieldSize = 64;
const double _hubTint = 0.1;

/// Halkanın döngü boyunca büyüdüğü pay, başlangıç opaklığı ve kalınlığı.
const double _ringGrowth = 120;
const double _ringAlpha = 0.35;
const double _ringWidth = 2;

/// İkinci halkanın faz kayması (yarım tur).
const double _ringPhase = 0.5;

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

  /// Hareket azaltıldığında halkalar yarı açılmış halde durur.
  @override
  double get stillValue => 0.3;

  @override
  void play() => _controller.repeat();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.scene * 2,
    );
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
                progress: (_controller.value + _ringPhase) % 1.0,
                scheme: scheme,
              ),
              child!,
            ],
          );
        },
        child: Container(
          width: _hubSize,
          height: _hubSize,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: _hubTint),
            shape: BoxShape.circle,
          ),
          child: Icon(
            AppIcons.shield,
            size: _shieldSize,
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
    final double size = _hubSize + progress * _ringGrowth;
    final double opacity = (1 - progress) * _ringAlpha;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: scheme.primary.withValues(alpha: opacity),
          width: _ringWidth,
        ),
      ),
    );
  }
}

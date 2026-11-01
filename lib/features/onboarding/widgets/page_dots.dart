// Onboarding sayfa göstergesi: noktalar kaydırmayı parmakla birlikte izler,
// etkin kapsül sayfalar arasında akıcı biçimde genişleyip daralır.
import 'package:flutter/material.dart';

import '../../../core/constants/ui_constants.dart';

/// [controller]'ın anlık sayfa konumunu (kesirli) çizen nokta satırı.
/// Dekoratiftir; ilerleme butonla yapıldığı için VoiceOver'a okunmaz.
class OnboardingPageDots extends StatelessWidget {
  const OnboardingPageDots({
    super.key,
    required this.controller,
    required this.count,
  });

  final PageController controller;
  final int count;

  /// Kaydırma konumu; ilk karede (henüz ölçü yokken) başlangıç sayfası.
  double get _page {
    if (!controller.hasClients || !controller.position.haveDimensions) {
      return controller.initialPage.toDouble();
    }
    return controller.page ?? controller.initialPage.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color idle = scheme.onSurfaceVariant.withValues(
      alpha: AppOpacities.pageDotIdle,
    );
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final double page = _page;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < count; i++)
                _dot(i, page, idle, scheme.primary),
            ],
          );
        },
      ),
    );
  }

  Widget _dot(int index, double page, Color idle, Color active) {
    // 1 = tam bu sayfada, 0 = bir sayfa ya da daha uzakta.
    final double t = (1 - (page - index).abs()).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      width: AppSizes.pageDot + (AppSizes.pageDotActive - AppSizes.pageDot) * t,
      height: AppSizes.pageDot,
      decoration: BoxDecoration(
        color: Color.lerp(idle, active, t),
        borderRadius: BorderRadius.circular(AppSizes.pageDot / 2),
      ),
    );
  }
}

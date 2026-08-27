// Yüzen buzlu-cam yüzey: arkasını bulanıklaştırır, parlak yarı-opak dolgu +
// ince kenar çizgisi + yumuşak gölge ile "havada duran cam kart" etkisi verir.
import 'dart:ui';

import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';

/// Glassmorphism zemin (navbar pili, ayrık Arama butonu). [borderRadius] şekli
/// belirler: pil için `yükseklik/2`, daire için `çap/2`. [child] camın ÜSTÜNDE
/// çizilir — bulanıklığa girmez, okunur kalır. `Scaffold(extendBody: true)`
/// altında kullanılmalı ki [BackdropFilter] arkadan akan içeriği örnekleyebilsin.
class GlassPanel extends StatelessWidget {
  const GlassPanel({super.key, required this.borderRadius, required this.child});

  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = scheme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(
              alpha: isDark ? AppGlass.shadowAlphaDark : AppGlass.shadowAlpha,
            ),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppGlass.blurSigma,
            sigmaY: AppGlass.blurSigma,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface.withValues(
                alpha: isDark ? AppGlass.fillAlphaDark : AppGlass.fillAlpha,
              ),
              borderRadius: borderRadius,
              border: Border.all(
                color: scheme.onSurface.withValues(
                  alpha: isDark
                      ? AppGlass.borderAlphaDark
                      : AppGlass.borderAlpha,
                ),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

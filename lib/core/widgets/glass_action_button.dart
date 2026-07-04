// Navbar pilinin yanında yüzen, aynı cam stilini paylaşan dairesel aksiyon butonu.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/ui_constants.dart';

/// [GlassNavBar] ile aynı hizada, ayrı bir dairesel buton (ör. Arama).
class GlassActionButton extends StatelessWidget {
  const GlassActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: scheme.inverseSurface.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            width: AppSizes.navBarActionSize,
            height: AppSizes.navBarHeight,
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.55),
              shape: BoxShape.circle,
              border: Border.all(color: scheme.outline.withValues(alpha: 0.35)),
            ),
            child: Semantics(
              button: true,
              label: tooltip,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onPressed();
                },
                child: Icon(icon, color: scheme.primary, size: AppSizes.navBarIcon),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

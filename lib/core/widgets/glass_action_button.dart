// Navbar pilinin yanında yüzen, aynı buzlu-cam yüzeyi paylaşan dairesel buton.
import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';
import '../services/haptic_service.dart';
import 'glass_nav_bar.dart';

/// [GlassNavBar] ile aynı hizada, ayrı bir dairesel buton (ör. Arama). Cam
/// görünümü paylaşılan [GlassSurface] ile üretilir.
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

    return GlassSurface(
      borderRadius: BorderRadius.circular(AppSizes.navBarHeight / 2),
      child: SizedBox(
        width: AppSizes.navBarActionSize,
        height: AppSizes.navBarHeight,
        child: Semantics(
          button: true,
          label: tooltip,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              Haptics.tap();
              onPressed();
            },
            child: Icon(icon, color: scheme.primary, size: AppSizes.navBarIcon),
          ),
        ),
      ),
    );
  }
}

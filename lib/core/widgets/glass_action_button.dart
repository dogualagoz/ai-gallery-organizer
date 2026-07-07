// Navbar pilinin yanında yüzen, aynı liquid glass stilini paylaşan dairesel aksiyon butonu.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../constants/ui_constants.dart';

/// [GlassNavBar] ile aynı hizada, ayrı bir dairesel buton (ör. Arama).
/// Bir ata `LiquidGlassLayer` + `LiquidGlassBlendGroup` içinde
/// kullanılmalıdır (bkz. `_MainShell`) — cam ayarları oradan miras alınır.
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

    // Kurulu paket sürümünde `shadows` parametresi henüz yok; gölge dıştan
    // sarmalanan bir DecoratedBox ile veriliyor.
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
      child: LiquidGlass.grouped(
        shape: const LiquidOval(),
        child: SizedBox(
          width: AppSizes.navBarActionSize,
          height: AppSizes.navBarHeight,
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
    );
  }
}

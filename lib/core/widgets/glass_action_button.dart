// Navbar pilinin yanında yüzen, aynı buzlu-cam yüzeyi paylaşan dairesel buton.
import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';
import '../services/haptic_service.dart';
import 'glass_panel.dart';

/// [GlassNavBar] ile aynı hizada, ayrık dairesel bir aksiyon butonu (ör. Arama).
/// `Scaffold(extendBody: true)` altında kullanılmalı — [GlassPanel]'in
/// BackdropFilter'ı arkadan akan içeriği bulanıklaştırır.
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

    return GlassPanel(
      borderRadius: BorderRadius.circular(AppSizes.navBarActionSize / 2),
      // GestureDetector (InkWell değil): Scaffold'un bottomNavigationBar
      // slotunda Material ata yok; _NavItem ile de tutarlı.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Haptics.tap();
          onPressed();
        },
        child: SizedBox(
          width: AppSizes.navBarActionSize,
          height: AppSizes.navBarHeight,
          child: Semantics(
            button: true,
            label: tooltip,
            child: Center(
              child: Icon(
                icon,
                color: scheme.primary,
                size: AppSizes.navBarIcon,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

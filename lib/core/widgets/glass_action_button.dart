// Sekme pilinin yanında yüzen, aynı buzlu-cam yüzeyi paylaşan dairesel sekme.
import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';
import 'glass_panel.dart';
import 'pressable.dart';

/// [GlassNavBar] ile aynı hizada, ayrık dairesel sekme (ör. Ara). Seçiliyken
/// pildeki göstergeyle aynı tonda dolar. `Scaffold(extendBody: true)` altında
/// kullanılmalı — [GlassPanel] arkadan akan içeriği bulanıklaştırır.
class GlassActionButton extends StatelessWidget {
  const GlassActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;

  /// VoiceOver etiketi (görünür metin yok).
  final String label;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return GlassPanel(
      borderRadius: BorderRadius.circular(AppSizes.navBarActionSize / 2),
      child: Pressable(
        onPressed: onPressed,
        haptic: !selected,
        semanticLabel: label,
        child: Semantics(
          selected: selected,
          child: SizedBox(
            width: AppSizes.navBarActionSize,
            height: AppSizes.navBarHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedOpacity(
                  opacity: selected ? 1 : 0,
                  duration: AppDurations.fast,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(
                          alpha: AppGlass.indicatorTint,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                Icon(
                  icon,
                  color: selected ? scheme.primary : scheme.onSurface,
                  size: AppSizes.navBarIcon,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

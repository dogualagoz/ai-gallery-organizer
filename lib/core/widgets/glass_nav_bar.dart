// Buzlu cam (glassmorphism) yüzen alt gezinme çubuğu; seçim kayarak taşınır.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/ui_constants.dart';

/// [GlassNavBar] içindeki tek sekme tanımı.
class GlassNavDestination {
  const GlassNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Modern iOS dilinde yüzen, arkasını blur'layan gezinme çubuğu.
/// Scaffold'a `extendBody: true` ile birlikte verilmelidir; içerik
/// çubuğun arkasından akar ve cam etkisi görünür olur.
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<GlassNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    // Dış boşluk artık paylaşılan tek bir inset olarak _MainShell'de
    // uygulanıyor (pil + ayrık aksiyon butonu aynı hizada yüzsün diye).
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: [
          BoxShadow(
            color: scheme.inverseSurface.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: AppSizes.navBarHeight,
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: scheme.outline.withValues(alpha: 0.35),
              ),
            ),
            child: Stack(
              children: [
                _SlidingIndicator(
                  itemCount: destinations.length,
                  selectedIndex: selectedIndex,
                ),
                Row(
                  children: [
                    for (int i = 0; i < destinations.length; i++)
                      Expanded(
                        child: _NavItem(
                          destination: destinations[i],
                          selected: i == selectedIndex,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onSelected(i);
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Seçili sekmenin arkasında kayarak hareket eden vurgu hapı.
class _SlidingIndicator extends StatelessWidget {
  const _SlidingIndicator({
    required this.itemCount,
    required this.selectedIndex,
  });

  final int itemCount;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    // Alignment -1..1 aralığında: i. sekmenin merkezine denk gelir.
    final double x = itemCount == 1
        ? 0
        : -1 + (2 * selectedIndex / (itemCount - 1));

    return AnimatedAlign(
      duration: AppDurations.medium,
      curve: Curves.easeOutCubic,
      alignment: Alignment(x, 0),
      child: FractionallySizedBox(
        widthFactor: 1 / itemCount,
        heightFactor: 1,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs + 2),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        ),
      ),
    );
  }
}

/// İkon + etiketten oluşan tek sekme düğmesi.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final GlassNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = selected ? scheme.primary : scheme.onSurfaceVariant;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Semantics(
        selected: selected,
        button: true,
        label: destination.label,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: AppDurations.fast,
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: Icon(
                selected ? destination.selectedIcon : destination.icon,
                key: ValueKey(selected),
                color: color,
                size: AppSizes.navBarIcon,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              destination.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

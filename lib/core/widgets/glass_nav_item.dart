// Cam sekme pilinin tek sekmesi: ikon, etiket ve kırmızı sayı rozeti; sekme
// tanımı GlassNavDestination da burada.
import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';
import '../l10n/l10n_extension.dart';
import 'pressable.dart';

/// `GlassNavBar` içindeki tek sekme tanımı.
class GlassNavDestination {
  const GlassNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount = 0,
    this.badgeLabel,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// 0'dan büyükse ikonun sağ üstünde kırmızı sayı rozeti (iOS tab badge).
  final int badgeCount;

  /// Rozetin VoiceOver karşılığı (ör. "3 silinecek").
  final String? badgeLabel;
}

/// İkon + etiketten oluşan tek sekme. Seçiliyken primary renk ve dolgulu ikon;
/// seçili olmayan sekmeye dokunmak seçim haptiği verir.
class GlassNavItem extends StatelessWidget {
  const GlassNavItem({
    super.key,
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final GlassNavDestination destination;

  /// Seçili sekme primary renkte ve dolgulu ikonla çizilir.
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = selected ? scheme.primary : scheme.onSurface;

    final bool badged = destination.badgeCount > 0;
    return Pressable(
      onPressed: onTap,
      haptic: !selected,
      child: Semantics(
        selected: selected,
        value: badged ? destination.badgeLabel : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: AppDurations.fast,
                  child: Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    key: ValueKey(selected),
                    color: color,
                    size: AppSizes.navBarIcon,
                  ),
                ),
                if (badged)
                  PositionedDirectional(
                    top: -AppSpacing.xs,
                    start: AppSizes.navBarIcon - AppSizes.tabBadgeOffset,
                    child: _Badge(count: destination.badgeCount),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.navBarLabelGap),
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

/// Sekme ikonundaki kırmızı sayı rozeti; tek haneli sayıda daire, fazlasında
/// kapsül.
class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        constraints: const BoxConstraints(
          minWidth: AppSizes.tabBadgeMinSize,
          minHeight: AppSizes.tabBadgeMinSize,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.tabBadgePaddingH,
        ),
        decoration: BoxDecoration(
          color: scheme.error,
          borderRadius: BorderRadius.circular(AppSizes.tabBadgeMinSize / 2),
        ),
        alignment: Alignment.center,
        child: Text(
          count > AppSizes.tabBadgeMaxCount
              ? context.l10n.tabBadgeOverflow(AppSizes.tabBadgeMaxCount)
              : '$count',
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: scheme.onError, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

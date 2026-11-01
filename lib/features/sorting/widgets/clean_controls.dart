// Temizle ekranının kontrolleri: jest yönleriyle eşleşen eylem satırı,
// bekleyen silmeleri tamamlatan kapsül ve yukarı kaydırma hedefi kapsülü.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/widgets/pressable.dart';
import '../swipe_decision.dart';
import 'swipe_card.dart';

/// Kartın altındaki eylemler: konumları jest yönüyle eşleşir (sil solda,
/// kategori ortada/yukarı, atla sağda) — kullanıcı jesti denemeden ne işe
/// yaradığını görür; dokunarak da aynı fırlatma tetiklenir.
class CleanActionRow extends StatelessWidget {
  const CleanActionRow({
    super.key,
    required this.assignIcon,
    required this.assignLabel,
    required this.onSwipe,
  });

  final IconData assignIcon;
  final String assignLabel;

  /// null ise eylemler pasiftir (ör. üstte kart yok).
  final ValueChanged<SwipeDirection>? onSwipe;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ValueChanged<SwipeDirection>? swipe = onSwipe;
    VoidCallback? action(SwipeDirection direction) =>
        swipe == null ? null : () => swipe(direction);
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            direction: SwipeDirection.left,
            icon: AppIcons.delete,
            label: l10n.sortingHintDelete,
            onPressed: action(SwipeDirection.left),
          ),
        ),
        Expanded(
          child: _ActionButton(
            direction: SwipeDirection.up,
            icon: assignIcon,
            label: assignLabel,
            onPressed: action(SwipeDirection.up),
          ),
        ),
        Expanded(
          child: _ActionButton(
            direction: SwipeDirection.right,
            icon: AppIcons.skip,
            label: l10n.sortingHintSkip,
            onPressed: action(SwipeDirection.right),
          ),
        ),
      ],
    );
  }
}

/// Tonlu daire + altında etiket. Haptik, kart gittiğinde ekrandan gelir.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.direction,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final SwipeDirection direction;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = onPressed == null
        ? scheme.outline
        : SwipeTone.of(scheme, direction).color;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppDeck.actionSize,
            height: AppDeck.actionSize,
            decoration: BoxDecoration(
              color: color.withValues(alpha: AppDeck.actionTintAlpha),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: AppDeck.actionIcon),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// "N silinecek · Sil": dokununca toplu silme iOS'un kendi onayıyla başlar.
class PendingDeleteBar extends StatelessWidget {
  const PendingDeleteBar({
    super.key,
    required this.count,
    required this.deleting,
    required this.onDelete,
  });

  final int count;
  final bool deleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Pressable(
      onPressed: deleting ? null : onDelete,
      semanticLabel: l10n.sortingFinishAction(count),
      // Görünen kapsül kısa; dokunma alanı 44pt.
      child: SizedBox(
        height: kMinInteractiveDimensionCupertino,
        child: Center(
          child: Container(
            height: AppDeck.pendingBarHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: scheme.error.withValues(alpha: AppDeck.actionTintAlpha),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  AppIcons.delete,
                  size: AppDeck.chipIcon,
                  color: scheme.error,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.sortingPendingDeleteCount(count),
                  style: text.bodyMedium?.copyWith(color: scheme.onSurface),
                ),
                const SizedBox(width: AppSpacing.md),
                if (deleting)
                  const CupertinoActivityIndicator()
                else
                  Text(
                    l10n.sortingHintDelete,
                    style: text.titleSmall?.copyWith(color: scheme.error),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Yukarı kaydırmanın hedef kategorisi ("↑ Sosyal ⌄"); dokununca değiştirilir.
class CleanTargetChip extends StatelessWidget {
  const CleanTargetChip({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Pressable(
      onPressed: onPressed,
      haptic: true,
      semanticLabel: context.l10n.cleanTargetLabel(label),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: kMinInteractiveDimensionCupertino,
          maxWidth:
              MediaQuery.sizeOf(context).width * AppDeck.chipMaxWidthFraction,
        ),
        child: Center(
          widthFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: AppDeck.actionTintAlpha),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.chipPaddingH,
                vertical: AppSizes.chipPaddingV,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppIcons.swipeUp,
                    size: AppDeck.chipIcon,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(color: scheme.primary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    AppIcons.chevronDown,
                    size: AppDeck.chipChevron,
                    color: scheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

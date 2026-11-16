// Temizle gövdesinin düzeni: durum satırı, deste (altında bitiş katmanı),
// bekleyen silme yuvası ve eylem satırı.
import 'package:flutter/material.dart';

import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/widgets/spring_visibility.dart';
import '../logic/swipe_decision.dart';
import 'clean_controls.dart';
import 'swipe_deck.dart';

/// Durum satırı + deste + bekleyen silme yuvası + eylem satırı. Satırlar
/// deste bitince de yer kaplar: son kart uçarken kart boyu değişmez.
class CleanDeckLayout extends StatelessWidget {
  const CleanDeckLayout({
    super.key,
    required this.top,
    required this.next,
    required this.remaining,
    required this.finished,
    required this.freeSwipesLeft,
    required this.assignIcon,
    required this.assignLabel,
    required this.deck,
    required this.onSwipe,
    required this.onPickTarget,
    required this.pending,
    required this.showPending,
    required this.deleting,
    required this.onDelete,
  });

  /// Üstteki ve sıradaki kart; deste boşsa null.
  final SwipeDeckItem? top;
  final SwipeDeckItem? next;

  /// Destede kalan kart sayısı.
  final int remaining;

  /// Destenin altında duran bitiş katmanı (deste bitti ya da kota doldu).
  final Widget? finished;

  /// Ücretsizde kalan kaydırma hakkı; Pro'da null.
  final int? freeSwipesLeft;

  /// Yukarı kaydırma hedefinin ikonu ve adı.
  final IconData assignIcon;
  final String assignLabel;

  final SwipeDeckController deck;
  final void Function(String id, SwipeDirection direction) onSwipe;
  final VoidCallback onPickTarget;

  /// Onay bekleyen silme sayısı ve kapsülün görünürlüğü.
  final int pending;
  final bool showPending;

  /// Silme sürüyor: kapsül eylemi kilitlenir.
  final bool deleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final bool hasCards = top != null;
    return Column(
      children: [
        SpringVisibility(
          visible: hasCards,
          child: _DeckStatus(
            remaining: remaining,
            freeSwipesLeft: freeSwipesLeft,
            targetLabel: assignLabel,
            onPickTarget: onPickTarget,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              ?finished,
              SwipeDeck(
                top: top,
                next: next,
                controller: deck,
                onSwipe: onSwipe,
                assignIcon: assignIcon,
                assignLabel: assignLabel,
              ),
            ],
          ),
        ),
        _PendingSlot(
          pending: pending,
          visible: showPending,
          deleting: deleting,
          onDelete: onDelete,
        ),
        SpringVisibility(
          visible: hasCards,
          child: CleanActionRow(
            assignIcon: assignIcon,
            assignLabel: assignLabel,
            onSwipe: hasCards ? deck.swipe : null,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

/// Bekleyen silme kapsülünün sabit yuvası (yer hep ayrılır).
class _PendingSlot extends StatelessWidget {
  const _PendingSlot({
    required this.pending,
    required this.visible,
    required this.deleting,
    required this.onDelete,
  });

  final int pending;
  final bool visible;
  final bool deleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDeck.pendingSlot,
      child: Center(
        child: SpringVisibility(
          visible: visible,
          child: PendingDeleteBar(
            count: pending,
            deleting: deleting,
            onDelete: onDelete,
          ),
        ),
      ),
    );
  }
}

/// Destenin üstü: kalan sayı (ücretsizde kalan hak) + yukarı hedefi.
class _DeckStatus extends StatelessWidget {
  const _DeckStatus({
    required this.remaining,
    required this.freeSwipesLeft,
    required this.targetLabel,
    required this.onPickTarget,
  });

  final int remaining;
  final int? freeSwipesLeft;
  final String targetLabel;
  final VoidCallback onPickTarget;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final int? swipes = freeSwipesLeft;
    return Row(
      children: [
        Expanded(
          child: Text(
            swipes == null
                ? l10n.sortingRemainingCount(remaining)
                : l10n.cleanStatusWithSwipes(remaining, swipes),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        CleanTargetChip(label: targetLabel, onPressed: onPickTarget),
      ],
    );
  }
}

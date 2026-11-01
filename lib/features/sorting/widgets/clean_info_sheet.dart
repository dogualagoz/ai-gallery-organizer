// Temizle destesinin kuralını anlatan sheet: hangi ekran görüntüleri gelir,
// üç jest ne yapar, geri alma ve ücretsiz plandaki haftalık hak.
import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/widgets/app_nav_scaffold.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/grouped_section.dart';
import '../swipe_decision.dart';
import 'swipe_card.dart';

/// Bilgi sheet'ini açar. [freeSwipes] verilirse (ücretsiz plan) haftalık
/// kaydırma hakkı da anlatılır.
Future<void> showCleanInfoSheet(BuildContext context, {int? freeSwipes}) {
  return showAppSheet<void>(
    context,
    builder: (context, controller) =>
        _CleanInfoSheet(controller: controller, freeSwipes: freeSwipes),
  );
}

class _CleanInfoSheet extends StatelessWidget {
  const _CleanInfoSheet({required this.controller, required this.freeSwipes});

  final ScrollController controller;
  final int? freeSwipes;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final int? swipes = freeSwipes;
    // Ücretsiz plan metni geri alma cümlesini de içerir (dile göre sıra).
    final String footer = swipes == null
        ? l10n.cleanInfoUndoFooter
        : l10n.cleanInfoFreeFooter(swipes);
    return AppNavScaffold(
      title: l10n.cleanInfoTitle,
      controller: controller,
      trailing: NavBarButton.text(
        label: l10n.doneAction,
        onPressed: () => Navigator.of(context).pop(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: Text(
              l10n.cleanInfoIntro,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: GroupedSection(
            footer: footer,
            children: [
              _GestureRow(
                direction: SwipeDirection.left,
                icon: AppIcons.delete,
                title: l10n.cleanInfoLeftTitle,
                body: l10n.cleanInfoLeftBody,
              ),
              _GestureRow(
                direction: SwipeDirection.up,
                icon: AppIcons.swipeUp,
                title: l10n.cleanInfoUpTitle,
                body: l10n.cleanInfoUpBody,
              ),
              _GestureRow(
                direction: SwipeDirection.right,
                icon: AppIcons.skip,
                title: l10n.cleanInfoRightTitle,
                body: l10n.cleanInfoRightBody,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tek jestin açıklaması: tonlu ikon + başlık + çok satırlı açıklama
/// (liste satırının tek satırlık alt yazısı yetmez).
class _GestureRow extends StatelessWidget {
  const _GestureRow({
    required this.direction,
    required this.icon,
    required this.title,
    required this.body,
  });

  final SwipeDirection direction;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final Color color = SwipeTone.of(scheme, direction).color;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

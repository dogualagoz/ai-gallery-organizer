// Paywall'ın fayda odaklı özellik kartı: ikon karosu + başlık + kısa açıklama.
import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/widgets/surface_card.dart';
import 'tinted_icon_tile.dart';

class PaywallFeatureList extends StatelessWidget {
  const PaywallFeatureList({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final List<(IconData, String, String)> items = [
      (
        AppIcons.analyze,
        l10n.paywallFeatureAnalysis,
        l10n.paywallFeatureAnalysisBody,
      ),
      (
        AppIcons.board,
        l10n.paywallFeatureBoards,
        l10n.paywallFeatureBoardsBody,
      ),
      (AppIcons.clean, l10n.paywallFeatureSwipe, l10n.paywallFeatureSwipeBody),
      (
        AppIcons.search,
        l10n.paywallFeatureSearch,
        l10n.paywallFeatureSearchBody,
      ),
      (
        AppIcons.delete,
        l10n.paywallFeatureBulkDelete,
        l10n.paywallFeatureBulkDeleteBody,
      ),
    ];

    return SurfaceCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          for (final (icon, title, body) in items)
            _FeatureRow(icon: icon, title: title, body: body),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TintedIconTile(icon: icon),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleMedium),
                Text(
                  body,
                  style: text.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

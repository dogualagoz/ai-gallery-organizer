// Paywall'ın fayda odaklı özellik listesi: ikon çipi + başlık + kısa açıklama.
import 'package:flutter/material.dart';

import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';

class PaywallFeatureList extends StatelessWidget {
  const PaywallFeatureList({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final List<(IconData, String, String)> items = [
      (
        Icons.auto_awesome,
        l10n.paywallFeatureAnalysis,
        l10n.paywallFeatureAnalysisBody,
      ),
      (
        Icons.dashboard_customize_outlined,
        l10n.paywallFeatureBoards,
        l10n.paywallFeatureBoardsBody,
      ),
      (
        Icons.swipe_outlined,
        l10n.paywallFeatureSwipe,
        l10n.paywallFeatureSwipeBody,
      ),
      (
        Icons.manage_search_outlined,
        l10n.paywallFeatureSearch,
        l10n.paywallFeatureSearchBody,
      ),
      (
        Icons.cleaning_services_outlined,
        l10n.paywallFeatureBulkDelete,
        l10n.paywallFeatureBulkDeleteBody,
      ),
    ];

    return Column(
      children: [
        for (final (icon, title, body) in items)
          _FeatureRow(icon: icon, title: title, body: body),
      ],
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
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, size: 22, color: scheme.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

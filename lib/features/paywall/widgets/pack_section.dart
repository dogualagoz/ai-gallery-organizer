// Tüketilebilir analiz paketleri: aboneliğe girmeden ek kredi satın alma.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../providers/purchase_provider.dart';

class PackSection extends ConsumerWidget {
  const PackSection({required this.packs, required this.busy, super.key});

  final List<ProductDetails> packs;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (packs.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: AppSpacing.xl),
        Text(
          l10n.paywallPacksTitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.paywallPacksSubtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < packs.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _PackCard(
                  pack: packs[i],
                  busy: busy,
                  onBuy: () =>
                      ref.read(purchaseFlowProvider.notifier).buy(packs[i]),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard({required this.pack, required this.busy, required this.onBuy});

  final ProductDetails pack;
  final bool busy;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final int? credits = ProductIds.creditsFor(pack.id);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(Icons.bolt_outlined, size: 20, color: scheme.secondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            credits == null ? pack.title : l10n.paywallPackCredits(credits),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (credits != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.paywallPackDescription(credits),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: busy ? null : onBuy,
              child: Text(pack.price),
            ),
          ),
        ],
      ),
    );
  }
}

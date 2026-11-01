// Tüketilebilir analiz paketleri: aboneliğe girmeden ek kredi satın alma.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/widgets/surface_card.dart';
import '../providers/purchase_provider.dart';
import 'tinted_icon_tile.dart';

class PackSection extends ConsumerWidget {
  const PackSection({required this.packs, required this.busy, super.key});

  final List<ProductDetails> packs;
  final bool busy;

  /// [pack]in en küçük pakete göre kredi başına tasarruf oranı (0-1).
  /// En küçük paketin kendisi ve hesaplanamayan durumlar için null.
  double? _savingsVsSmallest(ProductDetails pack) {
    final int? credits = ProductIds.creditsFor(pack.id);
    if (credits == null) return null;

    ProductDetails? smallest;
    int? smallestCredits;
    for (final ProductDetails candidate in packs) {
      final int? candidateCredits = ProductIds.creditsFor(candidate.id);
      if (candidateCredits == null) continue;
      if (smallestCredits == null || candidateCredits < smallestCredits) {
        smallest = candidate;
        smallestCredits = candidateCredits;
      }
    }
    if (smallest == null ||
        smallestCredits == null ||
        smallest.id == pack.id ||
        smallest.rawPrice <= 0) {
      return null;
    }

    final double baseUnit = smallest.rawPrice / smallestCredits;
    final double unit = pack.rawPrice / credits;
    final double savings = 1 - unit / baseUnit;
    return savings > 0 ? savings : null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (packs.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Semantics(
          header: true,
          child: Text(l10n.paywallPacksTitle, style: text.titleMedium),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.paywallPacksSubtitle,
          style: text.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Kartlar eş yükseklikte: fiyat butonları aynı hizada durur.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < packs.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _PackCard(
                    pack: packs[i],
                    busy: busy,
                    savings: _savingsVsSmallest(packs[i]),
                    onBuy: () =>
                        ref.read(purchaseFlowProvider.notifier).buy(packs[i]),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Paket kartı: kredi sayısı, kısa açıklama ve tonlu fiyat butonu.
class _PackCard extends StatelessWidget {
  const _PackCard({
    required this.pack,
    required this.busy,
    required this.onBuy,
    this.savings,
  });

  final ProductDetails pack;
  final bool busy;
  final VoidCallback onBuy;

  /// En küçük pakete göre kredi başına tasarruf (0-1); yoksa rozet çıkmaz.
  final double? savings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final TextTheme text = Theme.of(context).textTheme;
    final int? credits = ProductIds.creditsFor(pack.id);
    final double? savingsValue = savings;

    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const TintedIconTile(icon: AppIcons.bolt),
              // Dar kartta büyük yazıyla rozet taşmasın: gerekirse alt satıra.
              if (savingsValue != null)
                Flexible(
                  child: _SavingsPill(percent: (savingsValue * 100).round()),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            credits == null ? pack.title : l10n.paywallPackCredits(credits),
            style: text.titleMedium,
          ),
          if (credits != null)
            Text(
              l10n.paywallPackDescription(credits),
              style: text.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          const Spacer(),
          const SizedBox(height: AppSpacing.md),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(AppSizes.buttonHeightCompact),
            ),
            onPressed: busy ? null : onBuy,
            child: Text(pack.price),
          ),
        ],
      ),
    );
  }
}

/// Fiyat avantajını gösteren küçük rozet ("%X daha avantajlı").
class _SavingsPill extends StatelessWidget {
  const _SavingsPill({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppPaywall.badgePaddingV,
      ),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        context.l10n.paywallPackSavings(percent),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

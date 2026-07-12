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
                  savings: _savingsVsSmallest(packs[i]),
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

/// İkincil renkli, parlak (gradient + dış parıltı) paket kartı; metinler
/// zemin üstünde okunacak kontrast renkte.
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
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final int? credits = ProductIds.creditsFor(pack.id);
    final double? savingsValue = savings;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.secondary, scheme.tertiary],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: scheme.secondary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.onSecondary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(Icons.bolt, size: 20, color: scheme.onSecondary),
              ),
              const Spacer(),
              if (savingsValue != null)
                _SavingsPill(percent: (savingsValue * 100).round()),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            credits == null ? pack.title : l10n.paywallPackCredits(credits),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSecondary,
            ),
          ),
          if (credits != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.paywallPackDescription(credits),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSecondary.withValues(alpha: 0.85),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.onSecondary,
                foregroundColor: scheme.secondary,
              ),
              onPressed: busy ? null : onBuy,
              child: Text(pack.price),
            ),
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
        vertical: AppSpacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: scheme.onSecondary.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        context.l10n.paywallPackSavings(percent),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

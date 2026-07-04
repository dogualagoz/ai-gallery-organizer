// Plan seçim kartı: seçili durumda vurgulu çerçeve, yıllıkta tasarruf rozeti.
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({
    required this.product,
    required this.selected,
    required this.onTap,
    this.monthlyProduct,
    super.key,
  });

  final ProductDetails product;
  final bool selected;
  final VoidCallback onTap;

  /// Yıllık kart için aylık plan referansı — tasarruf yüzdesi ve aylık
  /// eşdeğer fiyat bundan hesaplanır. Aylık ürün yoksa ikisi de gizlenir.
  final ProductDetails? monthlyProduct;

  bool get _isYearly => product.id == ProductIds.yearly;

  /// `1 - yıllık/(aylık*12)` — aylık ürün yoksa null.
  int? get _savingsPercent {
    final ProductDetails? monthly = monthlyProduct;
    if (!_isYearly || monthly == null || monthly.rawPrice <= 0) return null;
    final double savings = 1 - (product.rawPrice / (monthly.rawPrice * 12));
    if (savings <= 0) return null;
    return (savings * 100).round();
  }

  String get _monthlyEquivalent {
    final NumberFormat format = NumberFormat.currency(
      symbol: product.currencySymbol,
      decimalDigits: 2,
    );
    return format.format(product.rawPrice / 12);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final int? savings = _savingsPercent;

    return Padding(
      // Rozet kartın üst kenarına bindiği için üstte nefes payı bırakılır.
      padding: EdgeInsets.only(top: savings != null ? AppSpacing.sm + 2 : 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _CardBody(
            product: product,
            selected: selected,
            onTap: onTap,
            monthlyEquivalent: _isYearly && monthlyProduct != null
                ? _monthlyEquivalent
                : null,
          ),
          if (savings != null)
            Positioned(
              top: -(AppSpacing.sm + 2),
              left: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  context.l10n.paywallSavingsBadge(savings),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.product,
    required this.selected,
    required this.onTap,
    this.monthlyEquivalent,
  });

  final ProductDetails product;
  final bool selected;
  final VoidCallback onTap;
  final String? monthlyEquivalent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isYearly = product.id == ProductIds.yearly;

    final String title = switch (product.id) {
      ProductIds.monthly => l10n.paywallPlanMonthly,
      ProductIds.yearly => l10n.paywallPlanYearly,
      ProductIds.lifetime => l10n.paywallPlanLifetime,
      _ => product.title,
    };
    final String unit = switch (product.id) {
      ProductIds.monthly => l10n.paywallUnitMonth,
      ProductIds.yearly => l10n.paywallUnitYear,
      _ => l10n.paywallUnitOnce,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          color: selected
              ? scheme.primary.withValues(alpha: 0.06)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (monthlyEquivalent != null)
                    Text(
                      l10n.paywallPerMonthEquivalent(monthlyEquivalent!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  if (isYearly)
                    Text(
                      l10n.paywallYearlyTrial,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  product.price,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  unit,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

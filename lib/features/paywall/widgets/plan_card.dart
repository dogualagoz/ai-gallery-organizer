// Plan seçim kartı: iOS seçim dairesi, seçiliyken aksan çerçeve ve ton;
// yıllıkta tasarruf rozeti kartın üst kenarına biner.
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/widgets/pressable.dart';

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

  /// Seçim; basış haptiği [Pressable]'dan gelir.
  final VoidCallback onTap;

  /// Yıllık kart için aylık plan referansı — tasarruf yüzdesi ve aylık
  /// eşdeğer fiyat bundan hesaplanır. Aylık ürün yoksa ikisi de gizlenir.
  final ProductDetails? monthlyProduct;

  static const int _monthsPerYear = 12;

  bool get _isYearly => product.id == ProductIds.yearly;

  /// `1 - yıllık/(aylık*12)` — aylık ürün yoksa null.
  int? get _savingsPercent {
    final ProductDetails? monthly = monthlyProduct;
    if (!_isYearly || monthly == null || monthly.rawPrice <= 0) return null;
    final double savings =
        1 - (product.rawPrice / (monthly.rawPrice * _monthsPerYear));
    if (savings <= 0) return null;
    return (savings * 100).round();
  }

  String get _monthlyEquivalent {
    final NumberFormat format = NumberFormat.currency(
      symbol: product.currencySymbol,
      decimalDigits: 2,
    );
    return format.format(product.rawPrice / _monthsPerYear);
  }

  @override
  Widget build(BuildContext context) {
    final int? savings = _savingsPercent;
    final Widget body = _PlanCardBody(
      product: product,
      selected: selected,
      monthlyEquivalent: _isYearly && monthlyProduct != null
          ? _monthlyEquivalent
          : null,
    );

    return Pressable(
      onPressed: onTap,
      haptic: true,
      child: Semantics(
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: savings == null
            ? body
            : Padding(
                // Rozet kartın üst kenarına bindiği için üstte pay bırakılır.
                padding: const EdgeInsets.only(top: AppPaywall.badgeOverlap),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    body,
                    Positioned(
                      top: -AppPaywall.badgeOverlap,
                      left: AppSpacing.md,
                      child: _SavingsBadge(percent: savings),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Kart yüzeyi: seçim dairesi, plan adı/ayrıntıları ve fiyat.
class _PlanCardBody extends StatelessWidget {
  const _PlanCardBody({
    required this.product,
    required this.selected,
    this.monthlyEquivalent,
  });

  final ProductDetails product;
  final bool selected;
  final String? monthlyEquivalent;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: AppDurations.fast,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: selected
            ? Color.alphaBlend(
                scheme.primary.withValues(alpha: AppOpacities.accentTint),
                scheme.surface,
              )
            : scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        // Saydam aksan: renk geçişi siyahtan değil aksanın kendisinden olur.
        border: Border.all(
          color: scheme.primary.withValues(alpha: selected ? 1 : 0),
          width: AppPaywall.planBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            selected ? AppIcons.checkCircleFill : AppIcons.circle,
            size: AppPaywall.planRadio,
            color: selected ? scheme.primary : scheme.outline,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _PlanLabels(
              product: product,
              monthlyEquivalent: monthlyEquivalent,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _PlanPrice(product: product),
        ],
      ),
    );
  }
}

class _PlanLabels extends StatelessWidget {
  const _PlanLabels({required this.product, this.monthlyEquivalent});

  final ProductDetails product;
  final String? monthlyEquivalent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final String? perMonth = monthlyEquivalent;
    final String title = switch (product.id) {
      ProductIds.monthly => l10n.paywallPlanMonthly,
      ProductIds.yearly => l10n.paywallPlanYearly,
      ProductIds.lifetime => l10n.paywallPlanLifetime,
      _ => product.title,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: text.titleMedium),
        if (perMonth != null)
          Text(
            l10n.paywallPerMonthEquivalent(perMonth),
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        if (product.id == ProductIds.yearly)
          Text(
            l10n.paywallYearlyTrial,
            style: text.bodySmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _PlanPrice extends StatelessWidget {
  const _PlanPrice({required this.product});

  final ProductDetails product;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final TextTheme text = Theme.of(context).textTheme;
    final String unit = switch (product.id) {
      ProductIds.monthly => l10n.paywallUnitMonth,
      ProductIds.yearly => l10n.paywallUnitYear,
      _ => l10n.paywallUnitOnce,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          product.price,
          style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          unit,
          style: text.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Yıllık plandaki "%X tasarruf" kapsülü.
class _SavingsBadge extends StatelessWidget {
  const _SavingsBadge({required this.percent});

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
        color: scheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        context.l10n.paywallSavingsBadge(percent),
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w700),
      ),
    );
  }
}

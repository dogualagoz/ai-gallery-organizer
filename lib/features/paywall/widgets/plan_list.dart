// Paywall plan seçimi: abonelik kartları ve yıllık seçiliyken altında deneme
// zaman çizelgesi.
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/ui_constants.dart';
import '../data/paywall_products.dart';
import 'plan_card.dart';
import 'trial_timeline.dart';

/// Plan kartları; yıllık seçiliyse altında deneme zaman çizelgesi.
class PlanList extends StatelessWidget {
  const PlanList({
    super.key,
    required this.subscriptions,
    required this.selectedId,
    required this.cardsKey,
    required this.onSelect,
  });

  /// Sıralı abonelik ürünleri.
  final List<ProductDetails> subscriptions;
  final String selectedId;

  /// Kart sütununun anahtarı: CTA görünürlüğü kartların tam görünüp
  /// görünmediğini bununla ölçer (zaman çizelgesi hariç).
  final GlobalKey cardsKey;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final ProductDetails? monthly = findProduct(
      subscriptions,
      ProductIds.monthly,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          key: cardsKey,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final ProductDetails product in subscriptions)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: PlanCard(
                  product: product,
                  selected: product.id == selectedId,
                  monthlyProduct: product.id == ProductIds.yearly
                      ? monthly
                      : null,
                  onTap: () => onSelect(product.id),
                ),
              ),
          ],
        ),
        if (selectedId == ProductIds.yearly) ...[
          const SizedBox(height: AppSpacing.sm),
          const TrialTimeline(),
        ],
      ],
    );
  }
}

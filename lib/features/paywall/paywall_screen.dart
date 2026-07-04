// Paywall ekranı: özellik karşılaştırması + 3 plan kartı + IAP satın alma/restore.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/ui_constants.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/utils/link_opener.dart';
import 'providers/purchase_provider.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final AsyncValue<List<ProductDetails>> products = ref.watch(
      purchaseProductsProvider,
    );

    ref.listen(purchaseFlowProvider, (_, next) {
      if (next.status == PurchaseFlowStatus.success) {
        HapticFeedback.mediumImpact();
        ref.read(purchaseFlowProvider.notifier).dismissError();
        if (context.mounted) Navigator.of(context).pop();
      } else if (next.status == PurchaseFlowStatus.error) {
        final String message = next.errorMessage ?? l10n.paywallPurchaseFailed;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        ref.read(purchaseFlowProvider.notifier).dismissError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: products.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _ProductsUnavailable(text: l10n.paywallProductsUnavailable),
          data: (items) => items.isEmpty
              ? _ProductsUnavailable(text: l10n.paywallProductsUnavailable)
              : _PaywallContent(products: items),
        ),
      ),
    );
  }
}

class _ProductsUnavailable extends StatelessWidget {
  const _ProductsUnavailable({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _PaywallContent extends ConsumerStatefulWidget {
  const _PaywallContent({required this.products});

  final List<ProductDetails> products;

  @override
  ConsumerState<_PaywallContent> createState() => _PaywallContentState();
}

class _PaywallContentState extends ConsumerState<_PaywallContent> {
  // Not: firstWhere+orElse kullanılamıyor — liste çalışma zamanında
  // platforma özgü alt tiple (AppStoreProduct2Details) geldiği için
  // orElse closure'ı kovaryans nedeniyle tip hatası fırlatıyor.
  late String _selectedProductId = _defaultProductId();

  String _defaultProductId() {
    for (final ProductDetails product in widget.products) {
      if (product.id == ProductIds.yearly) return product.id;
    }
    return widget.products.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final PurchaseFlowStatus status = ref.watch(purchaseFlowProvider).status;
    final bool busy = status == PurchaseFlowStatus.pending;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        const _PaywallHeader(),
        const SizedBox(height: AppSpacing.lg),
        const _FeatureComparison(),
        const SizedBox(height: AppSpacing.lg),
        for (final ProductDetails product in widget.products)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _PlanCard(
              product: product,
              selected: product.id == _selectedProductId,
              onTap: () => setState(() => _selectedProductId = product.id),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: busy ? null : _buy,
          child: busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.paywallContinueAction),
        ),
        _PaywallFooter(busy: busy),
      ],
    );
  }

  Future<void> _buy() async {
    final ProductDetails product = widget.products.firstWhere(
      (p) => p.id == _selectedProductId,
    );
    await ref.read(purchaseFlowProvider.notifier).buy(product);
  }
}

/// Üst kısım: rozet ikonu, başlık ve alt başlık.
class _PaywallHeader extends StatelessWidget {
  const _PaywallHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.workspace_premium_outlined, size: 48, color: scheme.primary),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.paywallWelcomeTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.paywallSubtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Alt kısım: restore, otomatik yenileme notu ve yasal linkler.
class _PaywallFooter extends ConsumerWidget {
  const _PaywallFooter({required this.busy});

  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: busy
              ? null
              : () => ref.read(purchaseFlowProvider.notifier).restore(),
          child: Text(l10n.paywallRestoreAction),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.paywallAutoRenewNote,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => openExternalUrl(context, LegalUrls.termsOfUse),
              child: Text(l10n.paywallTermsLink),
            ),
            Text(
              '·',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            TextButton(
              onPressed: () =>
                  openExternalUrl(context, LegalUrls.privacyPolicy),
              child: Text(l10n.paywallPrivacyLink),
            ),
          ],
        ),
      ],
    );
  }
}

/// Free/Pro özellik karşılaştırma tablosu.
class _FeatureComparison extends StatelessWidget {
  const _FeatureComparison();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<(String, String, String)> rows = [
      (
        l10n.paywallFeatureAnalysis,
        l10n.paywallLimitedValue(FreeLimits.aiAnalysis),
        l10n.paywallUnlimitedValue,
      ),
      (
        l10n.paywallFeatureBoards,
        l10n.paywallLimitedValue(FreeLimits.customBoards),
        l10n.paywallUnlimitedValue,
      ),
      (
        l10n.paywallFeatureSwipe,
        l10n.paywallLimitedValue(FreeLimits.swipeSorts),
        l10n.paywallUnlimitedValue,
      ),
      (
        l10n.paywallFeatureSearch,
        l10n.paywallLockedValue,
        l10n.paywallUnlockedValue,
      ),
      (
        l10n.paywallFeatureBulkDelete,
        l10n.paywallLockedValue,
        l10n.paywallUnlockedValue,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(flex: 3, child: SizedBox.shrink()),
              Expanded(
                flex: 2,
                child: Text(
                  l10n.paywallFreeLabel,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  l10n.paywallProLabel,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: scheme.primary),
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          for (final (label, free, pro) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      free,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      pro,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
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

/// Tek bir plan seçim kartı (aylık/yıllık/ömür boyu).
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.product,
    required this.selected,
    required this.onTap,
  });

  final ProductDetails product;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isYearly = product.id == ProductIds.yearly;
    final bool isLifetime = product.id == ProductIds.lifetime;

    final String title = switch (product.id) {
      ProductIds.monthly => l10n.paywallPlanMonthly,
      ProductIds.yearly => l10n.paywallPlanYearly,
      ProductIds.lifetime => l10n.paywallPlanLifetime,
      _ => product.title,
    };
    final String priceLine = isLifetime
        ? l10n.paywallOneTime(product.price)
        : isYearly
        ? l10n.paywallPerYear(product.price)
        : l10n.paywallPerMonth(product.price);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
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
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (isYearly) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            l10n.paywallYearlyBadge,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: scheme.onPrimary),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (isYearly)
                    Text(
                      l10n.paywallYearlyTrial,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Text(priceLine, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

// Paywall ekranı: gradient hero, açıklamalı özellikler, plan kartları,
// deneme zaman çizelgesi, analiz paketleri ve alta sabit CTA.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/ui_constants.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/utils/link_opener.dart';
import 'providers/purchase_provider.dart';
import 'widgets/feature_list.dart';
import 'widgets/pack_section.dart';
import 'widgets/plan_card.dart';
import 'widgets/trial_timeline.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key, this.scrollToPacks = false});

  /// Açılışta paket bölümüne kaydır (analiz limiti akışından gelindiğinde).
  final bool scrollToPacks;

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
        final int? credits = ProductIds.creditsFor(next.productId ?? '');
        if (credits != null) {
          // Paket alımı Pro açmaz — ekranı kapatmadan kredi eklendiğini bildir.
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.paywallPackPurchased(credits))),
            );
          }
        } else if (context.mounted) {
          Navigator.of(context).pop();
        }
      } else if (next.status == PurchaseFlowStatus.error) {
        final String message = next.errorMessage ?? l10n.paywallPurchaseFailed;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        ref.read(purchaseFlowProvider.notifier).dismissError();
      }
    });

    return Scaffold(
      body: products.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            _ProductsUnavailable(text: l10n.paywallProductsUnavailable),
        data: (items) => items.isEmpty
            ? _ProductsUnavailable(text: l10n.paywallProductsUnavailable)
            : _PaywallContent(products: items, scrollToPacks: scrollToPacks),
      ),
    );
  }
}

class _ProductsUnavailable extends StatelessWidget {
  const _ProductsUnavailable({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          const Positioned(top: 0, right: AppSpacing.md, child: _CloseButton()),
        ],
      ),
    );
  }
}

/// Hero'nun üstünde yüzen yarı saydam kapatma düğmesi.
class _CloseButton extends StatelessWidget {
  const _CloseButton();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: 0.7),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        icon: const Icon(Icons.close, size: 20),
        color: scheme.onSurface,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class _PaywallContent extends ConsumerStatefulWidget {
  const _PaywallContent({required this.products, this.scrollToPacks = false});

  final List<ProductDetails> products;
  final bool scrollToPacks;

  @override
  ConsumerState<_PaywallContent> createState() => _PaywallContentState();
}

class _PaywallContentState extends ConsumerState<_PaywallContent> {
  // Not: firstWhere+orElse kullanılamıyor — liste çalışma zamanında
  // platforma özgü alt tiple (AppStoreProduct2Details) geldiği için
  // orElse closure'ı kovaryans nedeniyle tip hatası fırlatıyor.
  late String _selectedProductId = _defaultProductId();

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.scrollToPacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealPacks());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Listeyi sona kaydırarak paket bölümünü görünür yapar (paketler ve footer
  /// birlikte viewport'a sığar). İlk animasyon sırasında lazily build edilen
  /// satırlar maxScrollExtent'i büyütebildiği için sonda küçük bir düzeltme
  /// kaydırması yapılır.
  Future<void> _revealPacks() async {
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
    if (!mounted || !_scrollController.hasClients) return;
    final double target = _scrollController.position.maxScrollExtent;
    if ((target - _scrollController.offset).abs() > 1) {
      await _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
  }

  /// Önerilen plan üstte olacak şekilde sabit sırada: yıllık, aylık, lifetime.
  static const List<String> _planOrder = [
    ProductIds.yearly,
    ProductIds.monthly,
    ProductIds.lifetime,
  ];

  List<ProductDetails> get _subscriptionProducts {
    final List<ProductDetails> subs = [
      for (final ProductDetails product in widget.products)
        if (ProductIds.subscriptions.contains(product.id)) product,
    ];
    subs.sort(
      (a, b) => _planOrder.indexOf(a.id).compareTo(_planOrder.indexOf(b.id)),
    );
    return subs;
  }

  List<ProductDetails> get _packProducts => [
    for (final ProductDetails product in widget.products)
      if (ProductIds.packs.contains(product.id)) product,
  ];

  ProductDetails? _findProduct(String id) {
    for (final ProductDetails product in _subscriptionProducts) {
      if (product.id == id) return product;
    }
    return null;
  }

  String _defaultProductId() {
    return _findProduct(ProductIds.yearly)?.id ??
        (_subscriptionProducts.isNotEmpty
            ? _subscriptionProducts.first.id
            : widget.products.first.id);
  }

  @override
  Widget build(BuildContext context) {
    final PurchaseFlowStatus status = ref.watch(purchaseFlowProvider).status;
    final bool busy = status == PurchaseFlowStatus.pending;
    final bool yearlySelected = _selectedProductId == ProductIds.yearly;
    final ProductDetails? monthly = _findProduct(ProductIds.monthly);
    final ProductDetails? selected = _findProduct(_selectedProductId);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.lg,
                  ),
                  children: [
                    const _PaywallHero(),
                    const SizedBox(height: AppSpacing.lg),
                    const PaywallFeatureList(),
                    const SizedBox(height: AppSpacing.lg),
                    for (final ProductDetails product in _subscriptionProducts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: PlanCard(
                          product: product,
                          selected: product.id == _selectedProductId,
                          monthlyProduct: product.id == ProductIds.yearly
                              ? monthly
                              : null,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedProductId = product.id);
                          },
                        ),
                      ),
                    if (yearlySelected) ...[
                      const SizedBox(height: AppSpacing.sm),
                      const TrialTimeline(),
                    ],
                    PackSection(packs: _packProducts, busy: busy),
                    _PaywallFooter(busy: busy),
                  ],
                ),
                const Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: _CloseButton(),
                ),
              ],
            ),
          ),
          _BottomCtaBar(
            busy: busy,
            yearlySelected: yearlySelected,
            selectedPrice: selected?.price,
            onPressed: busy ? null : _buy,
          ),
        ],
      ),
    );
  }

  Future<void> _buy() async {
    final ProductDetails product = widget.products.firstWhere(
      (p) => p.id == _selectedProductId,
    );
    await ref.read(purchaseFlowProvider.notifier).buy(product);
  }
}

/// Üst kısım: gradient zemin üzerinde rozet, başlık ve alt başlık.
class _PaywallHero extends StatelessWidget {
  const _PaywallHero();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.14),
            scheme.secondary.withValues(alpha: 0.10),
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.workspace_premium_outlined,
              size: 34,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.paywallWelcomeTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.paywallSubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Alta sabitlenen satın alma çubuğu: büyük CTA + şeffaf fiyat notu.
class _BottomCtaBar extends StatelessWidget {
  const _BottomCtaBar({
    required this.busy,
    required this.yearlySelected,
    required this.selectedPrice,
    required this.onPressed,
  });

  final bool busy;
  final bool yearlySelected;
  final String? selectedPrice;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: onPressed,
              child: busy
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      yearlySelected
                          ? l10n.paywallCtaTrial
                          : l10n.paywallContinueAction,
                    ),
            ),
            if (yearlySelected && selectedPrice != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  l10n.paywallThenPerYear(selectedPrice!),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
      ),
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
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.paywallAutoRenewNote,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xs),
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

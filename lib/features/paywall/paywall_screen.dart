// Paywall sheet'i: Pro karosu, özellik kartı, plan seçimi, deneme zaman
// çizelgesi, analiz paketleri ve alta sabit CTA. Kapatma her durumda görünür.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/motion_constants.dart';
import '../../core/constants/ui_constants.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/services/haptic_service.dart';
import '../../core/utils/motion_physics.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/sheet_close_button.dart';
import '../../core/widgets/spring_visibility.dart';
import '../../core/widgets/status_toast.dart';
import 'providers/purchase_provider.dart';
import 'widgets/cta_visibility.dart';
import 'widgets/feature_list.dart';
import 'widgets/pack_section.dart';
import 'widgets/paywall_chrome.dart';
import 'widgets/plan_card.dart';
import 'widgets/trial_timeline.dart';

/// Pro planları ve analiz paketlerini sunan sheet; satın alma sonucunu
/// dinleyip aboneliği kapatır, paket kredisini bildirir.
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({
    super.key,
    this.scrollToPacks = false,
    this.scrollController,
  });

  /// Açılışta paket bölümüne kaydır (analiz limiti akışından gelindiğinde).
  final bool scrollToPacks;

  /// Sheet rotasının kaydırıcısı: içerik en üstteyken aşağı çekmek sheet'i
  /// kapatsın diye listeye bağlanır. Null ise ekran kendi controller'ını açar.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ProductDetails>> products = ref.watch(
      purchaseProductsProvider,
    );
    ref.listen(
      purchaseFlowProvider,
      (_, next) => _onFlowChanged(context, ref, next),
    );

    return Scaffold(
      body: SheetWithCloseButton(
        child: products.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (_, _) => const _ProductsUnavailable(),
          data: (items) => items.isEmpty
              ? const _ProductsUnavailable()
              : _PaywallContent(
                  products: items,
                  scrollToPacks: scrollToPacks,
                  scrollController: scrollController,
                ),
        ),
      ),
    );
  }

  /// Satın alma sonucu: abonelik sheet'i kapatır, paket kredisi ekranda
  /// kalarak bildirilir, hata kullanıcıya gösterilir.
  void _onFlowChanged(
    BuildContext context,
    WidgetRef ref,
    PurchaseFlowState next,
  ) {
    final l10n = context.l10n;
    if (next.status == PurchaseFlowStatus.success) {
      Haptics.purchaseSuccess();
      ref.read(purchaseFlowProvider.notifier).dismissError();
      final int? credits = ProductIds.creditsFor(next.productId ?? '');
      if (!context.mounted) return;
      if (credits != null) {
        // Paket alımı Pro açmaz — ekranı kapatmadan kredi eklendiğini bildir.
        showStatusToast(
          context,
          l10n.paywallPackPurchased(credits),
          tone: StatusToastTone.success,
        );
      } else {
        Navigator.of(context).pop();
      }
    } else if (next.status == PurchaseFlowStatus.error) {
      Haptics.warning();
      final String message = next.errorMessage ?? l10n.paywallPurchaseFailed;
      if (context.mounted) {
        showStatusToast(context, message, tone: StatusToastTone.error);
      }
      ref.read(purchaseFlowProvider.notifier).dismissError();
    }
  }
}

/// Ürünler yüklenemedi: açıklama + yeniden dene.
class _ProductsUnavailable extends ConsumerWidget {
  const _ProductsUnavailable();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return EmptyStateView(
      icon: AppIcons.pro,
      title: l10n.paywallProductsUnavailableTitle,
      message: l10n.paywallProductsUnavailable,
      actionLabel: l10n.retryAction,
      onAction: () => ref.invalidate(purchaseProductsProvider),
    );
  }
}

class _PaywallContent extends ConsumerStatefulWidget {
  const _PaywallContent({
    required this.products,
    this.scrollToPacks = false,
    this.scrollController,
  });

  final List<ProductDetails> products;
  final bool scrollToPacks;
  final ScrollController? scrollController;

  @override
  ConsumerState<_PaywallContent> createState() => _PaywallContentState();
}

class _PaywallContentState extends ConsumerState<_PaywallContent>
    with CtaVisibility<_PaywallContent> {
  /// Paket bölümüne kaydırma: sekmesiz yay.
  static final Curve _revealCurve = SpringCurve(
    AppSprings.standard,
    AppDurations.slow,
  );

  /// Düzeltme kaydırmasının gerektiği en küçük sapma (px).
  static const double _settleTolerance = 1;

  // Not: firstWhere+orElse kullanılamıyor — liste çalışma zamanında
  // platforma özgü alt tiple (AppStoreProduct2Details) geldiği için
  // orElse closure'ı kovaryans nedeniyle tip hatası fırlatıyor.
  late String _selectedProductId = _defaultProductId();

  late final ScrollController _scrollController;

  /// Dışarıdan (sheet) gelen controller'ın sahibi rotadır; yalnız kendi
  /// açtığımızı kapatırız.
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.scrollController == null;
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(scheduleCtaSync);
    scheduleCtaSync();
    if (widget.scrollToPacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealPacks());
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(scheduleCtaSync);
    if (_ownsController) _scrollController.dispose();
    super.dispose();
  }

  /// Listeyi sona kaydırarak paket bölümünü görünür yapar (paketler ve footer
  /// birlikte viewport'a sığar); Reduce Motion'da kaydırmadan atlar. İlk
  /// animasyon sırasında lazily build edilen satırlar maxScrollExtent'i
  /// büyütebildiği için sonda küçük bir düzeltme kaydırması yapılır.
  Future<void> _revealPacks() async {
    if (!_scrollController.hasClients) return;
    if (context.reduceMotion) {
      // İlk atlama son satırları kurdurur; kesin uç bir kare sonra bilinir.
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      return;
    }
    await _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: AppDurations.slow,
      curve: _revealCurve,
    );
    if (!mounted || !_scrollController.hasClients) return;
    final double target = _scrollController.position.maxScrollExtent;
    if ((target - _scrollController.offset).abs() > _settleTolerance) {
      await _scrollController.animateTo(
        target,
        duration: AppDurations.fast,
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
    final bool busy = ref.watch(
      purchaseFlowProvider.select(
        (flow) => flow.status == PurchaseFlowStatus.pending,
      ),
    );
    final bool yearlySelected = _selectedProductId == ProductIds.yearly;
    final List<ProductDetails> packs = _packProducts;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              key: listKey,
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              children: [
                const PaywallHero(),
                const SizedBox(height: AppSpacing.lg),
                const PaywallFeatureList(),
                const SizedBox(height: AppSpacing.lg),
                _plans(yearlySelected),
                if (packs.isNotEmpty)
                  KeyedSubtree(
                    key: packsKey,
                    child: PackSection(packs: packs, busy: busy),
                  ),
                PaywallFooter(busy: busy),
              ],
            ),
          ),
          SpringVisibility(
            visible: ctaVisible,
            collapse: true,
            child: PaywallCtaBar(
              busy: busy,
              yearlySelected: yearlySelected,
              selectedPrice: _findProduct(_selectedProductId)?.price,
              onPressed: busy ? null : _buy,
            ),
          ),
        ],
      ),
    );
  }

  /// Plan kartları; yıllık seçiliyse altında deneme zaman çizelgesi.
  Widget _plans(bool yearlySelected) {
    final ProductDetails? monthly = _findProduct(ProductIds.monthly);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          key: plansKey,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final ProductDetails product in _subscriptionProducts)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: PlanCard(
                  product: product,
                  selected: product.id == _selectedProductId,
                  monthlyProduct: product.id == ProductIds.yearly
                      ? monthly
                      : null,
                  onTap: () => _select(product.id),
                ),
              ),
          ],
        ),
        if (yearlySelected) ...[
          const SizedBox(height: AppSpacing.sm),
          const TrialTimeline(),
        ],
      ],
    );
  }

  void _select(String productId) {
    setState(() => _selectedProductId = productId);
    // Zaman çizelgesi açılıp kapanınca paketlerin konumu değişir.
    scheduleCtaSync();
  }

  Future<void> _buy() async {
    final ProductDetails product = widget.products.firstWhere(
      (p) => p.id == _selectedProductId,
    );
    await ref.read(purchaseFlowProvider.notifier).buy(product);
  }
}

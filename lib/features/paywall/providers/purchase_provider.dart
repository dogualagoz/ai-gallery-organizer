// Satın alma akışı durumu + IAP purchase stream dinleyicisi; entitlement'ı günceller.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/services/entitlement_service.dart';
import '../data/purchase_repository.dart';

/// Satın alma/restore akışının anlık UI durumu.
enum PurchaseFlowStatus { idle, pending, success, error }

class PurchaseFlowState {
  const PurchaseFlowState({required this.status, this.errorMessage});

  static const PurchaseFlowState initial = PurchaseFlowState(
    status: PurchaseFlowStatus.idle,
  );

  final PurchaseFlowStatus status;
  final String? errorMessage;
}

/// Ürün listesi — paywall açıldığında sorgulanır.
final purchaseProductsProvider = FutureProvider<List<ProductDetails>>((
  ref,
) async {
  final PurchaseRepository repo = ref.watch(purchaseRepositoryProvider);
  if (!await repo.isAvailable()) {
    debugPrint('IAP: mağaza kullanılamıyor (isAvailable=false)');
    return const [];
  }
  final ProductDetailsResponse response = await repo.queryProducts();
  if (response.error != null) {
    debugPrint('IAP: ürün sorgu hatası — ${response.error}');
  }
  if (response.notFoundIDs.isNotEmpty) {
    debugPrint('IAP: bulunamayan ürün ID\'leri — ${response.notFoundIDs}');
  }
  return response.productDetails;
});

/// Restore sonrası hiçbir satın alma dönmezse bekleme süresi.
const Duration _restoreTimeout = Duration(seconds: 4);

final purchaseFlowProvider =
    NotifierProvider<PurchaseFlowNotifier, PurchaseFlowState>(
      PurchaseFlowNotifier.new,
    );

/// SnaplyApp kökünde watch edilerek uygulama boyunca canlı tutulur — böylece
/// paywall ekranı kapalıyken tamamlanan/restore edilen satın almalar da yakalanır.
class PurchaseFlowNotifier extends Notifier<PurchaseFlowState> {
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  @override
  PurchaseFlowState build() {
    final PurchaseRepository repo = ref.read(purchaseRepositoryProvider);
    _subscription = repo.purchaseStream.listen(
      _handleUpdates,
      onError: (_) => state = const PurchaseFlowState(
        status: PurchaseFlowStatus.error,
      ),
    );
    ref.onDispose(() => _subscription?.cancel());
    return PurchaseFlowState.initial;
  }

  Future<void> buy(ProductDetails product) async {
    state = const PurchaseFlowState(status: PurchaseFlowStatus.pending);
    await ref.read(purchaseRepositoryProvider).buy(product);
  }

  Future<void> restore() async {
    state = const PurchaseFlowState(status: PurchaseFlowStatus.pending);
    await ref.read(purchaseRepositoryProvider).restore();
    Future.delayed(_restoreTimeout, () {
      if (state.status == PurchaseFlowStatus.pending) {
        state = PurchaseFlowState.initial;
      }
    });
  }

  void dismissError() => state = PurchaseFlowState.initial;

  Future<void> _handleUpdates(List<PurchaseDetails> purchases) async {
    final PurchaseRepository repo = ref.read(purchaseRepositoryProvider);
    for (final PurchaseDetails purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          state = const PurchaseFlowState(status: PurchaseFlowStatus.pending);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Önce yetki + başarı durumu: completePurchase (aşağıda) restore
          // yolunda hata fırlatabiliyor; UI bu yüzden askıda kalmamalı.
          await ref.read(entitlementProvider.notifier).setPro(true);
          state = const PurchaseFlowState(status: PurchaseFlowStatus.success);
          await _completeSafely(repo, purchase);
        case PurchaseStatus.error:
          state = PurchaseFlowState(
            status: PurchaseFlowStatus.error,
            errorMessage: purchase.error?.message,
          );
          await _completeSafely(repo, purchase);
        case PurchaseStatus.canceled:
          state = PurchaseFlowState.initial;
      }
    }
  }

  /// İşlemi bitirmeyi dener; hata akışı kilitlemesin diye yutulmaz ama loglanır.
  /// Bitmemiş işlem bir sonraki açılışta stream'e yeniden düşer ve tekrar denenir.
  Future<void> _completeSafely(
    PurchaseRepository repo,
    PurchaseDetails purchase,
  ) async {
    try {
      await repo.completePurchase(purchase);
    } catch (error, stackTrace) {
      debugPrint(
        'IAP: completePurchase hatası (${purchase.productID}): '
        '$error\n$stackTrace',
      );
    }
  }
}

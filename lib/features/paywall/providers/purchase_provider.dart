// Satın alma akışı durumu + IAP purchase stream dinleyicisi; entitlement'ı günceller.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/entitlement_service.dart';
import '../../../core/services/preferences_service.dart';
import '../data/purchase_repository.dart';

/// Satın alma/restore akışının anlık UI durumu.
enum PurchaseFlowStatus { idle, pending, success, error }

class PurchaseFlowState {
  const PurchaseFlowState({
    required this.status,
    this.errorMessage,
    this.productId,
  });

  static const PurchaseFlowState initial = PurchaseFlowState(
    status: PurchaseFlowStatus.idle,
  );

  final PurchaseFlowStatus status;
  final String? errorMessage;

  /// Başarılı satın almanın ürün kimliği — UI paket/abonelik ayrımı yapar
  /// (ör. paket alımı paywall'u kapatmaz, snackbar gösterir).
  final String? productId;
} 

/// Çifte teslimatı önlemek için hatırlanan işlem sayısı üst sınırı.
const int _maxRememberedTransactions = 50;

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
          // Önce yetki/kredi + başarı durumu: completePurchase (aşağıda)
          // restore yolunda hata fırlatabiliyor; UI bu yüzden askıda kalmamalı.
          await _grantEntitlement(purchase);
          state = PurchaseFlowState(
            status: PurchaseFlowStatus.success,
            productId: purchase.productID,
          );
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

  /// Ürün kimliğine göre yetki verir: abonelik/lifetime → Pro, analiz paketi
  /// → kredi. Paketler `restored` olayıyla asla gelmemeli (consumable) ama
  /// güvenlik payı olarak yalnız `purchased`'de kredi verilir.
  Future<void> _grantEntitlement(PurchaseDetails purchase) async {
    final int? credits = ProductIds.creditsFor(purchase.productID);
    if (credits == null) {
      // İşlem zamanı trial penceresi hesabında kullanılır; restore orijinal
      // tarihi getirdiği için pencere reinstall sonrası da doğru kalır.
      await ref.read(entitlementProvider.notifier).setProFromPurchase(
        productId: purchase.productID,
        purchaseMs: int.tryParse(purchase.transactionDate ?? ''),
      );
      return;
    }
    if (purchase.status != PurchaseStatus.purchased) return;
    if (await _alreadyDelivered(purchase.purchaseID)) return;
    await ref.read(entitlementProvider.notifier).addCredits(credits);
    await _markDelivered(purchase.purchaseID);
  }

  Future<bool> _alreadyDelivered(String? purchaseId) async {
    if (purchaseId == null) return false;
    final prefs = ref.read(sharedPreferencesProvider);
    final List<String> delivered =
        prefs.getStringList(PrefKeys.deliveredPackTxIds) ?? const [];
    return delivered.contains(purchaseId);
  }

  Future<void> _markDelivered(String? purchaseId) async {
    if (purchaseId == null) return;
    final prefs = ref.read(sharedPreferencesProvider);
    final List<String> delivered = [
      ...prefs.getStringList(PrefKeys.deliveredPackTxIds) ?? const [],
      purchaseId,
    ];
    final int overflow = delivered.length - _maxRememberedTransactions;
    final List<String> bounded = overflow > 0
        ? delivered.sublist(overflow)
        : delivered;
    await prefs.setStringList(PrefKeys.deliveredPackTxIds, bounded);
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

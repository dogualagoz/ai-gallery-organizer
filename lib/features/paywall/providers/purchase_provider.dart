// Satın alma akışı durumu + IAP purchase stream dinleyicisi; entitlement'ı günceller.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/entitlement_service.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/utils/app_logger.dart';
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
    logInfo('IAP: mağaza kullanılamıyor (isAvailable=false)');
    return const [];
  }
  final ProductDetailsResponse response = await repo.queryProducts();
  if (response.error != null) {
    logError('IAP: ürün sorgu hatası', response.error!);
  }
  if (response.notFoundIDs.isNotEmpty) {
    logInfo('IAP: bulunamayan ürün ID\'leri — ${response.notFoundIDs}');
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
  Timer? _restoreTimer;

  /// Kredi teslimi sürerken aynı işlemin ikinci kez işlenmesini önler
  /// (kontrol ile `_markDelivered` arasında `await` boşluğu var).
  final Set<String> _deliveringTxIds = {};

  @override
  PurchaseFlowState build() {
    final PurchaseRepository repo = ref.read(purchaseRepositoryProvider);
    _subscription = repo.purchaseStream.listen(
      _handleUpdates,
      onError: (Object error, StackTrace stackTrace) {
        logError('IAP: purchase stream hatası', error, stackTrace);
        state = const PurchaseFlowState(status: PurchaseFlowStatus.error);
      },
    );
    ref.onDispose(() {
      _subscription?.cancel();
      _restoreTimer?.cancel();
    });
    return PurchaseFlowState.initial;
  }

  /// Satın alma başlatır; platform hatasında akış `error`'a düşer (UI'ı
  /// `pending`'de kilitlemez).
  Future<void> buy(ProductDetails product) async {
    state = const PurchaseFlowState(status: PurchaseFlowStatus.pending);
    try {
      await ref.read(purchaseRepositoryProvider).buy(product);
    } catch (error, stackTrace) {
      logError('IAP: buy hatası (${product.id})', error, stackTrace);
      state = const PurchaseFlowState(status: PurchaseFlowStatus.error);
    }
  }

  /// Geri yükleme başlatır; hiçbir işlem dönmezse [_restoreTimeout] sonra
  /// `pending` durumu temizlenir.
  Future<void> restore() async {
    state = const PurchaseFlowState(status: PurchaseFlowStatus.pending);
    try {
      await ref.read(purchaseRepositoryProvider).restore();
    } catch (error, stackTrace) {
      logError('IAP: restore hatası', error, stackTrace);
      state = const PurchaseFlowState(status: PurchaseFlowStatus.error);
      return;
    }
    // Önceki zamanlayıcı ikinci restore'un pending'ini erken sıfırlamasın.
    _restoreTimer?.cancel();
    _restoreTimer = Timer(_restoreTimeout, () {
      if (state.status == PurchaseFlowStatus.pending) {
        state = PurchaseFlowState.initial;
      }
    });
  }

  /// Apple'ın kod kullanma ekranını açar (Offer/Promo code). Kod geçerliyse
  /// sonuç purchase stream'e düşer, [_handleUpdates] Pro'yu açar.
  Future<void> presentCodeRedemption() =>
      ref.read(purchaseRepositoryProvider).presentCodeRedemption();

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
          final bool? granted = await _grantSafely(purchase);
          // null: aynı işlem zaten teslim ediliyor, ilk akış sonuçlandıracak.
          if (granted == null) continue;
          if (!granted) return;
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

  /// Yetkiyi verir; hata olursa akış `error`'a düşer ve işlem TAMAMLANMAZ
  /// (store yeniden iletir, kredi/Pro kaybolmaz). Başarıda true, hatada false,
  /// eşzamanlı yinelenen işlemde null döner.
  Future<bool?> _grantSafely(PurchaseDetails purchase) async {
    try {
      return await _grantEntitlement(purchase) ? true : null;
    } catch (error, stackTrace) {
      logError(
        'IAP: yetki verilemedi (${purchase.productID})',
        error,
        stackTrace,
      );
      state = const PurchaseFlowState(status: PurchaseFlowStatus.error);
      return false;
    }
  }

  /// Ürün kimliğine göre yetki verir: abonelik/lifetime → Pro, analiz paketi
  /// → kredi. Paketler `restored` olayıyla asla gelmemeli (consumable) ama
  /// güvenlik payı olarak yalnız `purchased`'de kredi verilir.
  /// Aynı paket işlemi zaten teslim ediliyorsa false (ilk akış sonuçlandırır).
  Future<bool> _grantEntitlement(PurchaseDetails purchase) async {
    final int? credits = ProductIds.creditsFor(purchase.productID);
    if (credits == null) {
      // İşlem zamanı trial penceresi hesabında kullanılır; restore orijinal
      // tarihi getirdiği için pencere reinstall sonrası da doğru kalır.
      await ref
          .read(entitlementProvider.notifier)
          .setProFromPurchase(
            productId: purchase.productID,
            purchaseMs: int.tryParse(purchase.transactionDate ?? ''),
          );
      return true;
    }
    if (purchase.status != PurchaseStatus.purchased) return true;
    final String? txId = purchase.purchaseID;
    // `add` senkron: ikinci aynı işlem ilk `await`'ten önce elenir.
    if (txId != null && !_deliveringTxIds.add(txId)) return false;
    try {
      if (await _alreadyDelivered(txId)) return true;
      await ref.read(entitlementProvider.notifier).addCredits(credits);
      await _markDelivered(txId);
      return true;
    } finally {
      if (txId != null) _deliveringTxIds.remove(txId);
    }
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
      logError(
        'IAP: completePurchase hatası (${purchase.productID})',
        error,
        stackTrace,
      );
    }
  }
}

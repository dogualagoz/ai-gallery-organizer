// in_app_purchase sarmalayıcısı: ürün sorgulama, satın alma, restore.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/constants/app_constants.dart';

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  return PurchaseRepository(InAppPurchase.instance);
});

class PurchaseRepository {
  /// [iap] tembel çözülür — böylece test'te alt sınıflar gerçek platform
  /// singleton'ına hiç dokunmadan `purchaseStream`/`completePurchase` gibi
  /// metotları override edebilir.
  PurchaseRepository([InAppPurchase? iap]) : _injectedIap = iap;

  final InAppPurchase? _injectedIap;

  InAppPurchase get _iap => _injectedIap ?? InAppPurchase.instance;

  Future<bool> isAvailable() => _iap.isAvailable();

  Future<ProductDetailsResponse> queryProducts() =>
      _iap.queryProductDetails(ProductIds.all);

  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  /// Abonelik/ömür boyu ürünler `buyNonConsumable`; analiz paketleri
  /// tüketilebilir olduğu için `buyConsumable` (iOS'ta autoConsume zorunlu).
  Future<void> buy(ProductDetails product) {
    if (ProductIds.packs.contains(product.id)) {
      return _iap.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    }
    return _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  Future<void> restore() => _iap.restorePurchases();

  Future<void> completePurchase(PurchaseDetails purchase) {
    if (purchase.pendingCompletePurchase) {
      return _iap.completePurchase(purchase);
    }
    return Future.value();
  }
}

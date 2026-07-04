// in_app_purchase sarmalayıcısı: ürün sorgulama, satın alma, restore.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/constants/app_constants.dart';

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  return PurchaseRepository(InAppPurchase.instance);
});

class PurchaseRepository {
  PurchaseRepository(this._iap);

  final InAppPurchase _iap;

  Future<bool> isAvailable() => _iap.isAvailable();

  Future<ProductDetailsResponse> queryProducts() =>
      _iap.queryProductDetails(ProductIds.all);

  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  /// Aboneliklerde de StoreKit tarafında ayrım olmadığı için tüm ürünler
  /// (aylık/yıllık/ömür boyu) `buyNonConsumable` ile satın alınır.
  Future<void> buy(ProductDetails product) {
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

// Paywall ürün listesinin saf yardımcıları: abonelikleri sabit sırada süzer,
// paketleri ayırır, varsayılan planı seçer.
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/constants/app_constants.dart';

/// Önerilen plan üstte olacak şekilde sabit sırada: yıllık, aylık, lifetime.
const List<String> _planOrder = [
  ProductIds.yearly,
  ProductIds.monthly,
  ProductIds.lifetime,
];

/// [products] içindeki abonelik ürünleri, [_planOrder] sırasında.
List<ProductDetails> subscriptionProducts(List<ProductDetails> products) {
  final List<ProductDetails> subs = [
    for (final ProductDetails product in products)
      if (ProductIds.subscriptions.contains(product.id)) product,
  ];
  subs.sort(
    (a, b) => _planOrder.indexOf(a.id).compareTo(_planOrder.indexOf(b.id)),
  );
  return subs;
}

/// [products] içindeki analiz paketleri (mağaza sırasıyla).
List<ProductDetails> packProducts(List<ProductDetails> products) => [
  for (final ProductDetails product in products)
    if (ProductIds.packs.contains(product.id)) product,
];

/// [id]'li ürün; yoksa null.
///
/// Not: firstWhere+orElse kullanılamıyor — liste çalışma zamanında
/// platforma özgü alt tiple (AppStoreProduct2Details) geldiği için
/// orElse closure'ı kovaryans nedeniyle tip hatası fırlatıyor.
ProductDetails? findProduct(List<ProductDetails> products, String id) {
  for (final ProductDetails product in products) {
    if (product.id == id) return product;
  }
  return null;
}

/// Açılışta seçili plan: yıllık, yoksa ilk abonelik, o da yoksa ilk ürün.
/// [all] boş olmamalıdır.
String defaultProductId(
  List<ProductDetails> subscriptions,
  List<ProductDetails> all,
) {
  return findProduct(subscriptions, ProductIds.yearly)?.id ??
      (subscriptions.isNotEmpty ? subscriptions.first.id : all.first.id);
}

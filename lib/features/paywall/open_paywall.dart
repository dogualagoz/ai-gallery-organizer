// Paywall'ın tek giriş noktası: kilitli eylemler ve yükseltme çağrıları hep
// buradan açar (ileride kaynak/ölçüm eklenecek tek yer).
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';

/// Paywall sheet'ini açar. [packs] true ise açılışta analiz paketleri
/// bölümüne kaydırır (kota bitti akışları).
void openPaywall(BuildContext context, {bool packs = false}) {
  context.push(packs ? AppRoutes.paywallPacks : AppRoutes.paywall);
}

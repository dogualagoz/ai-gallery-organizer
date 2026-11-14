// Satın alma teslimatı: pack -> kredi (Pro AÇMAZ), abonelik -> Pro, idempotency.
import 'dart:async';

import 'package:ai_gallery_organizer/core/constants/app_constants.dart';
import 'package:ai_gallery_organizer/core/services/entitlement_service.dart';
import 'package:ai_gallery_organizer/core/services/preferences_service.dart';
import 'package:ai_gallery_organizer/features/paywall/data/purchase_repository.dart';
import 'package:ai_gallery_organizer/features/paywall/providers/purchase_provider.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gerçek IAP kanalına dokunmadan purchaseStream'i elle tetikleyen sahte repo.
class _FakePurchaseRepository extends PurchaseRepository {
  final StreamController<List<PurchaseDetails>> _controller =
      StreamController.broadcast();
  final List<String> completedProductIds = [];
  Object? buyError;
  Object? restoreError;

  @override
  Future<void> buy(ProductDetails product) async {
    if (buyError != null) throw buyError!;
  }

  @override
  Future<void> restore() async {
    if (restoreError != null) throw restoreError!;
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completedProductIds.add(purchase.productID);
  }

  void emit(PurchaseDetails purchase) => _controller.add([purchase]);
}

ProductDetails _product(String id) => ProductDetails(
  id: id,
  title: id,
  description: id,
  price: '1',
  rawPrice: 1,
  currencyCode: 'TRY',
);

PurchaseDetails _purchase({
  required String productId,
  required PurchaseStatus status,
  String? purchaseId,
}) {
  return PurchaseDetails(
    purchaseID: purchaseId,
    productID: productId,
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: 'server',
      source: 'test',
    ),
    transactionDate: DateTime.now().toIso8601String(),
    status: status,
  );
}

Future<ProviderContainer> _container(_FakePurchaseRepository fake) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      purchaseRepositoryProvider.overrideWithValue(fake),
    ],
  );
}

void main() {
  test('paket satın alma kredi verir, Pro AÇMAZ', () async {
    final fake = _FakePurchaseRepository();
    final container = await _container(fake);
    container.read(purchaseFlowProvider); // build() -> stream'e abone olur

    fake.emit(
      _purchase(
        productId: ProductIds.pack500,
        status: PurchaseStatus.purchased,
        purchaseId: 'tx-1',
      ),
    );
    await Future<void>.delayed(Duration.zero);

    final EntitlementState state = container.read(entitlementProvider);
    expect(state.isPro, isFalse);
    expect(state.analysisCredits, 500);
    expect(fake.completedProductIds, [ProductIds.pack500]);
  });

  test('abonelik satın alma Pro açar, kredi vermez', () async {
    final fake = _FakePurchaseRepository();
    final container = await _container(fake);
    container.read(purchaseFlowProvider);

    fake.emit(
      _purchase(
        productId: ProductIds.yearly,
        status: PurchaseStatus.purchased,
        purchaseId: 'tx-2',
      ),
    );
    await Future<void>.delayed(Duration.zero);

    final EntitlementState state = container.read(entitlementProvider);
    expect(state.isPro, isTrue);
    expect(state.analysisCredits, 0);
  });

  test('aynı işlem tekrar gelirse kredi iki kez verilmez', () async {
    final fake = _FakePurchaseRepository();
    final container = await _container(fake);
    container.read(purchaseFlowProvider);

    final purchase = _purchase(
      productId: ProductIds.pack1000,
      status: PurchaseStatus.purchased,
      purchaseId: 'tx-3',
    );
    fake.emit(purchase);
    await Future<void>.delayed(Duration.zero);
    fake.emit(purchase);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(entitlementProvider).analysisCredits, 1000);
  });

  test(
    'restored paket olayı kredi vermez (consumable restore edilmez)',
    () async {
      final fake = _FakePurchaseRepository();
      final container = await _container(fake);
      container.read(purchaseFlowProvider);

      fake.emit(
        _purchase(
          productId: ProductIds.pack500,
          status: PurchaseStatus.restored,
          purchaseId: 'tx-4',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(container.read(entitlementProvider).analysisCredits, 0);
    },
  );

  test('buy platform hatası fırlatırsa akış error olur', () async {
    final fake = _FakePurchaseRepository()..buyError = StateError('boom');
    final container = await _container(fake);
    container.read(purchaseFlowProvider);

    await container
        .read(purchaseFlowProvider.notifier)
        .buy(_product(ProductIds.yearly));

    expect(
      container.read(purchaseFlowProvider).status,
      PurchaseFlowStatus.error,
    );
  });

  test('restore platform hatası fırlatırsa akış error olur', () async {
    final fake = _FakePurchaseRepository()..restoreError = StateError('boom');
    final container = await _container(fake);
    container.read(purchaseFlowProvider);

    await container.read(purchaseFlowProvider.notifier).restore();

    expect(
      container.read(purchaseFlowProvider).status,
      PurchaseFlowStatus.error,
    );
  });

  test('ikinci restore ilk zamanlayıcı yüzünden erken sıfırlanmaz', () async {
    final fake = _FakePurchaseRepository();
    final container = await _container(fake);
    container.read(purchaseFlowProvider);
    final notifier = container.read(purchaseFlowProvider.notifier);

    fakeAsync((async) {
      notifier.restore();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 3));
      notifier.restore();
      async.flushMicrotasks();
      // İlk zamanlayıcı (4 sn) dolar; ikincisi (3+4=7 sn) henüz dolmadı.
      async.elapse(const Duration(seconds: 2));
      expect(
        container.read(purchaseFlowProvider).status,
        PurchaseFlowStatus.pending,
      );
      async.elapse(const Duration(seconds: 3));
      expect(
        container.read(purchaseFlowProvider).status,
        PurchaseFlowStatus.idle,
      );
    });
  });

  test('aynı paket işlemi art arda gelirse kredi bir kez verilir', () async {
    final fake = _FakePurchaseRepository();
    final container = await _container(fake);
    container.read(purchaseFlowProvider);

    final purchase = _purchase(
      productId: ProductIds.pack500,
      status: PurchaseStatus.purchased,
      purchaseId: 'tx-race',
    );
    fake.emit(purchase);
    fake.emit(purchase);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(entitlementProvider).analysisCredits, 500);
  });
}

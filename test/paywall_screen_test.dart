// Paywall: kapatma yüklemede de görünür; plan seçimi CTA etiketini değiştirir;
// paket odaklı açılışta abonelik CTA'sı katlanır (Reduce Motion'da
// kaydırmadan atlar); ürün yoksa yeniden dene.
import 'dart:async';

import 'package:ai_gallery_organizer/core/constants/app_constants.dart';
import 'package:ai_gallery_organizer/core/services/preferences_service.dart';
import 'package:ai_gallery_organizer/core/theme/app_theme.dart';
import 'package:ai_gallery_organizer/core/widgets/sheet_close_button.dart';
import 'package:ai_gallery_organizer/core/widgets/spring_visibility.dart';
import 'package:ai_gallery_organizer/features/paywall/data/purchase_repository.dart';
import 'package:ai_gallery_organizer/features/paywall/paywall_screen.dart';
import 'package:ai_gallery_organizer/features/paywall/providers/purchase_provider.dart';
import 'package:ai_gallery_organizer/features/paywall/widgets/paywall_chrome.dart';
import 'package:ai_gallery_organizer/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

final AppLocalizations _l10n = lookupAppLocalizations(const Locale('en'));

/// Gerçek IAP kanalına dokunmayan repo: satın alma akışı boş akışa abone olur.
class _FakePurchaseRepository extends PurchaseRepository {
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => const Stream.empty();
}

ProductDetails _product(String id, double price) => ProductDetails(
  id: id,
  title: id,
  description: id,
  price: '\$${price.toStringAsFixed(2)}',
  rawPrice: price,
  currencyCode: 'USD',
  currencySymbol: '\$',
);

final List<ProductDetails> _catalog = [
  _product(ProductIds.monthly, 3.99),
  _product(ProductIds.yearly, 29.99),
  _product(ProductIds.lifetime, 59.99),
  _product(ProductIds.pack500, 4.99),
  _product(ProductIds.pack1000, 7.99),
];

Future<void> _pump(
  WidgetTester tester, {
  required Future<List<ProductDetails>> Function() products,
  bool scrollToPacks = false,
  bool reduceMotion = false,
}) async {
  // iPhone 17 ölçüsü: planlar ve paketler aynı anda sığmaz.
  tester.view.physicalSize = const Size(1206, 2622);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        purchaseRepositoryProvider.overrideWithValue(_FakePurchaseRepository()),
        purchaseProductsProvider.overrideWith((ref) => products()),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
        home: PaywallScreen(scrollToPacks: scrollToPacks),
      ),
    ),
  );
}

Finder _cta(String label) =>
    find.descendant(of: find.byType(PaywallCtaBar), matching: find.text(label));

bool _ctaVisible(WidgetTester tester) => tester
    .widget<SpringVisibility>(
      find.ancestor(
        of: find.byType(PaywallCtaBar),
        matching: find.byType(SpringVisibility),
      ),
    )
    .visible;

void main() {
  testWidgets('ürünler yüklenirken de kapatma butonu görünür', (tester) async {
    final Completer<List<ProductDetails>> never = Completer();
    await _pump(tester, products: () => never.future);
    await tester.pump();

    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    expect(find.byType(SheetCloseButton), findsOneWidget);
    expect(find.bySemanticsLabel(_l10n.dismissAction), findsOneWidget);
  });

  testWidgets('yıllık varsayılan; aylık seçilince CTA "Devam" olur', (
    tester,
  ) async {
    await _pump(tester, products: () async => _catalog);
    await tester.pumpAndSettle();

    expect(_cta(_l10n.paywallCtaTrial), findsOneWidget);
    expect(_ctaVisible(tester), isTrue);

    final Finder monthly = find.text(
      _l10n.paywallPlanMonthly,
      skipOffstage: false,
    );
    await tester.ensureVisible(monthly);
    await tester.pumpAndSettle();
    await tester.tap(monthly);
    await tester.pumpAndSettle();

    expect(_cta(_l10n.paywallContinueAction), findsOneWidget);
    expect(_cta(_l10n.paywallCtaTrial), findsNothing);
  });

  testWidgets('paket odaklı açılışta abonelik CTA\'sı katlanır', (
    tester,
  ) async {
    await _pump(tester, products: () async => _catalog, scrollToPacks: true);
    await tester.pumpAndSettle();

    expect(find.text(_l10n.paywallPacksTitle), findsOneWidget);
    expect(_ctaVisible(tester), isFalse);

    // Planlara geri dönünce çağrı yeniden belirir.
    await tester.drag(find.byType(ListView), const Offset(0, 3000));
    await tester.pumpAndSettle();
    expect(_ctaVisible(tester), isTrue);
  });

  testWidgets('Reduce Motion: paket odaklı açılış kaydırmadan atlar', (
    tester,
  ) async {
    await _pump(
      tester,
      products: () async => _catalog,
      scrollToPacks: true,
      reduceMotion: true,
    );
    // Ürünler → ilk kare → atlama → bir kare sonraki düzeltme; süre geçmez.
    for (int i = 0; i < 4; i++) {
      await tester.pump();
    }

    final ScrollPosition position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    expect(position.pixels, greaterThan(0));
    expect(position.pixels, position.maxScrollExtent);
  });

  testWidgets('ürün gelmezse açıklama ve yeniden dene', (tester) async {
    await _pump(tester, products: () async => const []);
    await tester.pumpAndSettle();

    expect(find.text(_l10n.paywallProductsUnavailableTitle), findsOneWidget);
    expect(find.text(_l10n.retryAction), findsOneWidget);
    expect(find.byType(SheetCloseButton), findsOneWidget);
  });
}

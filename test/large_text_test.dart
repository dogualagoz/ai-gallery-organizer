// Dynamic Type: en büyük erişilebilirlik boyutunda (AX5 ≈ 3.1x) sheet'ler,
// onboarding ve analiz modülü taşmadan kurulur. Flutter testleri RenderFlex
// taşmasında kendiliğinden düşer.
import 'package:ai_gallery_organizer/core/constants/app_constants.dart';
import 'package:ai_gallery_organizer/core/constants/app_icons.dart';
import 'package:ai_gallery_organizer/core/models/screenshot_category.dart';
import 'package:ai_gallery_organizer/core/models/screenshot_entry.dart';
import 'package:ai_gallery_organizer/core/services/preferences_service.dart';
import 'package:ai_gallery_organizer/core/theme/app_theme.dart';
import 'package:ai_gallery_organizer/features/analysis/milestone_screen.dart';
import 'package:ai_gallery_organizer/features/analysis/providers/analysis_queue_provider.dart';
import 'package:ai_gallery_organizer/features/analysis/widgets/analysis_status_module.dart';
import 'package:ai_gallery_organizer/features/analysis/widgets/analysis_status_views.dart';
import 'package:ai_gallery_organizer/features/onboarding/onboarding_screen.dart';
import 'package:ai_gallery_organizer/features/onboarding/widgets/sort_illustration.dart';
import 'package:ai_gallery_organizer/features/paywall/data/purchase_repository.dart';
import 'package:ai_gallery_organizer/features/paywall/paywall_screen.dart';
import 'package:ai_gallery_organizer/features/paywall/providers/purchase_provider.dart';
import 'package:ai_gallery_organizer/features/settings/providers/package_info_provider.dart';
import 'package:ai_gallery_organizer/features/settings/settings_screen.dart';
import 'package:ai_gallery_organizer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// iOS'un en büyük erişilebilirlik metin boyutu (gövde 17pt → 53pt).
const double _ax5 = 53 / 17;

class _FakePurchaseRepository extends PurchaseRepository {
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => const Stream.empty();
}

/// Tur özeti en uzun kategori adlarıyla dolu kuyruk.
class _FinishedQueue extends AnalysisQueueNotifier {
  @override
  AnalysisQueueState build() => const AnalysisQueueState(
    status: AnalysisQueueStatus.limitReached,
    done: FreeLimits.aiAnalysis,
    total: FreeLimits.aiAnalysis,
    categoryCounts: {
      ScreenshotCategory.notesPasswords: 40,
      ScreenshotCategory.entertainment: 35,
      ScreenshotCategory.inspiration: 25,
    },
  );
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

Future<void> _pump(
  WidgetTester tester, {
  required Widget home,
  required String locale,
  List<Object> overrides = const [],
  Map<String, Object> prefsValues = const {},
}) async {
  // En dar güncel iPhone genişliği (375pt).
  tester.view.physicalSize = const Size(1125, 2436);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({
    // Haftalık pencere taze olsun ki migration sayaçları sıfırlamasın.
    PrefKeys.aiWeekStart: DateTime.now().millisecondsSinceEpoch,
    ...prefsValues,
  });
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        ...overrides.cast(),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(_ax5),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Kütüphanedeki gibi kenar boşluklu, kaydırılabilir sütunda parçalar.
Widget _column(List<Widget> children) => Scaffold(
  body: SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: children,
      ),
    ),
  ),
);

List<ScreenshotEntry> _pending(int count) => [
  for (int i = 0; i < count; i++)
    ScreenshotEntry(assetId: 'p$i', createdAt: DateTime(2026)),
];

/// Tembel listeyi sonuna kadar kaydırır; her satır en az bir kez kurulur.
Future<void> _scrollThrough(WidgetTester tester, Finder scrollable) async {
  for (int i = 0; i < 30; i++) {
    await tester.drag(scrollable, const Offset(0, -600));
    await tester.pumpAndSettle();
  }
}

void main() {
  for (final String locale in ['en', 'tr']) {
    testWidgets('paywall ($locale) en büyük yazıda taşmaz', (tester) async {
      await _pump(
        tester,
        locale: locale,
        home: const PaywallScreen(),
        overrides: [
          purchaseRepositoryProvider.overrideWithValue(
            _FakePurchaseRepository(),
          ),
          purchaseProductsProvider.overrideWith(
            (ref) async => [
              _product(ProductIds.monthly, 3.99),
              _product(ProductIds.yearly, 29.99),
              _product(ProductIds.lifetime, 59.99),
              _product(ProductIds.pack500, 4.99),
              _product(ProductIds.pack1000, 7.99),
            ],
          ),
        ],
      );
      // Fiyat yan yana sığmaz; plan adının altına iner.
      final AppLocalizations l10n = lookupAppLocalizations(Locale(locale));
      final Finder yearly = find.text(l10n.paywallPlanYearly);
      // Büyük yazıda planlar ilk ekranın çok altında, henüz kurulmamış.
      await tester.scrollUntilVisible(
        yearly,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('\$29.99')).dy,
        greaterThan(tester.getBottomLeft(yearly).dy),
      );
      await _scrollThrough(tester, find.byType(ListView));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Ayarlar ($locale) en büyük yazıda taşmaz', (tester) async {
      await _pump(
        tester,
        locale: locale,
        home: const SettingsScreen(),
        overrides: [
          packageInfoProvider.overrideWith(
            (ref) async => PackageInfo(
              appName: kAppName,
              packageName: 'test',
              version: '1.3.0',
              buildNumber: '11',
            ),
          ),
        ],
      );
      await _scrollThrough(tester, find.byType(CustomScrollView));
      expect(tester.takeException(), isNull);
    });

    testWidgets('milestone ($locale) en büyük yazıda taşmaz', (tester) async {
      await _pump(
        tester,
        locale: locale,
        home: const MilestoneScreen(),
        overrides: [analysisQueueProvider.overrideWith(_FinishedQueue.new)],
      );
      await _scrollThrough(tester, find.byType(CustomScrollView));
      expect(tester.takeException(), isNull);
    });

    testWidgets('analiz modülü ($locale) en büyük yazıda taşmaz', (
      tester,
    ) async {
      await _pump(
        tester,
        locale: locale,
        prefsValues: {
          PrefKeys.aiAnalysisUsed: 90,
          PrefKeys.analysisCredits: 25,
        },
        home: _column([
          AnalysisStatusModule(entries: _pending(7)),
          AnalysisProgressCard(
            processed: 120,
            total: 400,
            source: null,
            onPause: () {},
          ),
          AnalysisSummaryRow(done: 120, categories: 12, onDone: () {}),
          AnalysisMessageRow(
            icon: AppIcons.error,
            text: lookupAppLocalizations(Locale(locale)).analysisFailedBanner,
            actionLabel: lookupAppLocalizations(Locale(locale))
                .analysisRetryAction,
            onAction: () {},
            onDismiss: () {},
          ),
        ]),
      );
      // Eylem metnin yanında değil altında.
      final AppLocalizations l10n = lookupAppLocalizations(Locale(locale));
      expect(
        tester.getTopLeft(find.text(l10n.analysisStartAction)).dy,
        greaterThan(
          tester.getBottomLeft(find.text(l10n.analyzeUngroupedBar(7))).dy,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('hak bitince kota satırı ($locale) taşmaz', (tester) async {
      await _pump(
        tester,
        locale: locale,
        prefsValues: {PrefKeys.aiAnalysisUsed: FreeLimits.aiAnalysis},
        home: _column([AnalysisStatusModule(entries: _pending(5))]),
      );
      expect(find.byType(AnalysisQuotaRow), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('onboarding ($locale) her sayfada taşmaz', (tester) async {
      await _pump(tester, locale: locale, home: const OnboardingScreen());
      // Dekoratif illüstrasyon metne yer açmak için kurulmaz.
      expect(find.byType(SortIllustration), findsNothing);
      final String next = lookupAppLocalizations(Locale(locale))
          .onboardingContinue;
      for (int page = 0; page < 3; page++) {
        await tester.ensureVisible(find.text(next));
        await tester.tap(find.text(next));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }
}

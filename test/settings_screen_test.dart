// Ayarlar sheet'i: free/Pro'ya göre Pro satırı, kota ayrıntısı ve abonelik
// yönetimi; tema segmenti tercihi değiştirir; sheet'te geri chevron'u yok.
import 'package:ai_gallery_organizer/core/constants/app_constants.dart';
import 'package:ai_gallery_organizer/core/services/preferences_service.dart';
import 'package:ai_gallery_organizer/core/theme/app_theme.dart';
import 'package:ai_gallery_organizer/features/settings/providers/package_info_provider.dart';
import 'package:ai_gallery_organizer/features/settings/settings_screen.dart';
import 'package:ai_gallery_organizer/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

final AppLocalizations _l10n = lookupAppLocalizations(const Locale('en'));

/// Pro yetkisi: [productId] ile [ago] önce satın alınmış.
Map<String, Object> _pro(String productId, Duration ago) => {
  PrefKeys.isPro: true,
  PrefKeys.proProductId: productId,
  PrefKeys.proPurchaseMs: DateTime.now().subtract(ago).millisecondsSinceEpoch,
};

Future<ProviderContainer> _pump(
  WidgetTester tester, [
  Map<String, Object> prefsValues = const {},
]) async {
  // Tüm bölümler tek ekrana sığsın (sliver liste görünmeyeni kurmaz).
  tester.view.physicalSize = const Size(1179, 7000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(prefsValues);
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final ProviderContainer container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
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
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SettingsScreen(),
      ),
    ),
  );
  await tester.pump();
  return container;
}

void main() {
  testWidgets('free: teklif satırı, haftalık kota, abonelik yönetimi yok', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text(_l10n.settingsGoPro), findsOneWidget);
    expect(find.text(_l10n.settingsWeeklyQuota), findsOneWidget);
    expect(
      find.text('${FreeLimits.aiAnalysis} / ${FreeLimits.aiAnalysis}'),
      findsOneWidget,
    );
    expect(find.text(_l10n.settingsManageSubscription), findsNothing);
    // Otomatik düzenleme free'de kilitli satır: anahtar yok.
    expect(find.byType(CupertinoSwitch), findsNothing);
    expect(find.text('1.3.0 (11)'), findsOneWidget);
  });

  testWidgets('Pro abonelik: sınırsız analiz, anahtar ve abonelik yönetimi', (
    tester,
  ) async {
    await _pump(tester, _pro(ProductIds.yearly, const Duration(days: 30)));

    expect(find.text(_l10n.settingsProActive), findsOneWidget);
    expect(find.text(_l10n.settingsUnlimited), findsOneWidget);
    expect(find.byType(CupertinoSwitch), findsOneWidget);
    expect(find.text(_l10n.settingsManageSubscription), findsOneWidget);
  });

  testWidgets('deneme haftası: kalan deneme hakkı gösterilir', (tester) async {
    await _pump(tester, _pro(ProductIds.yearly, const Duration(days: 1)));

    expect(find.text(_l10n.settingsTrialQuota), findsOneWidget);
    expect(
      find.text('${TrialLimits.aiAnalysis} / ${TrialLimits.aiAnalysis}'),
      findsOneWidget,
    );
  });

  testWidgets('ömür boyu Pro: yönetilecek abonelik yok', (tester) async {
    await _pump(tester, _pro(ProductIds.lifetime, const Duration(days: 30)));

    expect(find.text(_l10n.settingsManageSubscription), findsNothing);
  });

  testWidgets('tema segmenti tercihi değiştirir; geri chevron yok', (
    tester,
  ) async {
    final ProviderContainer container = await _pump(tester);
    // Sheet gibi geri gidilebilir bir rotada açılır: otomatik geri butonu
    // gelmemeli, kapatma "Bitti"de.
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(CupertinoPageRoute<void>(builder: (_) => const SettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoNavigationBarBackButton), findsNothing);
    expect(find.text(_l10n.doneAction), findsOneWidget);

    await tester.tap(find.text(_l10n.settingsThemeDark));
    await tester.pumpAndSettle();
    expect(container.read(themeModeProvider), ThemeMode.dark);
  });
}

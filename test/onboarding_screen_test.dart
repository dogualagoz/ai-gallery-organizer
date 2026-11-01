// Onboarding: "Devam" sayfaları ilerletir ve son sayfada da "Devam" kalır;
// izin reddinde aynı sayfada Ayarlar / Şimdilik geç çıkar, izin verilince
// akış tamamlanır. Hareket açıkken döngülü illüstrasyonlar da kurulur.
import 'package:ai_gallery_organizer/core/services/preferences_service.dart';
import 'package:ai_gallery_organizer/core/theme/app_theme.dart';
import 'package:ai_gallery_organizer/features/onboarding/onboarding_screen.dart';
import 'package:ai_gallery_organizer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final AppLocalizations _l10n = lookupAppLocalizations(const Locale('en'));

const MethodChannel _photoChannel = MethodChannel(
  'com.fluttercandies/photo_manager',
);

/// photo_manager PermissionState sırası: denied = 2, authorized = 3.
const int _denied = 2;
const int _authorized = 3;

/// İzin istemine [state] döndüren sahte platform kanalı.
void _mockPermission(int state) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_photoChannel, (call) async {
        return switch (call.method) {
          'requestPermissionExtend' || 'getPermissionState' => state,
          _ => null,
        };
      });
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_photoChannel, null),
  );
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  bool reduceMotion = true,
}) async {
  SharedPreferences.setMockInitialValues({});
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final ProviderContainer container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
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
        // Hareket azaltıldığında döngüler durur, pumpAndSettle biter.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
        home: const OnboardingScreen(),
      ),
    ),
  );
  return container;
}

Future<void> _continueToAccessPage(WidgetTester tester) async {
  for (int i = 0; i < 3; i++) {
    await tester.tap(find.text(_l10n.onboardingContinue));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('son sayfada "Devam" ve sınırlı erişim notu', (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();
    expect(find.text(_l10n.onboardingTitle1), findsOneWidget);

    await _continueToAccessPage(tester);

    expect(find.text(_l10n.onboardingTitle3), findsOneWidget);
    expect(find.text(_l10n.onboardingLimitedNote), findsOneWidget);
    expect(find.text(_l10n.onboardingContinue), findsOneWidget);
  });

  testWidgets('izin reddi aynı sayfada; "Şimdilik geç" akışı bitirir', (
    tester,
  ) async {
    _mockPermission(_denied);
    final ProviderContainer container = await _pump(tester);
    await tester.pumpAndSettle();
    await _continueToAccessPage(tester);

    await tester.tap(find.text(_l10n.onboardingContinue));
    await tester.pumpAndSettle();

    expect(find.text(_l10n.permissionDeniedTitle), findsOneWidget);
    expect(find.text(_l10n.openSettings), findsOneWidget);
    expect(find.text(_l10n.onboardingContinue), findsNothing);
    expect(container.read(onboardingCompleteProvider), isFalse);

    await tester.tap(find.text(_l10n.onboardingSkipForNow));
    await tester.pumpAndSettle();
    expect(container.read(onboardingCompleteProvider), isTrue);
  });

  testWidgets('izin verilince onboarding tamamlanır', (tester) async {
    _mockPermission(_authorized);
    final ProviderContainer container = await _pump(tester);
    await tester.pumpAndSettle();
    await _continueToAccessPage(tester);

    await tester.tap(find.text(_l10n.onboardingContinue));
    await tester.pumpAndSettle();

    expect(container.read(onboardingCompleteProvider), isTrue);
  });

  testWidgets('hareket açıkken yaylı geçiş ve döngüler çalışır', (
    tester,
  ) async {
    await _pump(tester, reduceMotion: false);
    // Döngüler sonsuz: settle yerine sabit adımlarla ilerlenir.
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text(_l10n.onboardingContinue));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text(_l10n.onboardingTitle2), findsOneWidget);
  });
}

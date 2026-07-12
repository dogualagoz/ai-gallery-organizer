// AnalyzeHeroButton: başlık sayısının bütçeye kırpılması ve kota satırı
// varyantları (free / free+kredi / Pro / trial) widget testleri.
import 'package:ai_gallery_organizer/core/constants/app_constants.dart';
import 'package:ai_gallery_organizer/core/services/preferences_service.dart';
import 'package:ai_gallery_organizer/core/theme/app_theme.dart';
import 'package:ai_gallery_organizer/features/analysis/widgets/analyze_hero_button.dart';
import 'package:ai_gallery_organizer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpHero(
  WidgetTester tester, {
  required int pendingCount,
  Map<String, Object> prefsValues = const {},
}) async {
  SharedPreferences.setMockInitialValues({
    // Haftalık pencere taze olsun ki migration sayaçları sıfırlamasın.
    PrefKeys.aiWeekStart: DateTime.now().millisecondsSinceEpoch,
    ...prefsValues,
  });
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AnalyzeHeroButton(pendingCount: pendingCount)),
      ),
    ),
  );
}

void main() {
  testWidgets('free kullanıcıda başlık kalan hakka kırpılır', (tester) async {
    // 40 kullanılmış → 60 kaldı; 197 bekleyene rağmen başlık 60 demeli.
    await _pumpHero(
      tester,
      pendingCount: 197,
      prefsValues: {PrefKeys.aiAnalysisUsed: 40},
    );

    expect(find.text('Analyze 60 screenshots'), findsOneWidget);
    expect(
      find.text('60 of ${FreeLimits.aiAnalysis} free analyses left this week'),
      findsOneWidget,
    );
  });

  testWidgets('kredili free kullanıcıda krediler ayrı gösterilir', (
    tester,
  ) async {
    await _pumpHero(
      tester,
      pendingCount: 197,
      prefsValues: {
        PrefKeys.aiAnalysisUsed: FreeLimits.aiAnalysis,
        PrefKeys.analysisCredits: 500,
      },
    );

    // Bütçe 0+500 → başlık bekleyenin tamamı; satır "0/100 + 500 kredi".
    expect(find.text('Analyze 197 screenshots'), findsOneWidget);
    expect(
      find.text('0 of ${FreeLimits.aiAnalysis} weekly free + 500 credits'),
      findsOneWidget,
    );
  });

  testWidgets('Pro kullanıcıda sınırsız satırı ve tam sayı görünür', (
    tester,
  ) async {
    await _pumpHero(
      tester,
      pendingCount: 197,
      prefsValues: {PrefKeys.isPro: true},
    );

    expect(find.text('Analyze 197 screenshots'), findsOneWidget);
    expect(find.text('Unlimited analysis with Pro'), findsOneWidget);
  });

  testWidgets('trial penceresinde kalan trial hakkı görünür', (tester) async {
    await _pumpHero(
      tester,
      pendingCount: 400,
      prefsValues: {
        PrefKeys.isPro: true,
        PrefKeys.proProductId: ProductIds.yearly,
        PrefKeys.proPurchaseMs: DateTime.now().millisecondsSinceEpoch,
        PrefKeys.trialAnalysisUsed: 50,
      },
    );

    // 250-50 = 200 kaldı; başlık min(400, 200) = 200.
    expect(find.text('Analyze 200 screenshots'), findsOneWidget);
    expect(find.text('200 trial analyses left'), findsOneWidget);
  });
}

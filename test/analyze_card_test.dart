// AnalyzeCard sunum parçaları: idle istatistik/kota tile'ları (free / Pro /
// trial), tur sonu özeti ve terminal mesaj satırı widget testleri.
import 'package:ai_gallery_organizer/core/constants/app_constants.dart';
import 'package:ai_gallery_organizer/core/services/preferences_service.dart';
import 'package:ai_gallery_organizer/core/theme/app_theme.dart';
import 'package:ai_gallery_organizer/features/analysis/widgets/analyze_card_content.dart';
import 'package:ai_gallery_organizer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// L10n + tema saran, provider gerektirmeyen basit pump (sunum widget'ları).
Future<void> _pumpPlain(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

/// entitlementProvider'ı prefs üzerinden besleyen idle pump.
Future<void> _pumpIdle(
  WidgetTester tester, {
  required int pending,
  required int analyzed,
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
        home: Scaffold(
          body: AnalyzeIdle(
            pending: pending,
            analyzed: analyzed,
            onAnalyze: () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('idle free kullanıcıda bekleyen/analiz/kalan tile görünür', (
    tester,
  ) async {
    // 40 kullanılmış → 60 kaldı.
    await _pumpIdle(
      tester,
      pending: 197,
      analyzed: 10,
      prefsValues: {PrefKeys.aiAnalysisUsed: 40},
    );

    expect(find.text('197'), findsOneWidget); // bekleyen
    expect(find.text('10'), findsOneWidget); // analiz edildi
    expect(find.text('60'), findsOneWidget); // kalan hak
    expect(find.text('Analyze'), findsOneWidget); // buton
  });

  testWidgets('idle Pro kullanıcıda kalan hak "Unlimited" gösterir', (
    tester,
  ) async {
    await _pumpIdle(
      tester,
      pending: 42,
      analyzed: 5,
      prefsValues: {PrefKeys.isPro: true},
    );

    expect(find.text('Unlimited'), findsOneWidget);
  });

  testWidgets('idle trial penceresinde kalan trial hakkı görünür', (
    tester,
  ) async {
    await _pumpIdle(
      tester,
      pending: 400,
      analyzed: 0,
      prefsValues: {
        PrefKeys.isPro: true,
        PrefKeys.proProductId: ProductIds.yearly,
        PrefKeys.proPurchaseMs: DateTime.now().millisecondsSinceEpoch,
        PrefKeys.trialAnalysisUsed: 50,
      },
    );

    // 250 - 50 = 200 trial hakkı.
    expect(find.text('200'), findsOneWidget);
  });

  testWidgets('inline özet başlık + sayı metnini gösterir', (tester) async {
    await _pumpPlain(
      tester,
      AnalyzeInlineSummary(done: 12, categories: 7, onDone: () {}),
    );

    expect(find.text('All sorted'), findsOneWidget);
    expect(
      find.text('12 screenshots settled into 7 categories'),
      findsOneWidget,
    );
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('mesaj satırı metin + aksiyonu gösterir', (tester) async {
    await _pumpPlain(
      tester,
      AnalyzeMessageRow(
        icon: Icons.error_outline,
        text: 'Analysis failed',
        actionLabel: 'Retry',
        onAction: () {},
        onDismiss: () {},
      ),
    );

    expect(find.text('Analysis failed'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}

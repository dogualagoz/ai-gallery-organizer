// Kütüphane analiz durum modülü: kota metninin free / Pro / deneme / kredi
// durumlarına göre seçimi, hak bitince tek eylemli satır ve sunum parçaları.
import 'package:ai_gallery_organizer/core/constants/app_constants.dart';
import 'package:ai_gallery_organizer/core/constants/app_icons.dart';
import 'package:ai_gallery_organizer/core/models/screenshot_category.dart';
import 'package:ai_gallery_organizer/core/models/screenshot_entry.dart';
import 'package:ai_gallery_organizer/core/services/preferences_service.dart';
import 'package:ai_gallery_organizer/core/theme/app_theme.dart';
import 'package:ai_gallery_organizer/features/analysis/providers/analysis_queue_provider.dart';
import 'package:ai_gallery_organizer/features/analysis/providers/analysis_summary_provider.dart';
import 'package:ai_gallery_organizer/features/analysis/providers/recent_distribution_provider.dart';
import 'package:ai_gallery_organizer/features/analysis/widgets/analysis_status_module.dart';
import 'package:ai_gallery_organizer/features/analysis/widgets/analysis_status_views.dart';
import 'package:ai_gallery_organizer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// L10n (İngilizce) + tema saran, provider gerektirmeyen pump.
Future<void> _pumpPlain(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

/// [pending] bekleyen + 1 analiz edilmiş kayıtla modülü, entitlement'ı
/// prefs üzerinden besleyerek kurar.
Future<void> _pumpModule(
  WidgetTester tester, {
  required int pending,
  Map<String, Object> prefsValues = const {},
}) async {
  SharedPreferences.setMockInitialValues({
    // Haftalık pencere taze olsun ki migration sayaçları sıfırlamasın.
    PrefKeys.aiWeekStart: DateTime.now().millisecondsSinceEpoch,
    ...prefsValues,
  });
  final prefs = await SharedPreferences.getInstance();
  final DateTime now = DateTime.now();
  final List<ScreenshotEntry> entries = [
    for (int i = 0; i < pending; i++)
      ScreenshotEntry(assetId: 'p$i', createdAt: now),
    ScreenshotEntry(assetId: 'done', createdAt: now, analyzedAt: now),
  ];

  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AnalysisStatusModule(entries: entries)),
      ),
    ),
  );
}

/// Kuyruk durumunu doğrudan yayınlayabilen test kuyruğu.
class _FakeQueue extends AnalysisQueueNotifier {
  void emit(AnalysisQueueState next) => state = next;
}

void main() {
  group('analysisSummaryProvider', () {
    test('tur bitince özet bekler ve dağılımı kaydeder; yeni tur kaldırır', () {
      final container = ProviderContainer(
        overrides: [analysisQueueProvider.overrideWith(_FakeQueue.new)],
      );
      addTearDown(container.dispose);
      container.listen(analysisSummaryProvider, (_, _) {});
      final _FakeQueue queue =
          container.read(analysisQueueProvider.notifier) as _FakeQueue;
      final ScreenshotCategory category = ScreenshotCategory.values.first;

      queue.emit(
        const AnalysisQueueState(status: AnalysisQueueStatus.running, total: 2),
      );
      queue.emit(
        AnalysisQueueState(
          status: AnalysisQueueStatus.completed,
          done: 2,
          total: 2,
          categoryCounts: {category: 2},
        ),
      );
      expect(container.read(analysisSummaryProvider), isTrue);
      expect(container.read(recentDistributionProvider), {category: 2});

      queue.emit(
        const AnalysisQueueState(status: AnalysisQueueStatus.running, total: 1),
      );
      expect(container.read(analysisSummaryProvider), isFalse);
    });

    test('hiç analiz yoksa özet açılmaz', () {
      final container = ProviderContainer(
        overrides: [analysisQueueProvider.overrideWith(_FakeQueue.new)],
      );
      addTearDown(container.dispose);
      container.listen(analysisSummaryProvider, (_, _) {});
      final _FakeQueue queue =
          container.read(analysisQueueProvider.notifier) as _FakeQueue;

      queue.emit(
        const AnalysisQueueState(status: AnalysisQueueStatus.running, total: 3),
      );
      queue.emit(
        const AnalysisQueueState(
          status: AnalysisQueueStatus.limitReached,
          total: 3,
        ),
      );
      expect(container.read(analysisSummaryProvider), isFalse);
    });
  });

  group('AnalysisStatusModule', () {
    testWidgets('free kullanıcıda bekleyen kartı haftalık kotayı gösterir', (
      tester,
    ) async {
      await _pumpModule(
        tester,
        pending: 7,
        prefsValues: {PrefKeys.aiAnalysisUsed: 40},
      );

      expect(find.text('7 new screenshots to organize'), findsOneWidget);
      expect(
        find.text(
          '60 of ${FreeLimits.aiAnalysis} free analyses left this week',
        ),
        findsOneWidget,
      );
      expect(find.text('Analyze'), findsOneWidget);
    });

    testWidgets('kredi varsa kota metni krediyi de sayar', (tester) async {
      await _pumpModule(
        tester,
        pending: 3,
        prefsValues: {
          PrefKeys.aiAnalysisUsed: 90,
          PrefKeys.analysisCredits: 25,
        },
      );

      expect(
        find.text('10 of ${FreeLimits.aiAnalysis} weekly free + 25 credits'),
        findsOneWidget,
      );
    });

    testWidgets('Pro kullanıcıda sınırsız yazar', (tester) async {
      await _pumpModule(
        tester,
        pending: 42,
        prefsValues: {PrefKeys.isPro: true},
      );

      expect(find.text('Unlimited analysis with Pro'), findsOneWidget);
    });

    testWidgets('deneme penceresinde kalan deneme hakkını yazar', (
      tester,
    ) async {
      await _pumpModule(
        tester,
        pending: 400,
        prefsValues: {
          PrefKeys.isPro: true,
          PrefKeys.proProductId: ProductIds.yearly,
          PrefKeys.proPurchaseMs: DateTime.now().millisecondsSinceEpoch,
          PrefKeys.trialAnalysisUsed: 50,
        },
      );

      // 250 - 50 = 200 deneme hakkı.
      expect(find.text('200 trial analyses left'), findsOneWidget);
    });

    testWidgets('hak bitince tek eylemli kota satırı çıkar', (tester) async {
      await _pumpModule(
        tester,
        pending: 5,
        prefsValues: {PrefKeys.aiAnalysisUsed: FreeLimits.aiAnalysis},
      );

      expect(find.text('5 screenshots waiting for analysis'), findsOneWidget);
      expect(find.text('Get More'), findsOneWidget);
      expect(find.text('Analyze'), findsNothing);
    });

    testWidgets('bekleyen yoksa modül gizlenir', (tester) async {
      await _pumpModule(tester, pending: 0);

      expect(find.byType(AnalysisPendingCard), findsNothing);
      expect(find.byType(AnalysisQuotaRow), findsNothing);
    });
  });

  group('Sunum parçaları', () {
    testWidgets('bekleyen kartındaki buton analizi başlatır', (tester) async {
      int taps = 0;
      await _pumpPlain(
        tester,
        AnalysisPendingCard(
          pending: 3,
          quotaHint: 'hint',
          onAnalyze: () => taps++,
        ),
      );

      await tester.tap(find.text('Analyze'));
      expect(taps, 1);
    });

    testWidgets('ilerleme kartı sayıyı ve duraklat eylemini gösterir', (
      tester,
    ) async {
      int pauses = 0;
      await _pumpPlain(
        tester,
        AnalysisProgressCard(
          processed: 12,
          total: 40,
          source: null,
          onPause: () => pauses++,
        ),
      );

      expect(find.text('12 of 40 analyzed'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Pause'));
      expect(pauses, 1);
    });

    testWidgets('özet satırı başlık + sayı metnini gösterir', (tester) async {
      await _pumpPlain(
        tester,
        AnalysisSummaryRow(done: 12, categories: 7, onDone: () {}),
      );

      expect(find.text('All sorted'), findsOneWidget);
      expect(
        find.text('12 screenshots settled into 7 categories'),
        findsOneWidget,
      );
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('mesaj satırı metin + eylem + kapat gösterir', (tester) async {
      int dismissed = 0;
      await _pumpPlain(
        tester,
        AnalysisMessageRow(
          icon: AppIcons.error,
          text: 'Analysis failed',
          actionLabel: 'Retry',
          onAction: () {},
          onDismiss: () => dismissed++,
        ),
      );

      expect(find.text('Analysis failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Dismiss'));
      expect(dismissed, 1);
    });
  });
}

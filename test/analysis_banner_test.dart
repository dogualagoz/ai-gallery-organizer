// AnalysisBanner: durum başına doğru içerik ve running kartının gradyanlı
// (secondaryContainer değil) olduğunu doğrulayan widget testleri.
import 'dart:typed_data';

import 'package:ai_gallery_organizer/core/models/screenshot_entry.dart';
import 'package:ai_gallery_organizer/core/models/hive/hive_registrar.g.dart';
import 'package:ai_gallery_organizer/core/services/preferences_service.dart';
import 'package:ai_gallery_organizer/core/theme/app_theme.dart';
import 'package:ai_gallery_organizer/features/analysis/providers/analysis_queue_provider.dart';
import 'package:ai_gallery_organizer/features/analysis/widgets/analysis_banner.dart';
import 'package:ai_gallery_organizer/features/gallery/data/screenshot_repository.dart';
import 'package:ai_gallery_organizer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sabit bir [AnalysisQueueState] döndüren test double'ı — gerçek `start()`
/// akışını (ağ/Hive) tetiklemeden banner'ın her duruma göre içeriğini test eder.
class _FixedQueueNotifier extends AnalysisQueueNotifier {
  _FixedQueueNotifier(this._fixed);

  final AnalysisQueueState _fixed;

  @override
  AnalysisQueueState build() => _fixed;
}

/// Disk/lock gerektirmeyen bellek-içi kutu — testlerde dosya sistemi
/// kilitlenmesine takılmamak için `bytes:` ile açılır.
bool _adaptersRegistered = false;

Future<void> _pumpBanner(
  WidgetTester tester, {
  required AnalysisQueueState queueState,
  int pendingCount = 3,
}) async {
  if (!_adaptersRegistered) {
    Hive.registerAdapters();
    _adaptersRegistered = true;
  }
  final Box<ScreenshotEntry> box = await Hive.openBox<ScreenshotEntry>(
    'test_screenshots_${DateTime.now().microsecondsSinceEpoch}',
    bytes: Uint8List(0),
  );
  addTearDown(box.close);
  await box.put(
    'pending-1',
    ScreenshotEntry(assetId: 'pending-1', createdAt: DateTime.now()),
  );

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        screenshotRepositoryProvider.overrideWithValue(
          ScreenshotRepository(box),
        ),
        analysisQueueProvider.overrideWith(
          () => _FixedQueueNotifier(queueState),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AnalysisBanner(pendingCount: pendingCount)),
      ),
    ),
  );
  await tester.pump(); // AnimatedSwitcher'ın ilk kare geçişini tamamla
}

void main() {
  testWidgets('idle + bekleyen varsa hero buton gösterilir', (tester) async {
    await _pumpBanner(
      tester,
      queueState: const AnalysisQueueState(),
      pendingCount: 3,
    );

    expect(find.text('Analyze 3 screenshots'), findsOneWidget);
  });

  testWidgets(
    'running kartı düz secondaryContainer değil gradyanla çizilir',
    (tester) async {
      await _pumpBanner(
        tester,
        queueState: const AnalysisQueueState(
          status: AnalysisQueueStatus.running,
          done: 2,
          total: 5,
        ),
      );

      expect(find.text('Organizing your screenshots'), findsOneWidget);
      expect(find.text('2 of 5 analyzed'), findsOneWidget);

      final Iterable<Container> containers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.decoration is BoxDecoration);
      final bool hasGradientContainer = containers.any(
        (c) => (c.decoration! as BoxDecoration).gradient != null,
      );
      expect(
        hasGradientContainer,
        isTrue,
        reason:
            'running kartı AnalyzeHeroButton ile aynı gradyanı kullanmalı, '
            'düz gri/pale bir renk değil',
      );
    },
  );

  testWidgets('completed durumunda sonuç özeti görünür', (tester) async {
    await _pumpBanner(
      tester,
      queueState: const AnalysisQueueState(
        status: AnalysisQueueStatus.completed,
        done: 4,
      ),
    );

    expect(find.text('4 screenshots analyzed'), findsOneWidget);
  });

  testWidgets('failed durumunda hata mesajı ve tekrar dene görünür', (
    tester,
  ) async {
    await _pumpBanner(
      tester,
      queueState: const AnalysisQueueState(status: AnalysisQueueStatus.failed),
    );

    expect(
      find.text('Analysis failed. Check your connection and try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });
}

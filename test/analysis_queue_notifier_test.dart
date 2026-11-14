// AnalysisQueueNotifier: iptal/sıfırlama yarışları, tekil analiz kilidi, bütçe.
import 'dart:async';
import 'dart:io';

import 'package:ai_gallery_organizer/core/models/hive/hive_registrar.g.dart';
import 'package:ai_gallery_organizer/core/models/screenshot_category.dart';
import 'package:ai_gallery_organizer/core/models/screenshot_entry.dart';
import 'package:ai_gallery_organizer/core/services/category_priors_service.dart';
import 'package:ai_gallery_organizer/core/services/entitlement_service.dart';
import 'package:ai_gallery_organizer/core/services/preferences_service.dart';
import 'package:ai_gallery_organizer/features/analysis/data/analysis_result.dart';
import 'package:ai_gallery_organizer/features/analysis/data/screenshot_analyzer.dart';
import 'package:ai_gallery_organizer/features/analysis/providers/analysis_queue_provider.dart';
import 'package:ai_gallery_organizer/features/gallery/data/screenshot_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Galeri izni olmadan, Hive box'ı üzerinde çalışan repo; asset'i uydurur.
class _TestRepo extends ScreenshotRepository {
  _TestRepo(super.box);

  @override
  AssetEntity? assetFor(String assetId) =>
      AssetEntity(id: assetId, typeInt: 1, width: 1, height: 1);
}

/// Her çağrıyı elle tamamlanan Completer'a bağlayan sahte analyzer.
class _FakeAnalyzer extends ScreenshotAnalyzer {
  final Map<String, Completer<AnalysisResult>> calls = {};

  @override
  Future<AnalysisResult> analyze(AssetEntity asset) {
    final Completer<AnalysisResult> completer = Completer();
    calls[asset.id] = completer;
    return completer.future;
  }

  void complete(String id) => calls[id]!.complete(
    const AnalysisResult(category: ScreenshotCategory.social, tags: ['t']),
  );
}

/// Hive'a dokunmayan, öneri üretmeyen kişiselleştirme.
class _NoPriors extends CategoryPriorsNotifier {
  @override
  PriorsMap build() => {};
}

void main() {
  late Directory dir;
  late Box<ScreenshotEntry> box;
  late _FakeAnalyzer analyzer;
  late ProviderContainer container;

  setUpAll(() {
    dir = Directory.systemTemp.createTempSync('queue_test');
    Hive
      ..init(dir.path)
      ..registerAdapters();
  });

  Future<void> setUpQueue({
    int pending = 3,
    Map<String, Object> prefsValues = const {},
  }) async {
    box = await Hive.openBox<ScreenshotEntry>('screenshots');
    for (int i = 0; i < pending; i++) {
      await box.put(
        'a$i',
        ScreenshotEntry(assetId: 'a$i', createdAt: DateTime(2026, 1, i + 1)),
      );
    }
    SharedPreferences.setMockInitialValues(prefsValues);
    final prefs = await SharedPreferences.getInstance();
    analyzer = _FakeAnalyzer();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        screenshotRepositoryProvider.overrideWithValue(_TestRepo(box)),
        screenshotAnalyzerProvider.overrideWithValue(analyzer),
        categoryPriorsProvider.overrideWith(_NoPriors.new),
      ],
    );
    addTearDown(container.dispose);
  }

  tearDown(() => box.deleteFromDisk());
  tearDownAll(() => dir.deleteSync(recursive: true));

  Future<void> pump() => Future<void>.delayed(Duration.zero);

  AnalysisQueueState queue() => container.read(analysisQueueProvider);
  AnalysisQueueNotifier notifier() =>
      container.read(analysisQueueProvider.notifier);

  test('tüm bekleyenler analiz edilir ve tur completed ile biter', () async {
    await setUpQueue();
    final Future<void> run = notifier().start();
    await pump();
    expect(queue().isRunning, isTrue);
    expect(queue().total, 3);

    for (final String id in analyzer.calls.keys.toList()) {
      analyzer.complete(id);
    }
    await run;

    expect(queue().status, AnalysisQueueStatus.completed);
    expect(queue().done, 3);
    expect(box.values.every((e) => !e.isPending), isTrue);
  });

  test('free kullanıcıda bütçe kalan haktan fazla öğe işlemez', () async {
    await setUpQueue(
      pending: 3,
      prefsValues: {
        PrefKeys.aiAnalysisUsed: 99,
        PrefKeys.aiWeekStart: DateTime.now().millisecondsSinceEpoch,
      },
    );
    final Future<void> run = notifier().start();
    await pump();
    expect(queue().total, 1);

    analyzer.complete(analyzer.calls.keys.single);
    await run;

    expect(queue().done, 1);
    expect(queue().status, AnalysisQueueStatus.limitReached);
    expect(container.read(entitlementProvider).remainingFreeAnalysis, 0);
  });

  test('limit doluyken start limitReached yazar ve hiç istek atmaz', () async {
    await setUpQueue(
      prefsValues: {
        PrefKeys.aiAnalysisUsed: 100,
        PrefKeys.aiWeekStart: DateTime.now().millisecondsSinceEpoch,
      },
    );
    await notifier().start();

    expect(queue().status, AnalysisQueueStatus.limitReached);
    expect(queue().freeQuotaExhausted, isTrue);
    expect(analyzer.calls, isEmpty);
  });

  test(
    'cancel sonrası dönen in-flight sonuç kaydedilmez, kredi düşmez',
    () async {
      await setUpQueue();
      final Future<void> run = notifier().start();
      await pump();

      notifier().cancel();
      expect(queue().status, AnalysisQueueStatus.completed);
      for (final String id in analyzer.calls.keys.toList()) {
        analyzer.complete(id);
      }
      await run;

      expect(queue().done, 0);
      expect(box.values.every((e) => e.isPending), isTrue);
      expect(container.read(entitlementProvider).aiAnalysisUsed, 0);
    },
  );

  test('cancel → dismiss → geç dönüş: state idle kalır', () async {
    await setUpQueue();
    final Future<void> run = notifier().start();
    await pump();

    notifier().cancel();
    notifier().dismiss();
    expect(queue().status, AnalysisQueueStatus.idle);

    for (final String id in analyzer.calls.keys.toList()) {
      analyzer.complete(id);
    }
    await run;

    expect(queue().status, AnalysisQueueStatus.idle);
    expect(queue().total, 0);
    expect(queue().failed, 0);
  });

  test(
    'cancel sonrası yeni tur başlarsa eski tur sonucu ona karışmaz',
    () async {
      await setUpQueue(pending: 1);
      final Future<void> first = notifier().start();
      await pump();
      final Completer<AnalysisResult> oldCall = analyzer.calls['a0']!;

      notifier().cancel();
      final Future<void> second = notifier().start();
      await pump();
      expect(queue().isRunning, isTrue);

      // Eski turun isteği yeni turdan önce döner: sayılmamalı.
      oldCall.complete(
        const AnalysisResult(category: ScreenshotCategory.other, tags: []),
      );
      await first;
      expect(queue().done, 0);

      analyzer.complete('a0');
      await second;
      expect(queue().done, 1);
    },
  );

  test('reset turu anında idle yapar; geç dönüş state yazmaz', () async {
    await setUpQueue();
    final Future<void> run = notifier().start();
    await pump();

    notifier().reset();
    for (final String id in analyzer.calls.keys.toList()) {
      analyzer.complete(id);
    }
    await run;

    expect(queue().status, AnalysisQueueStatus.idle);
    expect(queue().done, 0);
  });

  test('tüm istekler hata verirse tur failed ile biter', () async {
    await setUpQueue(pending: 2);
    final Future<void> run = notifier().start();
    await pump();
    for (final Completer<AnalysisResult> c in analyzer.calls.values) {
      c.completeError(StateError('ağ yok'));
    }
    await run;

    expect(queue().status, AnalysisQueueStatus.failed);
    expect(queue().failed, 2);
  });

  test('analyzeSingle sürerken kuyruk aynı screenshot\'ı atlar', () async {
    await setUpQueue(pending: 2);
    final Future<SingleAnalysisOutcome> single = notifier().analyzeSingle('a0');
    await pump();
    expect(analyzer.calls.keys, ['a0']);

    final Future<void> run = notifier().start();
    await pump();
    // Kuyruk yalnız a1'i işler: a0 için ikinci Gemini çağrısı yok.
    expect(queue().total, 1);
    expect(analyzer.calls.keys.toSet(), {'a0', 'a1'});

    analyzer.complete('a0');
    analyzer.complete('a1');
    expect(await single, SingleAnalysisOutcome.success);
    await run;
    expect(container.read(entitlementProvider).aiAnalysisUsed, 2);
  });

  test('aynı screenshot için ikinci analyzeSingle reddedilir', () async {
    await setUpQueue(pending: 1);
    final Future<SingleAnalysisOutcome> first = notifier().analyzeSingle('a0');
    await pump();

    expect(await notifier().analyzeSingle('a0'), SingleAnalysisOutcome.failed);

    analyzer.complete('a0');
    expect(await first, SingleAnalysisOutcome.success);
    expect(container.read(entitlementProvider).aiAnalysisUsed, 1);
  });

  test('analyzeSingle limit doluyken limitReached döner', () async {
    await setUpQueue(
      pending: 1,
      prefsValues: {
        PrefKeys.aiAnalysisUsed: 100,
        PrefKeys.aiWeekStart: DateTime.now().millisecondsSinceEpoch,
      },
    );
    expect(
      await notifier().analyzeSingle('a0'),
      SingleAnalysisOutcome.limitReached,
    );
    expect(analyzer.calls, isEmpty);
  });

  test('stoppedByUser: cancel işaretler, yeni tur temizler', () async {
    await setUpQueue(pending: 1);
    expect(notifier().stoppedByUser, isFalse);
    final Future<void> first = notifier().start();
    await pump();

    notifier().cancel();
    expect(notifier().stoppedByUser, isTrue);
    analyzer.complete('a0');
    await first;

    final Future<void> second = notifier().start();
    await pump();
    expect(notifier().stoppedByUser, isFalse);
    analyzer.complete('a0');
    await second;
  });
}

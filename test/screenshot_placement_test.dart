// Taşımayı geri alma: kaydın kategori/pano yerleşimi birebir eski haline döner.
import 'dart:io';

import 'package:ai_gallery_organizer/core/models/hive/hive_registrar.g.dart';
import 'package:ai_gallery_organizer/core/models/screenshot_category.dart';
import 'package:ai_gallery_organizer/core/models/screenshot_entry.dart';
import 'package:ai_gallery_organizer/features/gallery/data/screenshot_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory dir;
  late Box<ScreenshotEntry> box;
  late ScreenshotRepository repo;
  final List<ScreenshotCategory> corrections = [];

  setUpAll(() {
    dir = Directory.systemTemp.createTempSync('placement_test');
    Hive
      ..init(dir.path)
      ..registerAdapters();
  });

  setUp(() async {
    box = await Hive.openBox<ScreenshotEntry>('screenshots');
    corrections.clear();
    repo = ScreenshotRepository(
      box,
      onCorrection: (from, to, tags) async => corrections.add(to),
    );
  });

  tearDown(() => box.deleteFromDisk());

  tearDownAll(() => dir.deleteSync(recursive: true));

  test('kategoriye taşınan bekleyen pano kaydı aynen geri döner', () async {
    await box.put(
      'a',
      ScreenshotEntry(assetId: 'a', createdAt: DateTime(2026), boardId: 'b1'),
    );
    final ScreenshotPlacement before = ScreenshotPlacement.of(box.get('a')!);

    await repo.setCategory('a', ScreenshotCategory.receipts);
    expect(box.get('a')!.boardId, isNull);
    expect(box.get('a')!.isPending, isFalse);

    await repo.restorePlacement(before);
    final ScreenshotEntry restored = box.get('a')!;
    expect(restored.category, isNull);
    expect(restored.aiCategory, isNull);
    expect(restored.analyzedAt, isNull);
    expect(restored.boardId, 'b1');
  });

  test('düzeltilmiş kategori ve AI kararı geri alınınca korunur', () async {
    final DateTime analyzedAt = DateTime(2026, 3, 1);
    await box.put(
      'a',
      ScreenshotEntry(
        assetId: 'a',
        createdAt: DateTime(2026),
        category: ScreenshotCategory.shopping,
        analyzedAt: analyzedAt,
      ),
    );
    final ScreenshotPlacement before = ScreenshotPlacement.of(box.get('a')!);

    await repo.setCategory('a', ScreenshotCategory.receipts);
    expect(box.get('a')!.aiCategory, ScreenshotCategory.shopping);
    expect(corrections, [ScreenshotCategory.receipts]);

    await repo.restorePlacement(before);
    final ScreenshotEntry restored = box.get('a')!;
    expect(restored.category, ScreenshotCategory.shopping);
    expect(restored.aiCategory, isNull);
    expect(restored.analyzedAt, analyzedAt);
  });

  test('silinmiş kayıt için geri alma sessizce atlanır', () async {
    await box.put(
      'a',
      ScreenshotEntry(assetId: 'a', createdAt: DateTime(2026)),
    );
    final ScreenshotPlacement before = ScreenshotPlacement.of(box.get('a')!);
    await repo.removeEntry('a');

    await repo.restorePlacement(before);
    expect(box.get('a'), isNull);
  });
}

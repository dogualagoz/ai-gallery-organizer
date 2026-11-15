// Görüntüleyici dilimi: başka kayıtların analizi eşit sayılır (ekran yeniden
// kurulmaz); görünen kaydın değişimi, silme ve geri alma farklı sayılır.
import 'dart:io';

import 'package:ai_gallery_organizer/core/models/hive/hive_registrar.g.dart';
import 'package:ai_gallery_organizer/core/models/screenshot_category.dart';
import 'package:ai_gallery_organizer/core/models/screenshot_entry.dart';
import 'package:ai_gallery_organizer/features/detail/viewer_scope_snapshot.dart';
import 'package:ai_gallery_organizer/features/gallery/data/screenshot_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory dir;
  late Box<ScreenshotEntry> box;
  late ScreenshotRepository repo;
  const List<String> scope = ['a', 'b', 'c'];

  ViewerScopeSnapshot snapshot([String current = 'a']) =>
      ViewerScopeSnapshot.of(repo, scope, current);

  setUpAll(() {
    dir = Directory.systemTemp.createTempSync('viewer_snapshot_test');
    Hive
      ..init(dir.path)
      ..registerAdapters();
  });

  setUp(() async {
    box = await Hive.openBox<ScreenshotEntry>('screenshots');
    repo = ScreenshotRepository(box);
    await box.putAll({
      for (final String id in scope)
        id: ScreenshotEntry(assetId: id, createdAt: DateTime(2026)),
    });
  });

  tearDown(() => box.deleteFromDisk());

  tearDownAll(() => dir.deleteSync(recursive: true));

  Future<void> analyze(String id) => repo.saveAnalysis(
    assetId: id,
    category: ScreenshotCategory.receipts,
    aiCategory: ScreenshotCategory.receipts,
    tags: const ['fiş'],
  );

  test('kapsamdaki başka kaydın analizi dilimi değiştirmez', () async {
    final ViewerScopeSnapshot before = snapshot();
    await analyze('b');
    expect(snapshot(), before);
  });

  test('görünen kaydın analizi ve taşınması dilimi değiştirir', () async {
    final ViewerScopeSnapshot initial = snapshot();
    await analyze('a');
    final ViewerScopeSnapshot analyzed = snapshot();
    expect(analyzed, isNot(initial));

    await repo.assignManyToBoard(['a'], 'board');
    expect(snapshot(), isNot(analyzed));
  });

  test('silinen kayıt kapsamdan düşer, dilim değişir', () async {
    final ViewerScopeSnapshot before = snapshot();
    await repo.removeEntries(['c']);
    final ViewerScopeSnapshot after = snapshot();
    expect(after.ids, ['a', 'b']);
    expect(after, isNot(before));
  });

  test('görünen kayıt yoksa yerleşim alanı boş kalır', () async {
    await repo.removeEntries(['a']);
    expect(snapshot().current, isNull);
    expect(snapshot().ids, ['b', 'c']);
  });
}

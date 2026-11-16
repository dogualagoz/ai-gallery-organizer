// Görüntüleyici dilimi: analiz/taşıma kapsamı değiştirmez, silme değiştirir;
// görünen kaydın alanları analiz ve taşımada farklı sayılır.
import 'dart:io';

import 'package:ai_gallery_organizer/core/models/hive/hive_registrar.g.dart';
import 'package:ai_gallery_organizer/core/models/screenshot_category.dart';
import 'package:ai_gallery_organizer/core/models/screenshot_entry.dart';
import 'package:ai_gallery_organizer/features/detail/logic/viewer_scope_snapshot.dart';
import 'package:ai_gallery_organizer/features/gallery/data/screenshot_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory dir;
  late Box<ScreenshotEntry> box;
  late ScreenshotRepository repo;
  const List<String> scope = ['a', 'b', 'c'];

  ViewerScopeSnapshot snapshot() => ViewerScopeSnapshot.of(repo, scope);

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

  test('analiz ve taşıma kapsam dilimini değiştirmez', () async {
    final ViewerScopeSnapshot before = snapshot();
    await analyze('a');
    await repo.assignManyToBoard(['b'], 'board');
    expect(snapshot(), before);
  });

  test('görünen kaydın alanları analiz ve taşımada değişir', () async {
    final ViewerEntryFields? initial = viewerEntryFields(repo.entryFor('a'));
    await analyze('b');
    expect(viewerEntryFields(repo.entryFor('a')), initial);

    await analyze('a');
    final ViewerEntryFields? analyzed = viewerEntryFields(repo.entryFor('a'));
    expect(analyzed, isNot(initial));

    await repo.assignManyToBoard(['a'], 'board');
    expect(viewerEntryFields(repo.entryFor('a')), isNot(analyzed));
  });

  test('silinen kayıt kapsamdan düşer, dilim değişir', () async {
    final ViewerScopeSnapshot before = snapshot();
    await repo.removeEntries(['c']);
    final ViewerScopeSnapshot after = snapshot();
    expect(after.ids, ['a', 'b']);
    expect(after, isNot(before));
  });

  test('kayıt yoksa alanlar boş kalır', () async {
    await repo.removeEntries(['a']);
    expect(viewerEntryFields(repo.entryFor('a')), isNull);
    expect(snapshot().ids, ['b', 'c']);
  });
}

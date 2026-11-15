// Görüntüleyici duman testi: bilgi paneli açılır, sayfa kaydırınca panel
// görünen kayda geçer, kaydın kategorisi değişince panel tazelenir, görünen
// kayıt silinince sıradaki gelir.
import 'dart:async';

import 'package:ai_gallery_organizer/core/constants/app_constants.dart';
import 'package:ai_gallery_organizer/core/constants/app_icons.dart';
import 'package:ai_gallery_organizer/core/l10n/category_labels.dart';
import 'package:ai_gallery_organizer/core/models/screenshot_category.dart';
import 'package:ai_gallery_organizer/core/models/screenshot_entry.dart';
import 'package:ai_gallery_organizer/core/services/category_names_service.dart';
import 'package:ai_gallery_organizer/core/theme/app_theme.dart';
import 'package:ai_gallery_organizer/core/utils/debounced_listen.dart';
import 'package:ai_gallery_organizer/features/detail/detail_screen.dart';
import 'package:ai_gallery_organizer/features/detail/widgets/info_panel.dart';
import 'package:ai_gallery_organizer/features/gallery/data/screenshot_repository.dart';
import 'package:ai_gallery_organizer/features/gallery/providers/gallery_provider.dart';
import 'package:ai_gallery_organizer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:photo_manager/photo_manager.dart';

/// Bellekteki kayıtlarla çalışan depo; görseller yüklenmemiş sayılır.
class _FakeRepository implements ScreenshotRepository {
  _FakeRepository(Iterable<String> ids)
    : _entries = {
        for (final String id in ids)
          id: ScreenshotEntry(
            assetId: id,
            createdAt: DateTime(2026),
            category: ScreenshotCategory.receipts,
            analyzedAt: DateTime(2026),
          ),
      };

  final Map<String, ScreenshotEntry> _entries;
  final StreamController<BoxEvent> _changes = StreamController.broadcast();

  void remove(String id) {
    _entries.remove(id);
    _changes.add(BoxEvent(id, null, true));
  }

  /// Kaydı yerinde değiştirir (Hive'daki gibi) ve olay yayınlar.
  void mutate(String id, void Function(ScreenshotEntry entry) change) {
    final ScreenshotEntry entry = _entries[id]!;
    change(entry);
    _changes.add(BoxEvent(id, entry, false));
  }

  @override
  ScreenshotEntry? entryFor(String assetId) => _entries[assetId];

  @override
  AssetEntity? assetFor(String assetId) => null;

  @override
  List<ScreenshotEntry> sortedEntries() => _entries.values.toList();

  @override
  Stream<BoxEvent> watchChanges() => _changes.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Cihazla eşitlemeden yalnız depo olaylarını izleyen galeri.
class _FakeGallery extends GalleryNotifier {
  @override
  Future<List<ScreenshotEntry>> build() async {
    final ScreenshotRepository repo = ref.watch(screenshotRepositoryProvider);
    listenDebounced(
      ref,
      repo.watchChanges(),
      () => state = AsyncData(repo.sortedEntries()),
    );
    return repo.sortedEntries();
  }
}

class _NoCategoryNames extends CategoryNamesNotifier {
  @override
  Map<int, String> build() => {};
}

/// Görünen kaydın bilgi paneli (panel kimliği kayıt kimliğidir).
Finder _panelFor(String id) => find.byWidgetPredicate(
  (widget) => widget is ViewerInfoPanel && widget.key == ValueKey<String>(id),
);

void main() {
  testWidgets('panel görünen kaydı izler, silinen kaydın yerine sıradaki', (
    tester,
  ) async {
    final _FakeRepository repo = _FakeRepository(['a', 'b', 'c']);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          screenshotRepositoryProvider.overrideWithValue(repo),
          galleryProvider.overrideWith(_FakeGallery.new),
          categoryNamesProvider.overrideWith(_NoCategoryNames.new),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DetailScreen(assetId: 'a', scope: ['a', 'b', 'c']),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ViewerInfoPanel), findsNothing);

    await tester.tap(find.byIcon(AppIcons.info));
    await tester.pumpAndSettle();
    expect(find.byIcon(AppIcons.infoFill), findsOneWidget);
    expect(_panelFor('a'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1500);
    await tester.pumpAndSettle();
    expect(_panelFor('b'), findsOneWidget);

    final AppLocalizations l10n = AppLocalizations.of(
      tester.element(find.byType(ViewerInfoPanel)),
    );
    final ScreenshotCategory moved = ScreenshotCategory.values.last;
    expect(find.text(moved.displayName(l10n, const {})), findsNothing);
    repo.mutate('b', (entry) => entry.category = moved);
    await tester.pump(StorageTimings.reloadDebounce);
    await tester.pumpAndSettle();
    expect(find.text(moved.displayName(l10n, const {})), findsOneWidget);

    repo.remove('b');
    await tester.pump(StorageTimings.reloadDebounce);
    await tester.pumpAndSettle();
    expect(_panelFor('c'), findsOneWidget);
    expect(find.byIcon(AppIcons.infoFill), findsOneWidget);
  });
}

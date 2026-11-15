// Seçim modundaki ızgara: dokunuş seçimi değiştirir, seçim değişince yalnız
// üyeliği değişen karo yeniden kurulur.
import 'package:ai_gallery_organizer/core/models/screenshot_entry.dart';
import 'package:ai_gallery_organizer/core/theme/app_theme.dart';
import 'package:ai_gallery_organizer/features/gallery/data/screenshot_repository.dart';
import 'package:ai_gallery_organizer/features/gallery/widgets/screenshot_grid.dart';
import 'package:ai_gallery_organizer/features/gallery/widgets/screenshot_grid_tile.dart';
import 'package:ai_gallery_organizer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';

/// Görselleri yüklenmemiş depo; ızgara yalnız [ScreenshotRepository.assetFor]
/// çağırır.
class _NoAssets implements ScreenshotRepository {
  @override
  AssetEntity? assetFor(String assetId) => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ScreenshotGridTile _tile(WidgetTester tester, String id) =>
    tester.widget<ScreenshotGridTile>(
      find.byWidgetPredicate(
        (widget) => widget is ScreenshotGridTile && widget.entry.assetId == id,
      ),
    );

void main() {
  testWidgets('dokunulan karo seçilir, diğer karo yeniden kurulmaz', (
    tester,
  ) async {
    final List<ScreenshotEntry> entries = [
      for (final String id in ['a', 'b'])
        ScreenshotEntry(assetId: id, createdAt: DateTime(2026)),
    ];
    final ValueNotifier<Set<String>> selection = ValueNotifier(const {});
    addTearDown(selection.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          screenshotRepositoryProvider.overrideWithValue(_NoAssets()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CustomScrollView(
            slivers: [
              ScreenshotGrid(
                entries: entries,
                selection: selection,
                onToggle: (id) => selection.value = {...selection.value, id},
              ),
            ],
          ),
        ),
      ),
    );
    final ScreenshotGridTile untouched = _tile(tester, 'b');
    expect(_tile(tester, 'a').selected, isFalse);

    await tester.tap(find.byType(ScreenshotGridTile).first);
    await tester.pumpAndSettle();

    expect(selection.value, {'a'});
    expect(_tile(tester, 'a').selected, isTrue);
    expect(identical(_tile(tester, 'b'), untouched), isTrue);
  });
}

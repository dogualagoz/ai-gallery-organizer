// Ara sekmesi: Pro kilidi, boş sorguda öneriler, etiket önerisiyle arama
// (geçmişe yazılır), etkin aramada yazma ve "İptal" ile sıfırlama.
import 'dart:io';

import 'package:ai_gallery_organizer/core/models/hive/hive_registrar.g.dart';
import 'package:ai_gallery_organizer/core/models/screenshot_category.dart';
import 'package:ai_gallery_organizer/core/models/screenshot_entry.dart';
import 'package:ai_gallery_organizer/core/services/category_names_service.dart';
import 'package:ai_gallery_organizer/core/services/category_order_service.dart';
import 'package:ai_gallery_organizer/core/services/preferences_service.dart';
import 'package:ai_gallery_organizer/core/services/recent_searches_service.dart';
import 'package:ai_gallery_organizer/core/theme/app_theme.dart';
import 'package:ai_gallery_organizer/features/gallery/data/screenshot_repository.dart';
import 'package:ai_gallery_organizer/features/gallery/providers/gallery_provider.dart';
import 'package:ai_gallery_organizer/features/search/search_screen.dart';
import 'package:ai_gallery_organizer/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

final List<ScreenshotEntry> _entries = [
  ScreenshotEntry(
    assetId: 'concert',
    createdAt: DateTime(2026),
    analyzedAt: DateTime(2026),
    category: ScreenshotCategory.tickets,
    aiCategory: ScreenshotCategory.tickets,
    tags: ['concert'],
  ),
  ScreenshotEntry(
    assetId: 'receipt',
    createdAt: DateTime(2026),
    analyzedAt: DateTime(2026),
    category: ScreenshotCategory.receipts,
    aiCategory: ScreenshotCategory.receipts,
    tags: ['market'],
    ocrText: 'TOTAL 12.40',
  ),
];

/// Galeriyi diske/foto kütüphanesine gitmeden sabit listeyle verir.
class _FakeGallery extends GalleryNotifier {
  @override
  Future<List<ScreenshotEntry>> build() async => _entries;
}

/// Kategori adları ve sırası Hive yerine varsayılandan gelir.
class _FakeNames extends CategoryNamesNotifier {
  @override
  Map<int, String> build() => const {};
}

class _FakeOrder extends CategoryOrderNotifier {
  @override
  List<int> build() => [
    for (final ScreenshotCategory category in ScreenshotCategory.values)
      category.index,
  ];
}

void main() {
  late Directory dir;
  late ScreenshotRepository repo;

  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('search_screen_test');
    Hive
      ..init(dir.path)
      ..registerAdapters();
    repo = ScreenshotRepository(
      await Hive.openBox<ScreenshotEntry>('screenshots'),
      onCorrection: (from, to, tags) async {},
    );
  });

  tearDownAll(() async {
    await Hive.close();
    dir.deleteSync(recursive: true);
  });

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    required bool pro,
  }) async {
    SharedPreferences.setMockInitialValues({
      PrefKeys.aiWeekStart: DateTime.now().millisecondsSinceEpoch,
      PrefKeys.isPro: pro,
      PrefKeys.recentSearches: ['total'],
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          screenshotRepositoryProvider.overrideWithValue(repo),
          galleryProvider.overrideWith(_FakeGallery.new),
          categoryNamesProvider.overrideWith(_FakeNames.new),
          categoryOrderProvider.overrideWith(_FakeOrder.new),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SearchScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(tester.element(find.byType(SearchScreen)));
  }

  testWidgets('free kullanıcı kilit ve tek CTA görür, arama alanı yok', (
    tester,
  ) async {
    await pump(tester, pro: false);
    expect(find.text('Search is a Pro feature'), findsOneWidget);
    expect(find.text('Go Pro'), findsOneWidget);
    expect(find.byType(CupertinoSearchTextField), findsNothing);
  });

  testWidgets('boş sorguda son aramalar, sık etiketler ve kategoriler', (
    tester,
  ) async {
    await pump(tester, pro: true);
    expect(find.text('Recent Searches'), findsOneWidget);
    expect(find.text('total'), findsOneWidget);
    expect(find.text('Frequent Tags'), findsOneWidget);
    expect(find.text('Tickets'), findsOneWidget);
    expect(find.text('Receipts'), findsOneWidget);
  });

  testWidgets('etiket önerisi aranır ve geçmişin başına yazılır', (
    tester,
  ) async {
    final ProviderContainer container = await pump(tester, pro: true);
    await tester.tap(find.text('concert'));
    await tester.pumpAndSettle();
    expect(find.text('1 result'), findsOneWidget);
    expect(container.read(recentSearchesProvider), ['concert', 'total']);
  });

  testWidgets('etkin aramada yazılır, İptal aramayı sıfırlar', (tester) async {
    await pump(tester, pro: true);
    // Etkin değilken alan dokunuşu yutulur ve yalnız aramayı etkinleştirir.
    await tester.tap(
      find.byType(CupertinoSearchTextField),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(CupertinoSearchTextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No Results'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Recent Searches'), findsOneWidget);
    expect(find.text('zzz'), findsNothing);
  });
}

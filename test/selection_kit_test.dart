// Seçim modu parçaları (sekme çubuğu gizleme, yaylı görünürlük, araç çubuğu),
// ortak menüler ve ızgara karosu davranış testleri.
import 'package:ai_gallery_organizer/core/constants/app_icons.dart';
import 'package:ai_gallery_organizer/core/router/tab_bar_visibility.dart';
import 'package:ai_gallery_organizer/core/theme/app_theme.dart';
import 'package:ai_gallery_organizer/core/widgets/app_menus.dart';
import 'package:ai_gallery_organizer/core/widgets/pressable.dart';
import 'package:ai_gallery_organizer/core/widgets/selection_toolbar.dart';
import 'package:ai_gallery_organizer/core/widgets/spring_visibility.dart';
import 'package:ai_gallery_organizer/core/models/screenshot_entry.dart';
import 'package:ai_gallery_organizer/features/gallery/widgets/screenshot_grid_tile.dart';
import 'package:ai_gallery_organizer/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testlerin ortak kabuğu: tema + l10n (İngilizce) + tek gövde.
Widget _app(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

ScreenshotEntry _entry({bool pending = false}) => ScreenshotEntry(
  assetId: 'a1',
  createdAt: DateTime(2026),
  analyzedAt: pending ? null : DateTime(2026),
);

void main() {
  group('TabBarHiddenNotifier', () {
    test('son sahip bırakana dek çubuk gizli kalır', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      final TabBarHiddenNotifier notifier = container.read(
        tabBarHiddenProvider.notifier,
      );
      final Object first = Object();
      final Object second = Object();

      notifier.hide(first);
      notifier.hide(second);
      notifier.release(first);
      expect(container.read(tabBarHiddenProvider), isTrue);

      notifier.release(second);
      expect(container.read(tabBarHiddenProvider), isFalse);
    });

    test('hiç gizlemeyen sahibin bırakması etkisizdir', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      final TabBarHiddenNotifier notifier = container.read(
        tabBarHiddenProvider.notifier,
      );
      final Object owner = Object();

      notifier.hide(owner);
      notifier.release(Object());
      expect(container.read(tabBarHiddenProvider), isTrue);
    });
  });

  group('SpringVisibility', () {
    testWidgets('gizliyken dokunuş almaz, görünürken alır', (tester) async {
      int taps = 0;
      Widget build(bool visible) => _app(
        SpringVisibility(
          visible: visible,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => taps++,
            child: const SizedBox(width: 100, height: 60),
          ),
        ),
      );

      await tester.pumpWidget(build(false));
      await tester.tap(find.byType(SizedBox).last, warnIfMissed: false);
      expect(taps, 0);

      await tester.pumpWidget(build(true));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SizedBox).last);
      expect(taps, 1);
    });
  });

  group('SelectionToolbar', () {
    testWidgets('pasif eylem çalışmaz; meşgulken eylemler kilitlenir', (
      tester,
    ) async {
      int shares = 0;
      Widget build({required bool busy, VoidCallback? onShare}) => _app(
        SizedBox(
          width: 360,
          child: SelectionToolbar(
            status: '2 selected',
            busy: busy,
            leading: [
              ToolbarAction(
                icon: AppIcons.share,
                label: 'Share',
                onPressed: onShare,
              ),
            ],
            trailing: const [],
          ),
        ),
      );

      await tester.pumpWidget(build(busy: false));
      await tester.tap(find.byIcon(AppIcons.share));
      expect(shares, 0);

      await tester.pumpWidget(build(busy: false, onShare: () => shares++));
      await tester.tap(find.byIcon(AppIcons.share));
      expect(shares, 1);
      expect(find.text('2 selected'), findsOneWidget);

      await tester.pumpWidget(build(busy: true, onShare: () => shares++));
      await tester.tap(find.byIcon(AppIcons.share));
      expect(shares, 1);
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    });
  });

  group('AppContextMenu', () {
    testWidgets('kısa dokunuş çocuğun eylemini çalıştırır', (tester) async {
      int taps = 0;
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 120,
            height: 200,
            child: AppContextMenu(
              actions: [
                AppMenuAction(
                  label: 'Share',
                  icon: AppIcons.share,
                  onPressed: () {},
                ),
              ],
              child: Pressable(
                onPressed: () => taps++,
                child: const ColoredBox(color: Color(0xFF888888)),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Pressable));
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(find.text('Share'), findsNothing);
    });

    testWidgets('uzun basış menüyü açar, eylem menüyü kapatıp çalışır', (
      tester,
    ) async {
      int shares = 0;
      int taps = 0;
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 120,
            height: 200,
            child: AppContextMenu(
              actions: [
                AppMenuAction(
                  label: 'Share',
                  icon: AppIcons.share,
                  onPressed: () => shares++,
                ),
              ],
              child: Pressable(
                onPressed: () => taps++,
                child: const ColoredBox(color: Color(0xFF888888)),
              ),
            ),
          ),
        ),
      );

      // Menü, basılı tutma animasyonu bitene dek parmak kalkmadan açılır.
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(Pressable)),
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Share'), findsOneWidget);
      expect(taps, 0);

      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(shares, 1);
      expect(find.text('Share'), findsNothing);
    });
  });

  group('AppMoreMenuButton', () {
    testWidgets('dokununca açılır, öğe eylemini çalıştırır', (tester) async {
      final List<String> calls = [];
      await tester.pumpWidget(
        _app(
          AppMoreMenuButton(
            label: 'More',
            actions: [
              AppMenuAction(
                label: 'Rename',
                icon: AppIcons.edit,
                onPressed: () => calls.add('rename'),
              ),
              AppMenuAction(
                label: 'Delete',
                icon: AppIcons.delete,
                destructive: true,
                onPressed: () => calls.add('delete'),
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('More'));
      await tester.pumpAndSettle();
      expect(find.text('Rename'), findsOneWidget);
      expect(find.byType(CupertinoMenuDivider), findsOneWidget);

      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      expect(calls, ['rename']);
      expect(find.text('Rename'), findsNothing);
    });
  });

  group('ScreenshotGridTile', () {
    Widget tile({bool? selected, bool pending = false}) => _app(
      SizedBox(
        width: 120,
        height: 213,
        child: ScreenshotGridTile(
          entry: _entry(pending: pending),
          asset: null,
          selected: selected,
          onPressed: () {},
        ),
      ),
    );

    testWidgets('seçim modu dışında işaret yok; seçiliyse tik görünür', (
      tester,
    ) async {
      await tester.pumpWidget(tile());
      expect(find.byIcon(AppIcons.check), findsNothing);

      await tester.pumpWidget(tile(selected: false));
      expect(find.byIcon(AppIcons.check), findsNothing);

      await tester.pumpWidget(tile(selected: true));
      expect(find.byIcon(AppIcons.check), findsOneWidget);
    });

    testWidgets('analiz bekleyen karoda nokta görünür', (tester) async {
      await tester.pumpWidget(tile());
      expect(find.byType(PendingDot), findsNothing);

      await tester.pumpWidget(tile(pending: true));
      expect(find.byType(PendingDot), findsOneWidget);
    });
  });
}

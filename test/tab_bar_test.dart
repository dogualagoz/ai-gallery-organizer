// Sekme pili (dokunma, sürükleme, momentum projeksiyonu) ve rota yolu testleri.
import 'package:ai_gallery_organizer/core/models/screenshot_category.dart';
import 'package:ai_gallery_organizer/core/router/app_router.dart';
import 'package:ai_gallery_organizer/core/theme/app_theme.dart';
import 'package:ai_gallery_organizer/core/widgets/glass_nav_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const double _barWidth = 300;

/// İki sekmeli pil; seçimler [calls]'a yazılır ve seçili sekme güncellenir.
Widget _bar(List<int> calls, {int initial = 0}) {
  int selected = initial;
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: _barWidth,
          child: StatefulBuilder(
            builder: (context, setState) => GlassNavBar(
              selectedIndex: selected,
              onSelected: (index) {
                calls.add(index);
                setState(() => selected = index);
              },
              destinations: const [
                GlassNavDestination(
                  icon: CupertinoIcons.photo,
                  selectedIcon: CupertinoIcons.photo_fill,
                  label: 'Library',
                ),
                GlassNavDestination(
                  icon: CupertinoIcons.hand_draw,
                  selectedIcon: CupertinoIcons.hand_draw_fill,
                  label: 'Clean',
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('GlassNavBar', () {
    testWidgets('sekmeye dokunmak onu seçer', (tester) async {
      final List<int> calls = [];
      await tester.pumpWidget(_bar(calls));
      await tester.tap(find.text('Clean'));
      await tester.pumpAndSettle();
      expect(calls, [1]);
    });

    testWidgets('yarıyı geçen yavaş sürükleme sonraki sekmeyi seçer', (
      tester,
    ) async {
      final List<int> calls = [];
      await tester.pumpWidget(_bar(calls));
      await tester.timedDrag(
        find.text('Library'),
        const Offset(_barWidth / 2, 0),
        const Duration(seconds: 1),
      );
      await tester.pumpAndSettle();
      // Tap tanıyıcı kaybeder: yalnız sürüklemenin seçimi kayda geçer.
      expect(calls, [1]);
    });

    testWidgets('kısa yavaş sürükleme seçimi değiştirmez', (tester) async {
      final List<int> calls = [];
      await tester.pumpWidget(_bar(calls));
      await tester.timedDrag(
        find.text('Library'),
        const Offset(_barWidth / 5, 0),
        const Duration(seconds: 1),
      );
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
    });

    testWidgets('kısa ama hızlı fiske momentumla sekmeyi değiştirir', (
      tester,
    ) async {
      final List<int> calls = [];
      await tester.pumpWidget(_bar(calls));
      await tester.timedDrag(
        find.text('Library'),
        const Offset(_barWidth / 5, 0),
        const Duration(milliseconds: 50),
      );
      await tester.pumpAndSettle();
      expect(calls, [1]);
    });

    testWidgets('pil dışı sekme seçiliyken gösterge gizlenir', (tester) async {
      await tester.pumpWidget(_bar([], initial: 2));
      final AnimatedOpacity indicator = tester.widget<AnimatedOpacity>(
        find.descendant(
          of: find.byType(GlassNavBar),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(indicator.opacity, 0);
    });
  });

  group('AppRoutes', () {
    test('kategori ve pano yolları Kütüphane dalının altındadır', () {
      final ScreenshotCategory category = ScreenshotCategory.values[2];
      expect(AppRoutes.category(category), '/library/category/2');
      expect(
        AppRoutes.category(category, select: true),
        '/library/category/2?select=1',
      );
    });

    test('slash içeren kimlikler tek segment olarak encode edilir', () {
      expect(AppRoutes.board('a/b'), '/library/board/a%2Fb');
      expect(AppRoutes.detail('X/L0/001'), '/detail/X%2FL0%2F001');
    });
  });
}

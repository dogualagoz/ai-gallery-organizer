// Düzenleme modu ızgarası: basılı tutup sürükleyerek sıralama, bırakınca
// doğru index çifti ve düzenleme kapalıyken sürüklemenin çalışmaması;
// erişilebilirlik yazı boyutlarında tek sütun; sürükleme yalnız sıra
// değişince karoları yeniden kurar; ızgara geometrisinin saf hesapları.
import 'package:ai_gallery_organizer/core/constants/motion_constants.dart';
import 'package:ai_gallery_organizer/core/constants/ui_constants.dart';
import 'package:ai_gallery_organizer/core/theme/app_theme.dart';
import 'package:ai_gallery_organizer/core/widgets/reorder_grid_layout.dart';
import 'package:ai_gallery_organizer/core/widgets/reorderable_tile_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const double _gridWidth = 300;

Widget _grid({
  required bool editing,
  required void Function(int from, int to) onReorder,
  double textScale = 1,
  VoidCallback? onTileBuilt,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: _gridWidth,
          child: ReorderableTileGrid(
            itemCount: 4,
            editing: editing,
            keyBuilder: (index) => ValueKey<int>(index),
            onReorder: onReorder,
            itemBuilder: (context, index) {
              onTileBuilt?.call();
              return ColoredBox(color: Colors.grey, child: Text('tile$index'));
            },
          ),
        ),
      ),
    ),
  );
}

/// Karoyu basılı tutup [to] karosunun merkezine taşır ve bırakır.
Future<void> _liftAndDrop(WidgetTester tester, String from, String to) async {
  final Offset start = tester.getCenter(find.text(from));
  final Offset end = tester.getCenter(find.text(to));
  final TestGesture gesture = await tester.startGesture(start);
  await tester.pump(AppMotion.liftDelay + const Duration(milliseconds: 50));
  // Birkaç adımda taşı: önizleme sırası ara konumlarda da güncellenir.
  const int steps = 5;
  for (int i = 1; i <= steps; i++) {
    await gesture.moveTo(Offset.lerp(start, end, i / steps)!);
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  // Düzenleme modunda titreşim sürekli döner: settle yerine yayların
  // oturmasına yetecek sabit süre beklenir.
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('düzenleme modunda karo sürüklenip bırakılınca sıralanır', (
    tester,
  ) async {
    final List<(int, int)> moves = [];
    await tester.pumpWidget(
      _grid(editing: true, onReorder: (from, to) => moves.add((from, to))),
    );

    await _liftAndDrop(tester, 'tile0', 'tile3');

    expect(moves, [(0, 3)]);
  });

  testWidgets('düzenleme kapalıyken uzun basış sıralamaz', (tester) async {
    final List<(int, int)> moves = [];
    await tester.pumpWidget(
      _grid(editing: false, onReorder: (from, to) => moves.add((from, to))),
    );

    await _liftAndDrop(tester, 'tile0', 'tile3');

    expect(moves, isEmpty);
  });

  testWidgets('erişilebilirlik yazı boyutunda karolar tek sütuna dizilir', (
    tester,
  ) async {
    final List<(int, int)> moves = [];
    await tester.pumpWidget(
      _grid(
        editing: true,
        textScale: AppSizes.accessibilityTextScale,
        onReorder: (from, to) => moves.add((from, to)),
      ),
    );

    // Konum karonun içinden okunur: yuva kutusu dönüşümü çocuğa uygular.
    Rect tile(String label) => tester.getRect(
      find
          .ancestor(of: find.text(label), matching: find.byType(ColoredBox))
          .first,
    );
    final Rect first = tile('tile0');
    final Rect second = tile('tile1');
    expect(first.width, moreOrLessEquals(_gridWidth));
    expect(second.top, greaterThan(first.bottom));

    // Tek sütunda sıralama da konuma göre çalışır.
    await _liftAndDrop(tester, 'tile0', 'tile2');
    expect(moves, [(0, 2)]);
  });

  testWidgets('aynı yuvada sürüklemek karoları yeniden kurmaz', (tester) async {
    int builds = 0;
    await tester.pumpWidget(
      _grid(editing: true, onReorder: (_, _) {}, onTileBuilt: () => builds++),
    );
    final Offset start = tester.getCenter(find.text('tile0'));
    final TestGesture gesture = await tester.startGesture(start);
    await tester.pump(AppMotion.liftDelay + const Duration(milliseconds: 50));
    final int afterLift = builds;

    // Karo yarım hücre bile kaymadan izlenir: önizleme sırası değişmez.
    for (int i = 1; i <= 5; i++) {
      await gesture.moveTo(start + Offset(i * 4, i * 4));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(builds, afterLift);
    Rect tile(String label) => tester.getRect(
      find
          .ancestor(of: find.text(label), matching: find.byType(ColoredBox))
          .first,
    );
    final Rect moved = tile('tile0');
    final Rect neighbour = tile('tile1');
    // Kalkık karo parmakla birlikte kaydı, komşu yerinde.
    expect(moved.center.dx, greaterThan(start.dx));
    expect(neighbour.left, greaterThan(moved.left));

    await gesture.up();
    await tester.pump(const Duration(seconds: 1));
  });

  group('ReorderGridLayout', () {
    const ReorderGridLayout layout = ReorderGridLayout(
      columns: 2,
      cell: Size(100, 50),
      spacing: 10,
    );

    test('konumun köşesi satır ve sütundan hesaplanır', () {
      expect(layout.originOf(0), Offset.zero);
      expect(layout.originOf(1), const Offset(110, 0));
      expect(layout.originOf(3), const Offset(110, 60));
    });

    test('nokta en yakın sıralanabilir hücreye düşer', () {
      expect(layout.slotAt(const Offset(150, 70), itemCount: 4), 3);
      // Izgara dışı noktalar kenara sıkıştırılır.
      expect(layout.slotAt(const Offset(-20, -20), itemCount: 4), 0);
      expect(layout.slotAt(const Offset(500, 500), itemCount: 4), 3);
      // Son satır yarım: boş hücre son karoya düşer.
      expect(layout.slotAt(const Offset(150, 70), itemCount: 3), 2);
    });

    test('yükseklik satır sayısından ve aralıktan çıkar', () {
      expect(layout.extentFor(0), 0);
      expect(layout.extentFor(1), 50);
      expect(layout.extentFor(3), 110);
    });
  });
}

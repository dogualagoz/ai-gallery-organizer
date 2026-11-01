// Düzenleme modu ızgarası: basılı tutup sürükleyerek sıralama, bırakınca
// doğru index çifti ve düzenleme kapalıyken sürüklemenin çalışmaması.
import 'package:ai_gallery_organizer/core/constants/motion_constants.dart';
import 'package:ai_gallery_organizer/core/theme/app_theme.dart';
import 'package:ai_gallery_organizer/core/widgets/reorderable_tile_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const double _gridWidth = 300;

Widget _grid({
  required bool editing,
  required void Function(int from, int to) onReorder,
}) {
  return MaterialApp(
    theme: AppTheme.light,
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
            itemBuilder: (context, index) =>
                ColoredBox(color: Colors.grey, child: Text('tile$index')),
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
}

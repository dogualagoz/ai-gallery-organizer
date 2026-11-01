// Analiz uçuşları: kart, karosu sonradan kurulsa ya da uçuş sırasında yer
// değiştirse de kendi kategorisine iner; karo hiç gelmezse sıra takılmaz.
import 'package:ai_gallery_organizer/core/constants/motion_constants.dart';
import 'package:ai_gallery_organizer/core/models/screenshot_category.dart';
import 'package:ai_gallery_organizer/features/analysis/widgets/analysis_flights.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const ScreenshotCategory _category = ScreenshotCategory.shopping;
const Size _tileSize = Size(80, 80);
const Duration _frame = Duration(milliseconds: 16);

/// Kalkış kutusu üstte; karo [tile] konumunda (null ise henüz kurulmamış).
Future<AnalysisFlights> _pump(
  WidgetTester tester,
  ValueNotifier<Offset?> tile,
) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  late AnalysisFlights flights;
  await tester.pumpWidget(
    MaterialApp(
      home: AnalysisFlightScope(
        child: Builder(
          builder: (context) {
            flights = AnalysisFlightScope.of(context)!;
            return ValueListenableBuilder<Offset?>(
              valueListenable: tile,
              builder: (context, origin, _) => Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 100,
                    width: 390,
                    height: 80,
                    child: SizedBox(key: flights.sourceKey),
                  ),
                  if (origin != null)
                    Positioned(
                      left: origin.dx,
                      top: origin.dy,
                      width: _tileSize.width,
                      height: _tileSize.height,
                      child: SizedBox(key: flights.targetKeyFor(_category)),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
  return flights;
}

/// Uçan kart (asset yok: düz dolgulu kırpılmış kutu).
final Finder _card = find.byType(ClipRRect);

/// Kartın bir karedeki merkezi ve opaklığı.
typedef _Sample = ({Offset center, double opacity});

_Sample _sample(WidgetTester tester) => (
  center: tester.getCenter(_card),
  opacity: tester
      .widget<Opacity>(
        find.ancestor(of: _card, matching: find.byType(Opacity)).first,
      )
      .opacity,
);

/// Kart inene kadar kareleri ilerletir; her karedeki durumunu döndürür.
Future<List<_Sample>> _flyToLanding(WidgetTester tester) async {
  final List<_Sample> path = [];
  for (int i = 0; i < 200; i++) {
    await tester.pump(_frame);
    if (_card.evaluate().isEmpty) {
      if (path.isNotEmpty) return path;
      continue;
    }
    path.add(_sample(tester));
  }
  fail('Kart inmedi');
}

Offset _centerOf(Offset origin) => origin + _tileSize.center(Offset.zero);

/// Karosu olmayan kartın indiği yer: ekranın altı eksi kartın yarısı.
const double _floorY = 844 - 32;

void main() {
  testWidgets('karo sonradan kurulursa kart bekler, sonra karosuna iner', (
    tester,
  ) async {
    final ValueNotifier<Offset?> tile = ValueNotifier(null);
    addTearDown(tile.dispose);
    final AnalysisFlights flights = await _pump(tester, tile);

    flights.enqueue([(asset: null, category: _category)]);
    // Galeri yenilenene kadar karo yok: kart boşluğa kalkmaz.
    for (int i = 0; i < 5; i++) {
      await tester.pump(_frame);
      expect(_card, findsNothing);
    }
    expect(flights.nextFlight.value, isNotNull);

    const Offset origin = Offset(280, 500);
    tile.value = origin;
    final List<_Sample> path = await _flyToLanding(tester);
    expect((path.last.center - _centerOf(origin)).distance, lessThan(24));
    expect(flights.busy.value, isFalse);
  });

  testWidgets('karo uçuş sırasında kayarsa kart yeni yerine döner', (
    tester,
  ) async {
    const Offset before = Offset(280, 500);
    const Offset after = Offset(20, 650);
    final ValueNotifier<Offset?> tile = ValueNotifier(before);
    addTearDown(tile.dispose);
    final AnalysisFlights flights = await _pump(tester, tile);

    flights.enqueue([(asset: null, category: _category)]);
    // Kart eski karoya varıp solmaya başlamışken ızgara akar.
    final List<_Sample> path = [];
    for (int i = 0; i < 100 && (path.lastOrNull?.opacity ?? 1) >= 1; i++) {
      await tester.pump(_frame);
      if (_card.evaluate().isNotEmpty) path.add(_sample(tester));
    }
    expect(path.last.opacity, lessThan(1));
    tile.value = after;
    path.addAll(await _flyToLanding(tester));

    expect((path.last.center - _centerOf(after)).distance, lessThan(24));
    for (int i = 1; i < path.length; i++) {
      // Yön değişimi sıçramasız; solan kart yeniden belirmez.
      expect((path[i].center - path[i - 1].center).distance, lessThan(40));
      expect(path[i].opacity, lessThanOrEqualTo(path[i - 1].opacity));
    }
  });

  testWidgets('karo hiç gelmezse süre dolunca kart aşağı iner', (tester) async {
    final ValueNotifier<Offset?> tile = ValueNotifier(null);
    addTearDown(tile.dispose);
    final AnalysisFlights flights = await _pump(tester, tile);

    flights.enqueue([(asset: null, category: _category)]);
    await tester.pump();
    await tester.pump(AppFlight.targetGrace - _frame * 2);
    expect(_card, findsNothing);

    final List<_Sample> path = await _flyToLanding(tester);
    expect(path.last.center.dy, closeTo(_floorY, 30));
    await tester.pump(_frame);
    expect(flights.busy.value, isFalse);
    expect(flights.nextFlight.value, isNull);
  });

  testWidgets('karosu gelmeyen kategorinin sonraki öğesi yeniden beklemez', (
    tester,
  ) async {
    final ValueNotifier<Offset?> tile = ValueNotifier(null);
    addTearDown(tile.dispose);
    final AnalysisFlights flights = await _pump(tester, tile);

    flights.enqueue([
      (asset: null, category: _category),
      (asset: null, category: _category),
    ]);
    await tester.pump();
    await tester.pump(AppFlight.targetGrace);
    // İkincisi yalnız kalkış aralığı kadar arkadan gelir.
    for (int i = 0; i < 12; i++) {
      await tester.pump(_frame);
    }
    expect(_card, findsNWidgets(2));
  });

  testWidgets('beklerken temizlenirse sıra boşalır, kart kalkmaz', (
    tester,
  ) async {
    final ValueNotifier<Offset?> tile = ValueNotifier(null);
    addTearDown(tile.dispose);
    final AnalysisFlights flights = await _pump(tester, tile);

    flights.enqueue([(asset: null, category: _category)]);
    await tester.pump();
    await tester.pump(_frame);
    flights.clear();
    expect(flights.busy.value, isFalse);
    expect(flights.nextFlight.value, isNull);

    await tester.pump(AppFlight.targetGrace * 2);
    expect(_card, findsNothing);
  });
}

// Görüntüleyici davranış testleri: aşağı çekip kapatma ve bilgi paneli
// kararları, çift dokunuş yakınlaştırması, tam çözünürlük ölçüsü, arama isteği.
import 'package:ai_gallery_organizer/core/theme/app_theme.dart';
import 'package:ai_gallery_organizer/features/detail/viewer_motion.dart';
import 'package:ai_gallery_organizer/features/detail/widgets/photo_page.dart';
import 'package:ai_gallery_organizer/features/search/search_request_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';

/// Testlerde kullanılan ekran yüksekliği (panel = %55 → 440 px).
const double _height = 800;

DragEndDetails _release(double velocity) =>
    DragEndDetails(velocity: Velocity(pixelsPerSecond: Offset(0, velocity)));

/// [from]'dan [to]'ya tek adımlı sürükleme, [velocity] ile bırakılır.
void _drag(ViewerMotion motion, Offset from, Offset to, double velocity) {
  motion
    ..dragStart(DragStartDetails(globalPosition: from))
    ..dragUpdate(DragUpdateDetails(globalPosition: to), _height)
    ..dragEnd(_release(velocity), _height);
}

void main() {
  group('ViewerMotion', () {
    late int dismissed;
    late List<bool> infoChanges;
    late ViewerMotion motion;

    setUp(() {
      dismissed = 0;
      infoChanges = [];
      motion = ViewerMotion(
        vsync: const TestVSync(),
        onDismiss: () => dismissed++,
        onInfoChanged: infoChanges.add,
      );
    });

    tearDown(() => motion.dispose());

    testWidgets('sürükleme parmağı iki eksende izler', (tester) async {
      motion
        ..dragStart(DragStartDetails(globalPosition: const Offset(100, 300)))
        ..dragUpdate(
          DragUpdateDetails(globalPosition: const Offset(110, 360)),
          _height,
        );
      expect(motion.drag.value, const Offset(10, 60));
      expect(motion.dismissProgress(_height), greaterThan(0));
    });

    testWidgets('yavaş kısa çekiş kapatmaz, yerine yayla döner', (
      tester,
    ) async {
      _drag(motion, const Offset(100, 300), const Offset(110, 360), 100);
      await tester.pumpAndSettle();
      expect(dismissed, 0);
      expect(motion.drag.value, Offset.zero);
    });

    testWidgets('kısa ama hızlı fiske kapatır', (tester) async {
      _drag(motion, const Offset(100, 300), const Offset(100, 340), 1500);
      expect(dismissed, 1);
    });

    testWidgets('aşağı inip yukarı fırlatılan çekiş kapatmaz', (tester) async {
      _drag(motion, const Offset(100, 300), const Offset(100, 500), -2000);
      await tester.pumpAndSettle();
      expect(dismissed, 0);
    });

    testWidgets('yukarı fiske paneli açar, aşağı fiske kapatır', (
      tester,
    ) async {
      _drag(motion, const Offset(100, 500), const Offset(100, 440), -800);
      expect(motion.infoShown, isTrue);
      await tester.pumpAndSettle();
      expect(motion.info.value, closeTo(1, 0.01));

      // Açık panelde kısa, hızsız çekiş paneli açık bırakır.
      _drag(motion, const Offset(100, 200), const Offset(100, 300), 0);
      await tester.pumpAndSettle();
      expect(motion.infoShown, isTrue);
      expect(dismissed, 0);

      _drag(motion, const Offset(100, 200), const Offset(100, 250), 800);
      await tester.pumpAndSettle();
      expect(motion.infoShown, isFalse);
      expect(motion.info.value, closeTo(0, 0.01));
      expect(infoChanges, [true, false]);
    });
  });

  group('PhotoPage', () {
    testWidgets('çift dokunuş yakınlaştırır, tekrarı ve panel sığdırır', (
      tester,
    ) async {
      final List<bool> zooms = [];
      int taps = 0;
      Widget build({bool fit = false, bool current = true}) => MaterialApp(
        theme: AppTheme.light,
        home: PhotoPage(
          asset: null,
          heroTag: 'test',
          isCurrent: current,
          heroEnabled: false,
          fitRequested: fit,
          onTap: () => taps++,
          onZoomChanged: zooms.add,
        ),
      );
      Future<void> doubleTap() async {
        await tester.tap(find.byType(PhotoPage));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.byType(PhotoPage));
        await tester.pumpAndSettle();
      }

      await tester.pumpWidget(build());
      await doubleTap();
      expect(zooms, [true]);
      await doubleTap();
      expect(zooms, [true, false]);

      await doubleTap();
      await tester.pumpWidget(build(fit: true));
      await tester.pumpAndSettle();
      expect(zooms, [true, false, true, false]);

      // Kaydırılıp bırakılan sayfa yakınlaştırmasını bırakır: geri gelince
      // çift dokunuş yeniden yakınlaştırır (uzaklaştırmaz).
      await doubleTap();
      await tester.pumpWidget(build(current: false));
      await tester.pumpWidget(build());
      await doubleTap();
      expect(zooms, [true, false, true, false, true, true]);

      // Tek dokunuş, çift dokunuş süresi dolunca bildirilir.
      expect(taps, 0);
      await tester.tap(find.byType(PhotoPage));
      await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 50));
      expect(taps, 1);
    });
  });

  group('viewerFullSize', () {
    AssetEntity asset(int width, int height) =>
        AssetEntity(id: 'a', typeInt: 1, width: width, height: height);

    test('ekran görüntüsü kendi ölçüsünde istenir', () {
      expect(
        viewerFullSize(asset(1179, 2556)),
        const ThumbnailSize(1179, 2556),
      );
    });

    test('büyük görsel uzun kenardan sınırlanır, oran korunur', () {
      expect(
        viewerFullSize(asset(4000, 3000)),
        const ThumbnailSize(2880, 2160),
      );
    });

    test('ölçüsü bilinmeyen varlık için yedek ölçü', () {
      expect(viewerFullSize(asset(0, 0)), const ThumbnailSize(1080, 1920));
    });
  });

  test('aynı etiket art arda istense de yeni istek sayılır', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final SearchRequestNotifier notifier = container.read(
      searchRequestProvider.notifier,
    );

    notifier.request('fatura');
    final SearchRequest? first = container.read(searchRequestProvider);
    notifier.request('fatura');
    final SearchRequest? second = container.read(searchRequestProvider);

    expect(first?.query, 'fatura');
    expect(second?.query, 'fatura');
    expect(second?.serial, greaterThan(first!.serial));

    notifier.clear();
    expect(container.read(searchRequestProvider), isNull);
  });
}

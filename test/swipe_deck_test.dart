// Temizle destesi testleri: denetleyicinin kimlik kontrollü bağlantısı,
// sürükleyerek ve butonla gönderme, geri dönüş ve oturum sırası.
import 'package:ai_gallery_organizer/core/models/screenshot_category.dart';
import 'package:ai_gallery_organizer/core/models/screenshot_entry.dart';
import 'package:ai_gallery_organizer/core/theme/app_theme.dart';
import 'package:ai_gallery_organizer/features/sorting/providers/clean_session_provider.dart';
import 'package:ai_gallery_organizer/features/sorting/swipe_decision.dart';
import 'package:ai_gallery_organizer/features/sorting/widgets/swipe_deck.dart';
import 'package:ai_gallery_organizer/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Gönderilen kartlar ([id, yön]) buraya yazılır.
typedef _Swipes = List<(String, SwipeDirection)>;

Widget _deck(
  SwipeDeckController controller,
  _Swipes swipes, {
  Key? key,
  String top = 'a',
  String? next = 'b',
}) {
  return MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SwipeDeck(
        key: key,
        top: SwipeDeckItem(top, null),
        next: next == null ? null : SwipeDeckItem(next, null),
        controller: controller,
        onSwipe: (id, direction) => swipes.add((id, direction)),
        assignIcon: CupertinoIcons.star,
        assignLabel: 'Social',
      ),
    ),
  );
}

ScreenshotEntry _entry(
  String id, {
  bool pending = true,
  ScreenshotCategory? category,
  String? boardId,
}) {
  return ScreenshotEntry(
    assetId: id,
    createdAt: DateTime(2026),
    category: category,
    analyzedAt: pending ? null : DateTime(2026),
    boardId: boardId,
  );
}

void main() {
  group('SwipeDeckController', () {
    testWidgets('yeni deste eskisinin dispose\'undan sonra da bağlı kalır', (
      tester,
    ) async {
      final SwipeDeckController controller = SwipeDeckController();
      final _Swipes swipes = [];
      await tester.pumpWidget(
        _deck(controller, swipes, key: const ValueKey('first')),
      );
      // Anahtar değişince yeni deste önce bağlanır, eskisi sonra çözülür.
      await tester.pumpWidget(
        _deck(controller, swipes, key: const ValueKey('second')),
      );
      expect(controller.isAttached, isTrue);
      controller.swipe(SwipeDirection.left);
      expect(swipes, [('a', SwipeDirection.left)]);
      await tester.pumpAndSettle();
    });

    testWidgets('deste kalkınca bağlantı çözülür', (tester) async {
      final SwipeDeckController controller = SwipeDeckController();
      await tester.pumpWidget(_deck(controller, []));
      await tester.pumpWidget(const SizedBox.shrink());
      expect(controller.isAttached, isFalse);
    });
  });

  group('SwipeDeck', () {
    testWidgets('eşiği geçen sürükleme kartı gönderir', (tester) async {
      final _Swipes swipes = [];
      await tester.pumpWidget(_deck(SwipeDeckController(), swipes));
      await tester.drag(
        find.byType(SwipeDeck),
        const Offset(-200, 0),
        warnIfMissed: false,
      );
      expect(swipes, [('a', SwipeDirection.left)]);
      await tester.pumpAndSettle();
    });

    testWidgets('kısa sürükleme göndermez, kart yerine döner', (tester) async {
      final _Swipes swipes = [];
      await tester.pumpWidget(_deck(SwipeDeckController(), swipes));
      final Offset rest = tester.getCenter(find.byType(GestureDetector).last);
      final TestGesture gesture = await tester.startGesture(rest);
      await gesture.moveBy(const Offset(0, -40));
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(swipes, isEmpty);
      expect(tester.getCenter(find.byType(GestureDetector).last), rest);
    });

    testWidgets('aynı kart butonla iki kez gönderilemez', (tester) async {
      final SwipeDeckController controller = SwipeDeckController();
      final _Swipes swipes = [];
      await tester.pumpWidget(_deck(controller, swipes));
      controller
        ..swipe(SwipeDirection.up)
        ..swipe(SwipeDirection.up);
      expect(swipes, [('a', SwipeDirection.up)]);
      await tester.pumpAndSettle();
    });
  });

  group('CleanSession.queue', () {
    test(
      'panoda olanlar, analiz edilmiş kategorililer ve ele alınanlar düşer',
      () {
        final List<ScreenshotEntry> entries = [
          _entry('pending'),
          _entry('other', pending: false, category: ScreenshotCategory.other),
          _entry('sorted', pending: false, category: ScreenshotCategory.social),
          _entry('boarded', boardId: 'b1'),
          _entry('skipped'),
          _entry('deleting'),
          _entry('assigned'),
        ];
        const CleanSession session = CleanSession(
          skipped: {'skipped'},
          pendingDeletes: {'deleting'},
          assigned: {'assigned'},
        );
        expect(session.queue(entries).map((entry) => entry.assetId), [
          'pending',
          'other',
        ]);
      },
    );

    test('geri alınan kart deste başına gelir', () {
      final List<ScreenshotEntry> entries = [
        _entry('a'),
        _entry('b'),
        _entry('c'),
      ];
      const CleanSession session = CleanSession(front: 'c');
      expect(session.queue(entries).map((entry) => entry.assetId), [
        'c',
        'a',
        'b',
      ]);
    });
  });
}

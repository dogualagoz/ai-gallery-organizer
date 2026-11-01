// Temizle destesinin saf jest mantığı testleri: yön, ilerleme, bırakış
// kararı (projeksiyon + vazgeçiş), eşik histerezisi, dönüş ve çıkış yolu.
import 'dart:ui';

import 'package:ai_gallery_organizer/core/constants/motion_constants.dart';
import 'package:ai_gallery_organizer/features/sorting/swipe_decision.dart';
import 'package:flutter_test/flutter_test.dart';

const Size _screen = Size(400, 800);
const double _t = AppSwipe.threshold;

void main() {
  group('directionOf', () {
    test('baskın eksen yönü belirler', () {
      expect(directionOf(const Offset(-50, -10)), SwipeDirection.left);
      expect(directionOf(const Offset(50, -10)), SwipeDirection.right);
      expect(directionOf(const Offset(10, -50)), SwipeDirection.up);
    });

    test('aşağı hareketin yönü yoktur', () {
      expect(directionOf(Offset.zero), isNull);
      expect(directionOf(const Offset(0, 80)), isNull);
    });
  });

  test('ilerleme eşikte 1 ile sınırlanır', () {
    expect(swipeProgress(Offset.zero), 0);
    expect(swipeProgress(const Offset(-_t / 2, 0)), closeTo(0.5, 1e-9));
    expect(swipeProgress(const Offset(0, -_t * 3)), 1);
  });

  group('decideSwipe', () {
    test('eşiği geçen yavaş bırakış gider', () {
      expect(
        decideSwipe(const Offset(-_t - 10, 0), Offset.zero),
        SwipeDirection.left,
      );
      expect(
        decideSwipe(const Offset(5, -_t - 10), Offset.zero),
        SwipeDirection.up,
      );
    });

    test('eşiğe varmayan yavaş bırakış geri döner', () {
      expect(decideSwipe(const Offset(_t - 10, 0), Offset.zero), isNull);
    });

    test('kısa ama hızlı fiske projeksiyonla gider', () {
      expect(
        decideSwipe(const Offset(30, 0), const Offset(1500, 0)),
        SwipeDirection.right,
      );
    });

    test('eşik geçilmiş olsa da geri çekilen kart gitmez', () {
      expect(
        decideSwipe(const Offset(-_t - 60, 0), const Offset(400, 0)),
        isNull,
      );
    });

    test('aşağı fırlatma hiçbir şey yapmaz', () {
      expect(decideSwipe(const Offset(0, 80), const Offset(0, 2000)), isNull);
    });
  });

  test('eşik haptiği histerezisle titremez', () {
    final SwipeDirection? armed = armedDirection(const Offset(-_t, 0), null);
    expect(armed, SwipeDirection.left);
    // Eşiğin hemen gerisi: hâlâ eşikte sayılır.
    final Offset justBelow = Offset(-_t + AppSwipe.armHysteresis / 2, 0);
    expect(armedDirection(justBelow, armed), SwipeDirection.left);
    // Daha önce eşikte değilse aynı nokta eşik sayılmaz.
    expect(armedDirection(justBelow, null), isNull);
    // Payın gerisine dönünce çıkar.
    final Offset clear = Offset(-_t + AppSwipe.armHysteresis * 2, 0);
    expect(armedDirection(clear, armed), isNull);
  });

  group('swipeRotation', () {
    test(
      'üstten tutulan kart gittiği yöne, alttan tutulan ters yöne döner',
      () {
        expect(swipeRotation(100, 300, 0), greaterThan(0));
        expect(swipeRotation(100, 300, 1), lessThan(0));
        expect(swipeRotation(-100, 300, 0), lessThan(0));
      },
    );

    test('ortadan tutulan kart dönmez', () {
      expect(swipeRotation(100, 300, 0.5), 0);
    });
  });

  test('gidiş hızı en az asgari hız, hızlı fırlatma korunur', () {
    expect(
      throwVelocity(SwipeDirection.left, Offset.zero).dx,
      -AppSwipe.minThrowSpeed,
    );
    expect(
      throwVelocity(SwipeDirection.right, const Offset(4000, 50)),
      const Offset(4000, 50),
    );
    expect(
      throwVelocity(SwipeDirection.up, const Offset(30, -100)).dy,
      -AppSwipe.minThrowSpeed,
    );
  });

  test('çıkış hedefi ve geri dönüş noktası ekranın dışında', () {
    final Offset left = exitTarget(
      SwipeDirection.left,
      const Offset(-130, 20),
      const Offset(-2000, 0),
      _screen,
    );
    expect(left.dx, lessThan(-_screen.width));
    expect(left.dy, 20);
    final Offset up = exitTarget(
      SwipeDirection.up,
      Offset.zero,
      const Offset(0, -2000),
      _screen,
    );
    expect(up.dy, lessThan(-_screen.height));
    expect(returnOrigin(SwipeDirection.right, _screen).dx, _screen.width);
    expect(returnOrigin(SwipeDirection.up, _screen).dy, -_screen.height);
  });
}

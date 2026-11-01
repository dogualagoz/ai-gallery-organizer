// motion_physics saf fonksiyonlarının birim testleri.
import 'package:ai_gallery_organizer/core/constants/motion_constants.dart';
import 'package:ai_gallery_organizer/core/utils/motion_physics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('project', () {
    test('Apple formülü: (v/1000)·d/(1−d)', () {
      // 1000 px/s, d=0.998 → 1 · 0.998 / 0.002 = 499 px.
      expect(project(1000), closeTo(499, 1e-6));
    });

    test('hızlı yavaşlama daha kısa mesafe verir', () {
      final double normal = project(1500);
      final double fast = project(
        1500,
        decelerationRate: AppMotion.decelerationFast,
      );
      expect(fast, lessThan(normal));
      expect(fast, closeTo(1.5 * 0.99 / 0.01, 1e-6));
    });

    test('hız işaretini korur, sıfır hız sıfır mesafe', () {
      expect(project(-800), lessThan(0));
      expect(project(0), 0);
    });
  });

  group('rubberband', () {
    test('sıfır aşımda sıfır, işaret korunur', () {
      expect(rubberband(0, 300), 0);
      expect(rubberband(-50, 300), lessThan(0));
    });

    test('her zaman aşımdan az ve asimptotik olarak boyuta yaklaşır', () {
      const double dimension = 300;
      final double small = rubberband(20, dimension);
      final double huge = rubberband(1e7, dimension);
      expect(small, lessThan(20));
      expect(huge, lessThan(dimension));
      expect(huge, closeTo(dimension, 1));
    });

    test('artan aşımda artış azalır (azalan marjinal takip)', () {
      final double a = rubberband(50, 300);
      final double b = rubberband(100, 300);
      final double c = rubberband(150, 300);
      expect(b - a, greaterThan(c - b));
    });

    test('geçersiz boyutta 0 döner', () {
      expect(rubberband(40, 0), 0);
    });
  });

  group('relativeVelocity', () {
    test('skill örneği: 50 px/s, 50→150 = 0.5', () {
      expect(relativeVelocity(50, 50, 150), closeTo(0.5, 1e-9));
    });

    test('mesafe yoksa 0', () {
      expect(relativeVelocity(300, 10, 10), 0);
    });
  });

  group('nearestSnap', () {
    test('projeksiyona en yakın noktayı seçer', () {
      expect(nearestSnap(140, [0, 100, 300]), 100);
      expect(nearestSnap(260, [0, 100, 300]), 300);
      expect(nearestSnap(-40, [0, 100, 300]), 0);
    });
  });
}

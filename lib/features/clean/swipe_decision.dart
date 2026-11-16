// Temizle destesinin saf jest mantığı: bırakış kararı, ilerleme, eşik
// haptiği, dönüş açısı ve çıkış yolu. Widget'tan bağımsız, birim testli.
import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import '../../core/constants/motion_constants.dart';
import '../../core/utils/motion_physics.dart';

/// Kartın gidebileceği yönler: sola sil, sağa atla, yukarı kategoriye ata.
enum SwipeDirection { left, right, up }

/// [offset]'in baskın yönü. Yatay yol yukarı yoldan büyükse sol/sağ; aşağı
/// hareketin karşılığı yoktur (yatay bileşen yoksa null).
SwipeDirection? directionOf(Offset offset) {
  if (offset.dx.abs() >= -offset.dy) {
    if (offset.dx == 0) return null;
    return offset.dx > 0 ? SwipeDirection.right : SwipeDirection.left;
  }
  return SwipeDirection.up;
}

/// [offset]'in [direction] yönündeki bileşeni; ters yönde negatiftir.
double travelAlong(Offset offset, SwipeDirection direction) {
  return switch (direction) {
    SwipeDirection.left => -offset.dx,
    SwipeDirection.right => offset.dx,
    SwipeDirection.up => -offset.dy,
  };
}

/// Sürükleme ilerlemesi (0 → 1): baskın yöndeki yolun eşiğe oranı. Yön
/// ipucunun opaklığını ve arkadaki kartın büyümesini sürer.
double swipeProgress(Offset offset) {
  final SwipeDirection? direction = directionOf(offset);
  if (direction == null) return 0;
  return (travelAlong(offset, direction) / AppSwipe.threshold).clamp(0.0, 1.0);
}

/// Bırakış kararı: konum + hız projeksiyonunun baskın yönü eşiği geçerse o
/// yön. Parmak o yönün tersine hızla dönüyorsa (vazgeçiş) ya da eşik
/// geçilmediyse null — kart yerine döner.
SwipeDirection? decideSwipe(Offset position, Offset velocity) {
  final Offset projected =
      position +
      Offset(
        project(velocity.dx, decelerationRate: AppSwipe.deceleration),
        project(velocity.dy, decelerationRate: AppSwipe.deceleration),
      );
  final SwipeDirection? direction = directionOf(projected);
  if (direction == null) return null;
  if (travelAlong(projected, direction) < AppSwipe.threshold) return null;
  if (travelAlong(velocity, direction) < -AppSwipe.cancelVelocity) return null;
  return direction;
}

/// Sürüklerken kartın eşiği geçtiği yön (haptik ve "bırakırsan gider"
/// hissi). [previous] yönünde kalındıkça çıkış için eşiğin
/// [AppSwipe.armHysteresis] gerisine dönmek gerekir: eşikte titreyen parmak
/// haptiği tekrar tekrar tetiklemez.
SwipeDirection? armedDirection(Offset offset, SwipeDirection? previous) {
  final SwipeDirection? direction = directionOf(offset);
  if (direction == null) return null;
  final double needed = direction == previous
      ? AppSwipe.threshold - AppSwipe.armHysteresis
      : AppSwipe.threshold;
  return travelAlong(offset, direction) >= needed ? direction : null;
}

/// Kartın yatış açısı (radyan): çekildiği yöne, yatay yolla orantılı ve
/// [AppSwipe.maxRotation] ile sınırlı. Tutulan nokta fark etmez: aynı jest
/// her seferinde aynı görünür ve yatış kartın gittiği yönü gösterir.
double swipeRotation(double dx, double width) {
  if (width <= 0) return 0;
  return (dx / width * AppSwipe.rotationPerWidth).clamp(
    -AppSwipe.maxRotation,
    AppSwipe.maxRotation,
  );
}

/// Gidişin başlangıç hızı (px/s): bırakış hızı korunur, gidiş ekseninde en
/// az [AppSwipe.minThrowSpeed] olur (yavaş bırakılan kart da kararlı çıkar).
Offset throwVelocity(SwipeDirection direction, Offset velocity) {
  const double min = AppSwipe.minThrowSpeed;
  return switch (direction) {
    SwipeDirection.left => Offset(-math.max(-velocity.dx, min), velocity.dy),
    SwipeDirection.right => Offset(math.max(velocity.dx, min), velocity.dy),
    SwipeDirection.up => Offset(velocity.dx, -math.max(-velocity.dy, min)),
  };
}

/// Giden kartın hedefi: gidiş ekseninde ekranın epey dışı, diğer eksende
/// [from] + hızın taşıyacağı kadar (fırlatmanın açısı korunur).
Offset exitTarget(
  SwipeDirection direction,
  Offset from,
  Offset velocity,
  Size screen,
) {
  const double far = AppSwipe.exitDistanceFactor;
  final double driftX =
      from.dx + project(velocity.dx, decelerationRate: AppSwipe.deceleration);
  final double driftY =
      from.dy + project(velocity.dy, decelerationRate: AppSwipe.deceleration);
  return switch (direction) {
    SwipeDirection.left => Offset(-screen.width * far, driftY),
    SwipeDirection.right => Offset(screen.width * far, driftY),
    SwipeDirection.up => Offset(driftX, -screen.height * far),
  };
}

/// Geri alınan kartın geldiği nokta: çıktığı kenarın hemen dışı (simetrik
/// yol — kart gittiği yerden döner).
Offset returnOrigin(SwipeDirection direction, Size screen) {
  return switch (direction) {
    SwipeDirection.left => Offset(-screen.width, 0),
    SwipeDirection.right => Offset(screen.width, 0),
    SwipeDirection.up => Offset(0, -screen.height),
  };
}

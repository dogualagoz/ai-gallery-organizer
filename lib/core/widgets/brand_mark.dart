// Uygulama logosunun vektör hâli: gradient kutucuk + iki kart + 4 uçlu parıltı.
// PNG yerine CustomPaint — açılış animasyonunda pürüzsüz ölçeklenir, her boyutta
// keskin kalır. Renkler tema `colorScheme`'inden gelir (hardcode yok).
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Marka işareti (app icon). [size] kutucuğun kenar uzunluğu.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _BrandMarkPainter(
          gradientStart: scheme.primary,
          gradientEnd: scheme.secondary,
          cardColor: Colors.white,
          sparkleColor: scheme.primary,
        ),
      ),
    );
  }
}

/// İkonu çizen ressam. Tüm ölçüler kenar uzunluğuna (S) oranlıdır.
class _BrandMarkPainter extends CustomPainter {
  _BrandMarkPainter({
    required this.gradientStart,
    required this.gradientEnd,
    required this.cardColor,
    required this.sparkleColor,
  });

  final Color gradientStart;
  final Color gradientEnd;
  final Color cardColor;
  final Color sparkleColor;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final RRect tile = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(s * _tileRadiusRatio),
    );

    // Kutucuk zemini: iris → menekşe köşegen gradient.
    final Paint bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [gradientStart, gradientEnd],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(tile, bg);
    canvas.save();
    canvas.clipRRect(tile);

    // Arka kart: sola eğik, yarı saydam beyaz.
    _drawCard(
      canvas,
      center: Offset(s * 0.42, s * 0.46),
      cardSize: Size(s * 0.40, s * 0.54),
      radius: s * 0.06,
      angle: -13 * math.pi / 180,
      color: cardColor.withValues(alpha: 0.42),
      shadow: false,
    );

    // Ön kart: hafif sağa eğik, tam beyaz + yumuşak gölge.
    final Offset frontCenter = Offset(s * 0.55, s * 0.51);
    _drawCard(
      canvas,
      center: frontCenter,
      cardSize: Size(s * 0.44, s * 0.60),
      radius: s * 0.07,
      angle: 5 * math.pi / 180,
      color: cardColor,
      shadow: true,
    );

    // Ön kartın üzerindeki büyük parıltı (iris).
    canvas.drawPath(
      _sparklePath(frontCenter, s * 0.15, _sparkleWaist),
      Paint()..color = sparkleColor,
    );

    // Sol üstteki küçük parıltı (beyaz).
    canvas.drawPath(
      _sparklePath(Offset(s * 0.29, s * 0.25), s * 0.055, _sparkleWaist),
      Paint()..color = cardColor,
    );

    canvas.restore();
  }

  /// Döndürülmüş yuvarlak köşeli kartı (opsiyonel gölgeyle) çizer.
  void _drawCard(
    Canvas canvas, {
    required Offset center,
    required Size cardSize,
    required double radius,
    required double angle,
    required Color color,
    required bool shadow,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final RRect card = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: cardSize.width,
        height: cardSize.height,
      ),
      Radius.circular(radius),
    );
    if (shadow) {
      final RRect shadowRect = card.shift(Offset(0, cardSize.height * 0.03));
      canvas.drawRRect(
        shadowRect,
        Paint()
          ..color = const Color(0xFF1B1B24).withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    canvas.drawRRect(card, Paint()..color = color);
    canvas.restore();
  }

  /// 4 uçlu parıltı (✦) yolu: dış uçlar N/E/S/W, aralar merkeze doğru büzülür.
  Path _sparklePath(Offset c, double outer, double waist) {
    final double inner = outer * waist;
    final Path path = Path();
    for (int k = 0; k < 4; k++) {
      final double outerA = k * math.pi / 2 - math.pi / 2;
      final double ctrlA = outerA + math.pi / 4;
      final Offset o = c + Offset(math.cos(outerA), math.sin(outerA)) * outer;
      final Offset ctrl = c + Offset(math.cos(ctrlA), math.sin(ctrlA)) * inner;
      final double nextA = outerA + math.pi / 2;
      final Offset next = c + Offset(math.cos(nextA), math.sin(nextA)) * outer;
      if (k == 0) path.moveTo(o.dx, o.dy);
      path.quadraticBezierTo(ctrl.dx, ctrl.dy, next.dx, next.dy);
    }
    path.close();
    return path;
  }

  /// Apple squircle'a yakın köşe oranı.
  static const double _tileRadiusRatio = 0.2237;

  /// Parıltı uçları arası büzülme (küçük = daha sivri).
  static const double _sparkleWaist = 0.14;

  @override
  bool shouldRepaint(_BrandMarkPainter oldDelegate) =>
      oldDelegate.gradientStart != gradientStart ||
      oldDelegate.gradientEnd != gradientEnd ||
      oldDelegate.cardColor != cardColor ||
      oldDelegate.sparkleColor != sparkleColor;
}

// iOS metin stilleri (SF): boyuta özgü tracking + leading, Material slotlarına eşli.
import 'package:flutter/material.dart';

/// iOS Dynamic Type "Large" (varsayılan) metin stillerini Material [TextTheme]
/// slotlarına eşler; böylece mevcut `textTheme.x` kullanımları SF metrikleriyle
/// çizilir. Tracking Apple'ın SF tablosundan: büyük metinde açılır, gövde
/// boyutlarında negatiftir — tek bir sabit letterSpacing her boyutta yanlıştır.
///
/// | Slot           | iOS stili           | pt / leading |
/// |----------------|---------------------|--------------|
/// | displaySmall   | Large Title         | 34 / 41      |
/// | headlineLarge  | Title 1             | 28 / 34      |
/// | headlineMedium | Title 2             | 22 / 28      |
/// | headlineSmall  | Title 3             | 20 / 25      |
/// | titleLarge     | Title 3 (vurgulu)   | 20 / 25      |
/// | titleMedium    | Headline            | 17 / 22      |
/// | titleSmall     | Subheadline vurgulu | 15 / 20      |
/// | bodyLarge      | Body                | 17 / 22      |
/// | bodyMedium     | Subheadline         | 15 / 20      |
/// | bodySmall      | Footnote            | 13 / 18      |
/// | labelLarge     | Body vurgulu (buton)| 17 / 22      |
/// | labelMedium    | Caption 1           | 12 / 16      |
/// | labelSmall     | Caption 2           | 11 / 13      |
abstract final class AppTypography {
  /// SF Pro Text optik boyutu (< 20pt) — Flutter iOS'ta sistem fontuna eşler.
  static const String _textFamily = 'CupertinoSystemText';

  /// SF Pro Display optik boyutu (≥ 20pt).
  static const String _displayFamily = 'CupertinoSystemDisplay';

  /// Display optik boyutuna geçilen eşik (Apple: 20pt ve üstü).
  static const double _displayThreshold = 20;

  static TextStyle _style(
    double size,
    double leading,
    double tracking,
    FontWeight weight,
  ) {
    return TextStyle(
      fontFamily: size >= _displayThreshold ? _displayFamily : _textFamily,
      fontSize: size,
      height: leading / size,
      letterSpacing: tracking,
      fontWeight: weight,
    );
  }

  // Apple SF tracking tablosu (pt cinsinden, ilgili boyut için).
  static final TextStyle largeTitle = _style(34, 41, 0.40, FontWeight.w700);
  static final TextStyle title1 = _style(28, 34, 0.38, FontWeight.w700);
  static final TextStyle title2 = _style(22, 28, -0.26, FontWeight.w700);
  static final TextStyle title3 = _style(20, 25, -0.45, FontWeight.w600);
  static final TextStyle headline = _style(17, 22, -0.43, FontWeight.w600);
  static final TextStyle body = _style(17, 22, -0.43, FontWeight.w400);
  static final TextStyle subheadline = _style(15, 20, -0.23, FontWeight.w400);
  static final TextStyle footnote = _style(13, 18, -0.08, FontWeight.w400);
  static final TextStyle caption1 = _style(12, 16, 0, FontWeight.w400);
  static final TextStyle caption2 = _style(11, 13, 0.06, FontWeight.w400);

  /// Verilen renklerle iOS ölçeğinde [TextTheme] üretir.
  static TextTheme textTheme(Color color) {
    return TextTheme(
      displayLarge: largeTitle,
      displayMedium: largeTitle,
      displaySmall: largeTitle,
      headlineLarge: title1,
      headlineMedium: title2,
      headlineSmall: title3,
      titleLarge: title3,
      titleMedium: headline,
      titleSmall: subheadline.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: body,
      bodyMedium: subheadline,
      bodySmall: footnote,
      labelLarge: headline,
      labelMedium: caption1,
      labelSmall: caption2,
    ).apply(bodyColor: color, displayColor: color);
  }
}

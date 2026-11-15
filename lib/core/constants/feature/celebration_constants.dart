// Haftalık kota kutlama sahnesinin ölçüleri.
import 'dart:ui' show Size;

import '../motion_constants.dart';

/// Haftalık kota kutlama sahnesinin ölçüleri.
abstract final class AppCelebration {
  /// Kartların yörünge salınımının bir turu.
  static final Duration drift = AppDurations.scene * 2;

  /// Sahne yüksekliği ve rozet çevresindeki mini kartların yörüngesi.
  static const double sceneHeight = 220;
  static const int cardCount = 6;
  static const double orbitRadius = 88;

  /// Süzülen kartların yörünge salınımı (px) ve en fazla yatışı (radyan).
  static const double wobble = 8;
  static const double wobbleTilt = 0.12;
  static const Size cardSize = Size(30, 52);

  /// Merkez onay rozeti, glifi ve çevresindeki yumuşak ışıma.
  static const double badgeSize = 96;
  static const double badgeGlyph = 48;
  static const double glowAlpha = 0.25;
  static const double glowBlur = 32;
  static const double glowSpread = 4;

  /// Özetteki en çok dolan kategori sayısı.
  static const int topCategories = 3;
}

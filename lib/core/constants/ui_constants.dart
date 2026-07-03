// UI sabitleri: boşluk, köşe yarıçapı ve animasyon süreleri.
// Magic number kullanmamak için tüm widget'lar bu değerleri kullanır.

/// Standart boşluk ölçeği (4pt grid).
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Standart köşe yarıçapları.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
  static const double xl = 28;
}

/// Standart animasyon süreleri.
abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 600);

  /// Onboarding gibi sahne animasyonları için uzun süre.
  static const Duration scene = Duration(milliseconds: 1200);
}

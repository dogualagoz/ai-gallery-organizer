// Boşluk ölçeği, köşe yarıçapları ve standart opaklıklar (4pt grid).

/// Standart boşluk ölçeği (4pt grid).
abstract final class AppSpacing {
  /// Rozet içi dikey pay ve kapak küçük resimleri arası ince ayraç.
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;

  /// Durum kartlarının dikey iç boşluğu ve ikon-metin aralığı.
  static const double smPlus = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Standart köşe yarıçapları.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
  static const double xl = 28;

  /// Tam yuvarlak hap formu (navbar, rozetler).
  static const double pill = 40;
}

/// Standart opaklık değerleri.
abstract final class AppOpacities {
  /// Aksan rengiyle hafifçe tonlanmış kart zemini (öneri/eylem kartları).
  static const double accentTint = 0.08;

  /// Onboarding sayfa göstergesindeki pasif noktaların opaklığı.
  static const double pageDotIdle = 0.3;

  /// Aksan rengiyle tonlanmış ikon karosu zemini.
  static const double iconTileTint = 0.12;
}

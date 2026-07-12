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

  /// Tam yuvarlak hap formu (navbar, rozetler).
  static const double pill = 40;
}

/// Sabit bileşen ölçüleri.
abstract final class AppSizes {
  static const double navBarHeight = 64;
  static const double navBarIcon = 24;

  /// Navbar pili yanındaki ayrık dairesel aksiyon butonunun kenar uzunluğu.
  static const double navBarActionSize = 64;

  /// Board kartlarındaki kapak şeridi yüksekliği referansı.
  static const double boardCoverMin = 72;
}

/// Liquid glass (iOS 26) render ayarları — sayısal değerler burada, renk
/// (glassColor) çağrı yerinde `colorScheme`'den üretilir.
abstract final class AppGlass {
  static const double thickness = 22;
  static const double blur = 18;
  static const double lightIntensity = 0.8;
  static const double refractiveIndex = 1.6;
  static const double saturation = 1.5;
  static const double ambientStrength = 0.2;

  /// `scheme.surfaceBright` üzerine uygulanan cam dolgu opaklığı; parlak,
  /// belirgin bir cam yüzeyi için yüksek tutulur (mat/soluk görünmesin diye).
  static const double tintAlpha = 0.6;

  /// Navbar pili ile ayrık aksiyon butonunun birbirine yaklaşınca
  /// kaynaşma (blend) miktarı.
  static const double blend = 20;
}

/// Standart opaklık değerleri.
abstract final class AppOpacities {
  /// Pro kullanıcının app bar'ındaki incelikli gradient tonunun opaklığı.
  static const double proAppBarTint = 0.12;
}

/// Standart animasyon süreleri.
abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 600);

  /// Onboarding gibi sahne animasyonları için uzun süre.
  static const Duration scene = Duration(milliseconds: 1200);
}

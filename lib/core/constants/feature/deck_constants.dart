// Temizle destesinin görünüm sabitleri.

/// Temizle destesinin görünümü.
abstract final class AppDeck {
  /// Kartın en-boy oranı (dikey ekran görüntüsü).
  static const double cardAspect = 9 / 16;

  /// Kart görselinin uzun kenar sınırı (px): kart ekranın yarısı kadar,
  /// görüntüleyicinin tam çözünürlüğü gerekmez.
  static const int imageMaxPx = 1920;

  /// Kartın kenar çizgisi (koyu temada siyah zeminden ayrılsın).
  static const double cardBorder = 0.5;

  /// Kart gölgesi: bulanıklık, aşağı kayma ve opaklık.
  static const double shadowBlur = 24;
  static const double shadowOffsetY = 10;
  static const double shadowAlpha = 0.16;

  /// Sürükleme ilerlemesi tamken kartın üstüne düşen yön tonu opaklığı.
  static const double hintTintAlpha = 0.22;

  /// Alttaki eylem dairelerinin çapı, ikon boyutu ve dolgu tonu opaklığı.
  static const double actionSize = 60;
  static const double actionIcon = 26;
  static const double actionTintAlpha = 0.12;

  /// Kart ile eylem satırı arasındaki sabit yuva: bekleyen silme kapsülü
  /// burada belirir; yuva hep yer kapladığı için butonlar parmağın altından
  /// kaymaz.
  static const double pendingSlot = 52;
  static const double pendingBarHeight = 36;

  /// Hedef kategori kapsülündeki ikonların boyutu.
  static const double chipIcon = 15;
  static const double chipChevron = 12;

  /// Hedef kapsülünün en geniş hali (ekran genişliğinin oranı).
  static const double chipMaxWidthFraction = 0.55;
}

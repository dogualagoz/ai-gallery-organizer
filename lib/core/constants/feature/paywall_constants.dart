// Paywall sheet'inin ölçüleri.

/// Paywall sheet'inin ölçüleri.
abstract final class AppPaywall {
  /// Hero'daki dolgulu Pro karosu ve glifi (uygulama ikonu gibi).
  static const double heroTile = 72;
  static const double heroGlyph = 40;

  /// Özellik, paket ve zaman çizelgesi satırlarındaki tonlu ikon karosu.
  static const double iconTile = 36;
  static const double iconGlyph = 20;

  /// Plan kartının seçim dairesi ve çerçeve kalınlığı. Seçili değilken
  /// çerçeve saydamdır; kalınlık değişmediği için içerik kaymaz.
  static const double planRadio = 24;
  static const double planBorder = 2;

  /// Tasarruf rozetinin kartın üst kenarına binme payı ve dikey iç boşluğu.
  static const double badgeOverlap = 10;
  static const double badgePaddingV = 3;

  /// Deneme zaman çizelgesindeki adımları bağlayan çizgi ve opaklığı.
  static const double timelineLine = 2;
  static const double timelineLineAlpha = 0.25;
}

// Gemini API katmanına göre istek temposu profilleri (free/paid).

/// Analiz kuyruğunun eşzamanlılık ve tempo ayarları.
///
/// Ücretli katmana geçiş tek satırdır: `AiConfig.activeProfile`'ı
/// [AiRateProfile.paid] yap — başka kod değişikliği gerekmez.
class AiRateProfile {
  const AiRateProfile({
    required this.concurrency,
    required this.minRequestGap,
    this.dailyCap,
  });

  /// Aynı anda uçuşta olabilecek istek sayısı.
  final int concurrency;

  /// İki istek başlangıcı arasındaki asgari süre (global, worker'lar arası).
  final Duration minRequestGap;

  /// Günlük istek tavanı (yalnız ücretsiz katmanda; null = sınırsız).
  final int? dailyCap;

  /// gemini-2.5-flash-lite ücretsiz katman: 15 istek/dk (4s) + güvenlik payı,
  /// 1.000 istek/gün.
  static const AiRateProfile free = AiRateProfile(
    concurrency: 1,
    minRequestGap: Duration(milliseconds: 4200),
    dailyCap: 1000,
  );

  /// Ücretli katman: yüksek RPM — paralel istek, tempo sınırı yok.
  static const AiRateProfile paid = AiRateProfile(
    concurrency: 5,
    minRequestGap: Duration.zero,
  );
}

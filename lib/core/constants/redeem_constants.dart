// Arkadaş/test erişimi için yerel (offline) redeem kodları ve süre ayarı.
// Backend yok: kod app içinde doğrulanır, geçerliyse Pro süreli açılır.

/// Redeem koduyla açılan Pro erişiminin ayarları.
abstract final class RedeemConfig {
  /// Geçerli bir kod girildiğinde Pro'nun açık kalacağı süre. Kalıcı değil:
  /// sızan bir kod kalıcı zarar vermesin diye bilinçli olarak sınırlı.
  static const Duration duration = Duration(days: 30);

  /// [duration]'ın gün cinsinden değeri (kullanıcıya gösterilen metinlerde).
  static int get durationDays => duration.inDays;
}

/// Geçerli redeem kodları ve normalize/doğrulama yardımcıları. Kodlar
/// arkadaşlara özeldir; yeni kod eklemek rebuild gerektirir (süre 30 günle
/// sınırlı olduğundan bu kabul edilebilir bir trade-off).
abstract final class RedeemCodes {
  /// Kabul edilen kodlar — hepsi [normalize] edilmiş biçimde tutulur.
  static const Set<String> valid = {
    'SNAPLYTEST30',
    'SNAPLYFRIEND',
    'SNAPLYVIP',
  };

  /// Kullanıcı girişini karşılaştırma için normalize eder: büyük harf,
  /// tire/boşluk temizlenir (kullanıcı 'snaply-test-30' yazsa da eşleşir).
  static String normalize(String raw) =>
      raw.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');

  /// [raw] girişi geçerli bir koda karşılık geliyor mu.
  static bool isValid(String raw) => valid.contains(normalize(raw));
}

/// Redeem kodu deneme sonucu (UI geri bildirimi için).
enum RedeemOutcome { success, invalid }

// Uygulama genelindeki sabitler: ad, limitler, box isimleri, ürün ID'leri.

/// Uygulamanın çalışma adı (placeholder — yayın öncesi tek noktadan değişir).
const String kAppName = 'Snaply';

/// Free kullanıcı limitleri (PROJECT_DOCUMENTATION.md Bölüm 3).
abstract final class FreeLimits {
  /// Ücretsiz otomatik AI analizi hakkı.
  static const int aiAnalysis = 100;

  /// Ücretsiz manuel swipe sıralama hakkı.
  static const int swipeSorts = 100;
}

/// Hive box isimleri — tek yerden yönetilir, string tekrarını önler.
abstract final class HiveBoxes {
  static const String screenshots = 'screenshots';
  static const String boards = 'boards';
  static const String settings = 'settings';
}

/// IAP ürün kimlikleri — App Store Connect tanımlarıyla birebir eşleşmeli.
abstract final class ProductIds {
  static const String monthly = 'snaply_pro_monthly';
  static const String yearly = 'snaply_pro_yearly';
  static const String lifetime = 'snaply_pro_lifetime';

  static const Set<String> all = {monthly, yearly, lifetime};
}

/// Yasal doküman linkleri (yayın öncesi gerçek URL'lerle değiştirilecek).
abstract final class LegalUrls {
  // TODO(release): Gerçek privacy/terms URL'leri yayınlanınca güncelle.
  static const String privacyPolicy = 'https://example.com/privacy';
  static const String termsOfUse = 'https://example.com/terms';
}

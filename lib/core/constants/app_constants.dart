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

  /// Box şifreleme anahtarının iOS Keychain'deki kaydının adı.
  static const String encryptionKeyName = 'snaply_hive_encryption_key';
}

/// IAP ürün kimlikleri — App Store Connect tanımlarıyla birebir eşleşmeli.
abstract final class ProductIds {
  static const String monthly = 'snaply_pro_monthly';
  static const String yearly = 'snaply_pro_yearly';
  static const String lifetime = 'snaply_pro_lifetime';

  /// Tüketilebilir analiz paketleri (Pro değil, yalnız kredi verir).
  static const String pack500 = 'snaply_pack_500';
  static const String pack1000 = 'snaply_pack_1000';

  static const Set<String> subscriptions = {monthly, yearly, lifetime};
  static const Set<String> packs = {pack500, pack1000};
  static const Set<String> all = {...subscriptions, ...packs};

  /// [productId] bir analiz paketiyse verdiği kredi miktarı, değilse null.
  static int? creditsFor(String productId) => switch (productId) {
    pack500 => 500,
    pack1000 => 1000,
    _ => null,
  };
}

/// Yasal doküman linkleri (yayın öncesi gerçek URL'lerle değiştirilecek).
abstract final class LegalUrls {
  // TODO(release): Gerçek privacy/terms URL'leri yayınlanınca güncelle.
  static const String privacyPolicy = 'https://example.com/privacy';
  static const String termsOfUse = 'https://example.com/terms';
}

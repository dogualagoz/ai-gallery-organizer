// Uygulama genelindeki sabitler: ad, limitler, box isimleri, ürün ID'leri.

/// Uygulamanın çalışma adı (placeholder — yayın öncesi tek noktadan değişir).
const String kAppName = 'Snaply';

/// Free kullanıcı limitleri (PROJECT_DOCUMENTATION.md Bölüm 3).
abstract final class FreeLimits {
  /// Haftalık ücretsiz otomatik AI analizi hakkı.
  static const int aiAnalysis = 100;

  /// Ücretsiz analiz kotasının yenilenme penceresi. Kayan 7 gün tercih
  /// edildi (ISO hafta değil): timezone/locale kenar durumu yok ve
  /// "X gün sonra yenilenir" hesabı basit.
  static const Duration aiAnalysisWindow = Duration(days: 7);

  /// Haftalık ücretsiz manuel swipe sıralama hakkı (analizle aynı
  /// [aiAnalysisWindow] penceresinde yenilenir).
  static const int swipeSorts = 100;
}

/// Ücretsiz deneme (yıllık plan intro offer) dönemindeki sınırlar.
/// Amaç: trial'da tüm galeriyi analiz ettirip iptal ederek sistemin
/// boşluğundan yararlanmayı önlemek. Diğer Pro özellikler trial'da sınırsız.
abstract final class TrialLimits {
  /// Deneme süresi boyunca izin verilen AI analizi sayısı.
  static const int aiAnalysis = 250;

  /// Deneme penceresi — StoreKit'teki 7 günlük intro offer ile eşleşir.
  static const Duration window = Duration(days: 7);
}

/// Hive box isimleri — tek yerden yönetilir, string tekrarını önler.
abstract final class HiveBoxes {
  static const String screenshots = 'screenshots';
  static const String boards = 'boards';
  static const String settings = 'settings';

  /// Kullanıcının sistem kategorilerine verdiği özel adlar (kategori index →
  /// ad). Enum sabit kalır; yalnız görüntülenen ad değişir.
  static const String categoryNames = 'category_names';

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

/// App Store değerlendirme (in_app_review) istem ayarları.
abstract final class ReviewConfig {
  /// İki değerlendirme istemi arasındaki en az süre. iOS zaten yılda en fazla
  /// 3 kez gösterir; bu, kendi ek koruma penceremiz (gereksiz sık deneme yok).
  static const Duration minInterval = Duration(days: 30);

  /// "N açılış" tetikleyicisinin eşiği — bu kadar açılıştan sonra istenebilir.
  static const int appOpenThreshold = 5;
}

/// Yasal doküman linkleri.
abstract final class LegalUrls {
  static const String privacyPolicy =
      'https://dogualagoz.github.io/ai-gallery-organizer/privacy.html';
  static const String termsOfUse =
      'https://dogualagoz.github.io/ai-gallery-organizer/terms.html';
}

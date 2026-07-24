// Gemini analiz pipeline'ının yapılandırma sabitleri.
import 'ai_rate_profile.dart';

/// AI analiz ayarları (model, görsel boyutu, istek temposu).
abstract final class AiConfig {
  static const String modelName = 'gemini-2.5-flash-lite';

  /// Aktif API katmanı profili — ücretli katmana geçişte tek değişiklik
  /// burası: [AiRateProfile.paid].
  static const AiRateProfile activeProfile = AiRateProfile.paid;

  /// Tek isteğin tavan süresi; asılı kalan istek kuyruğu kilitlemesin.
  static const Duration requestTimeout = Duration(seconds: 30);

  /// Görsel başına toplam deneme hakkı (ilk istek dahil).
  static const int maxAttempts = 3;

  /// Backoff taban süresi; her denemede katlanarak artar.
  static const Duration retryBaseDelay = Duration(seconds: 2);

  /// Analize gönderilen thumbnail boyutu — orijinal görsel yerine küçültülmüş
  /// kopya gönderilir: token maliyeti düşer, OCR için çözünürlük yeterli kalır.
  static const int imageWidth = 768;
  static const int imageHeight = 1366;
  static const int imageQuality = 80;

  /// Screenshot başına istenen etiket sayısı.
  static const int maxTags = 3;

  /// Sınıflandırma tutarlılığı için düşük sıcaklık — aynı screenshot her
  /// çalıştırmada aynı kategoriye düşmeli.
  static const double temperature = 0.1;

  /// Çıktı tavanı: ocr_text metin yoğun ekranlarda uzayabilir ama model
  /// loop'a girerse maliyet sınırsız büyümesin (çıktı, girdinin 4 katı fiyat).
  static const int maxOutputTokens = 2048;

  /// Modele gönderilen talimat. Şema `responseSchema` ile ayrıca zorlanır.
  /// Karışması muhtemel kategoriler kısa tanımlar + ayrım kurallarıyla
  /// ayrıştırılır. En kritik kural: telefonun kendi sistem ekranları
  /// (kilit + ana ekran) her zaman lock_screen'e düşer, içerik kategorilerine
  /// asla sızmaz.
  static const String prompt =
      'Label this phone screenshot with the single best matching category. '
      'Prefer the most specific category; use other ONLY when nothing else '
      'fits. Category definitions:\n'
      'lock_screen = the phone system UI itself: the LOCK SCREEN (large '
      'centered clock and date, notifications, no app grid) OR the HOME SCREEN '
      '(a grid/pages of app icons with a bottom dock, widgets, wallpaper). '
      'Any screenshot that is the device home or lock screen ALWAYS goes to '
      'lock_screen and NEVER to social, inspiration, other, entertainment or '
      'any content category.\n'
      'social = social media posts, profiles or feeds (Instagram, X, TikTok, '
      'Reddit).\n'
      'messages = one-to-one or group chat and email conversations (iMessage, '
      'WhatsApp, mail threads). Prefer messages over social for private '
      'conversations.\n'
      'shopping = product pages, online store listings, shopping carts.\n'
      'receipts = completed purchase/payment/order confirmations. Prefer '
      'receipts over finance when it is a single transaction proof.\n'
      'finance = banking, investing, crypto or budgeting app screens '
      '(balances, portfolios, charts).\n'
      'notes_passwords = notes, to-do lists, credentials, wifi codes, 2FA.\n'
      'qr_codes = a QR code or barcode is the main subject. Prefer tickets '
      'when the code is clearly a boarding pass or event ticket.\n'
      'recipes = cooking instructions with ingredients or steps. Prefer '
      'recipes over food when there is a written recipe.\n'
      'food = food/drink photos or restaurant menus without a recipe.\n'
      'places = maps, locations or venue detail screens. Prefer travel when '
      'it is a trip booking.\n'
      'travel = trips, hotels, flights, itineraries, boarding reservations.\n'
      'inspiration = ideas, quotes or aesthetics saved for later.\n'
      'memes = humor images and jokes. Prefer memes over inspiration for '
      'jokes.\n'
      'outfits = clothing, fashion and style looks.\n'
      'health = fitness, workouts, medical, sleep or nutrition tracking.\n'
      'tickets = event tickets, boarding passes, reservations with a code.\n'
      'documents = official documents, forms, contracts or IDs. Prefer '
      'documents over notes_passwords for formal paperwork.\n'
      'education = study material, courses, lectures, homework.\n'
      'entertainment = movies, TV, music, games or streaming content.\n'
      'other = only when nothing above fits.\n'
      'Give exactly $maxTags short lowercase tags describing the content, in '
      'the same language as the text in the screenshot (English if there is '
      'no text). Put all clearly readable text into ocr_text, or an empty '
      'string if there is none.';

  /// Cihaz içi kişiselleşme eşikleri: kullanıcı düzeltmelerinden öğrenilen
  /// priors, AI kategorisini yalnız net ve tekrarlı sinyalde ezmeli — aksi
  /// halde tek tük düzeltme genel doğruluğu bozabilir.
  ///
  /// Bir etiket→kategori önerisinin geçerli sayılması için toplam oy sayısı
  /// bu eşiği geçmeli.
  static const int personalizationMinVotes = 3;

  /// Öneri kategorisi, o etiketin tüm oylarının en az bu oranını almalı.
  static const double personalizationMinDominance = 0.7;
}

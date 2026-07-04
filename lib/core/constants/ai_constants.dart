// Gemini analiz pipeline'ının yapılandırma sabitleri.
import 'ai_rate_profile.dart';

/// AI analiz ayarları (model, görsel boyutu, istek temposu).
abstract final class AiConfig {
  static const String modelName = 'gemini-2.5-flash-lite';

  /// Aktif API katmanı profili — ücretli katmana geçişte tek değişiklik
  /// burası: [AiRateProfile.paid].
  static const AiRateProfile activeProfile = AiRateProfile.free;

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

  /// Modele gönderilen talimat. Şema `responseSchema` ile ayrıca zorlanır.
  static const String prompt =
      'Label this phone screenshot. Pick the single best matching category. '
      'Prefer the most specific category; use other only when nothing fits. '
      'receipts = purchase/payment confirmations, finance = banking or '
      'investing apps, recipes = cooking instructions, food = food photos or '
      'menus, places = maps and locations, travel = trips/hotels/flights. '
      'Give exactly $maxTags short lowercase tags describing the content, in '
      'the same language as the text in the screenshot (English if there is '
      'no text). Put all clearly readable text into ocr_text, or an empty '
      'string if there is none.';
}

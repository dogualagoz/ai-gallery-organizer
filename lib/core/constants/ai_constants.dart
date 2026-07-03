// Gemini analiz pipeline'ının yapılandırma sabitleri.

/// AI analiz ayarları (model, görsel boyutu, istek temposu).
abstract final class AiConfig {
  static const String modelName = 'gemini-2.5-flash';

  /// Analize gönderilen thumbnail boyutu — orijinal görsel yerine küçültülmüş
  /// kopya gönderilir: token maliyeti düşer, OCR için çözünürlük yeterli kalır.
  static const int imageWidth = 768;
  static const int imageHeight = 1366;
  static const int imageQuality = 80;

  /// Screenshot başına istenen etiket sayısı.
  static const int maxTags = 3;

  /// Ardışık istekler arası bekleme. gemini-2.5-flash'ın ücretsiz katmanı
  /// dakikada 5 istekle sınırlı (12s/istek); güvenlik payıyla 13s kullanılır.
  static const Duration requestGap = Duration(seconds: 13);

  /// Modele gönderilen talimat. Şema `responseSchema` ile ayrıca zorlanır.
  static const String prompt =
      'Label this phone screenshot. Pick the single best matching category. '
      'Give exactly $maxTags short lowercase tags describing the content, in '
      'the same language as the text in the screenshot (English if there is '
      'no text). Put all clearly readable text into ocr_text, or an empty '
      'string if there is none.';
}

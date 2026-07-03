// AI'ın atadığı sabit screenshot kategorileri (sistem board'ları).

/// Gemini'nin döndürebileceği kategori seti.
/// [wireName] structured output şemasındaki enum değerleriyle eşleşir.
enum ScreenshotCategory {
  lockScreen('lock_screen'),
  social('social'),
  shopping('shopping'),
  notesPasswords('notes_passwords'),
  messages('messages'),
  receipts('receipts'),
  other('other');

  const ScreenshotCategory(this.wireName);

  /// AI yanıtındaki JSON string karşılığı.
  final String wireName;

  /// JSON'dan güvenli çözümleme — bilinmeyen değer [other]'a düşer,
  /// böylece model şema dışına çıkarsa uygulama kırılmaz.
  static ScreenshotCategory fromWire(String? value) {
    return ScreenshotCategory.values.firstWhere(
      (category) => category.wireName == value,
      orElse: () => ScreenshotCategory.other,
    );
  }
}

// AI'ın atadığı sabit screenshot kategorileri (sistem board'ları).

/// Gemini'nin döndürebileceği kategori seti.
/// [wireName] structured output şemasındaki enum değerleriyle eşleşir.
enum ScreenshotCategory {
  // DİKKAT: Hive adapter enum'u bildirim sırası index'iyle saklar.
  // Mevcut değerlerin sırası ASLA değişmez; yeni değerler SONA eklenir.
  lockScreen('lock_screen'),
  social('social'),
  shopping('shopping'),
  notesPasswords('notes_passwords'),
  messages('messages'),
  receipts('receipts'),
  other('other'),
  qrCodes('qr_codes'),
  recipes('recipes'),
  places('places'),
  inspiration('inspiration'),
  memes('memes'),
  outfits('outfits'),
  health('health'),
  tickets('tickets'),
  travel('travel'),
  food('food'),
  finance('finance'),
  documents('documents'),
  education('education'),
  entertainment('entertainment');

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

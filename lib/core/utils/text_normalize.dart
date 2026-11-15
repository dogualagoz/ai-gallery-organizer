// Arama için Türkçe karaktere duyarsız, küçük harfli metin normalizasyonu.

/// Türkçe harf kod birimi → ASCII küçük karşılığı. Hepsi BMP içinde olduğundan
/// kod birimi düzeyinde değiştirmek vekil çiftleri bozmaz.
const Map<int, int> _turkishFold = {
  0x0130: 0x69, // İ
  0x0049: 0x69, // I
  0x0131: 0x69, // ı
  0x015E: 0x73, // Ş
  0x015F: 0x73, // ş
  0x011E: 0x67, // Ğ
  0x011F: 0x67, // ğ
  0x00DC: 0x75, // Ü
  0x00FC: 0x75, // ü
  0x00D6: 0x6F, // Ö
  0x00F6: 0x6F, // ö
  0x00C7: 0x63, // Ç
  0x00E7: 0x63, // ç
};

/// [input]'ı arama karşılaştırması için sadeleştirir: Türkçe harfler ASCII
/// karşılığına döner, geri kalan `toLowerCase()` ile küçültülür. Böylece
/// "Kış" araması "kis" ve "KIŞ" ile aynı şekilde eşleşir.
String normalizeForSearch(String input) {
  // Katlama küçültmeden önce: 'İ'.toLowerCase() iki karakterlik "i̇" verir.
  // Türkçe harf yoksa kopya hiç oluşturulmaz.
  List<int>? folded;
  for (int i = 0; i < input.length; i++) {
    final int? ascii = _turkishFold[input.codeUnitAt(i)];
    if (ascii != null) (folded ??= input.codeUnits.toList())[i] = ascii;
  }
  return (folded == null ? input : String.fromCharCodes(folded)).toLowerCase();
}

// Arama için Türkçe karaktere duyarsız, küçük harfli metin normalizasyonu.

const Map<String, String> _turkishFold = {
  'İ': 'i',
  'I': 'i',
  'ı': 'i',
  'Ş': 's',
  'ş': 's',
  'Ğ': 'g',
  'ğ': 'g',
  'Ü': 'u',
  'ü': 'u',
  'Ö': 'o',
  'ö': 'o',
  'Ç': 'c',
  'ç': 'c',
};

/// [input]'ı arama karşılaştırması için sadeleştirir: Türkçe harfler ASCII
/// karşılığına döner, geri kalan `toLowerCase()` ile küçültülür. Böylece
/// "Kış" araması "kis" ve "KIŞ" ile aynı şekilde eşleşir.
String normalizeForSearch(String input) {
  final StringBuffer buffer = StringBuffer();
  for (final int rune in input.runes) {
    final String char = String.fromCharCode(rune);
    buffer.write(_turkishFold[char] ?? char.toLowerCase());
  }
  return buffer.toString();
}

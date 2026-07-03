// normalizeForSearch: Türkçe karaktere duyarsız arama eşleşmesi testleri.
import 'package:ai_gallery_organizer/core/utils/text_normalize.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeForSearch', () {
    test('Türkçe büyük/küçük harfleri ASCII karşılığına indirger', () {
      expect(normalizeForSearch('KIŞ'), 'kis');
      expect(normalizeForSearch('kış'), 'kis');
      expect(normalizeForSearch('İstanbul'), 'istanbul');
      expect(normalizeForSearch('Işık'), 'isik');
    });

    test('ğ, ü, ö, ç sadeleştirilir', () {
      expect(normalizeForSearch('Öğrenci Çığlığı'), 'ogrenci cigligi');
    });

    test('ASCII metin değişmeden küçük harfe döner', () {
      expect(normalizeForSearch('Market Fisi'), 'market fisi');
    });
  });
}

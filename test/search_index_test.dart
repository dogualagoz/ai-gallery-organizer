// Arama dizini: kelime bazlı eşleşme (etiket, OCR, kategori adı), kategori
// filtresi, bekleyenlerin dışarıda kalması ve sık etiket sıralaması.
import 'package:ai_gallery_organizer/core/models/screenshot_category.dart';
import 'package:ai_gallery_organizer/core/models/screenshot_entry.dart';
import 'package:ai_gallery_organizer/features/search/search_index.dart';
import 'package:flutter_test/flutter_test.dart';

ScreenshotEntry _entry(
  String id, {
  ScreenshotCategory? category = ScreenshotCategory.other,
  List<String> tags = const [],
  String? ocr,
  bool pending = false,
}) {
  return ScreenshotEntry(
    assetId: id,
    createdAt: DateTime(2026),
    category: pending ? null : category,
    tags: tags,
    ocrText: ocr,
    analyzedAt: pending ? null : DateTime(2026),
  );
}

String _name(ScreenshotCategory category) => switch (category) {
  ScreenshotCategory.tickets => 'Biletler',
  ScreenshotCategory.receipts => 'Fişler',
  _ => category.name,
};

List<String> _ids(List<ScreenshotEntry> entries) => [
  for (final ScreenshotEntry entry in entries) entry.assetId,
];

void main() {
  final SearchIndex index = SearchIndex([
    _entry(
      'flight',
      category: ScreenshotCategory.tickets,
      tags: ['Uçuş', 'İstanbul'],
      ocr: 'Kalkış 09:40 Gate B12',
    ),
    _entry(
      'market',
      category: ScreenshotCategory.receipts,
      tags: ['market'],
      ocr: 'TOPLAM 245,90 TL',
    ),
    _entry('concert', category: ScreenshotCategory.tickets, tags: ['konser']),
    _entry('waiting', pending: true, tags: ['uçuş']),
  ]);

  test('Türkçe karakter ve büyük harf farkı gözetmeden eşleşir', () {
    expect(_ids(index.search('ucus', nameOf: _name)), ['flight']);
    expect(_ids(index.search('KALKIŞ', nameOf: _name)), ['flight']);
  });

  test('her kelime ayrı ayrı aranır, sıra fark etmez', () {
    expect(_ids(index.search('istanbul gate', nameOf: _name)), ['flight']);
    expect(_ids(index.search('istanbul toplam', nameOf: _name)), isEmpty);
  });

  test('kategori adı da aranır', () {
    expect(_ids(index.search('bilet', nameOf: _name)), ['flight', 'concert']);
  });

  test('kategori filtresi daraltır, boş sorgu kategorinin tamamını verir', () {
    expect(
      _ids(
        index.search('', category: ScreenshotCategory.tickets, nameOf: _name),
      ),
      ['flight', 'concert'],
    );
    expect(
      _ids(
        index.search(
          'market',
          category: ScreenshotCategory.tickets,
          nameOf: _name,
        ),
      ),
      isEmpty,
    );
  });

  test('analiz bekleyenler aranmaz ve kategori sayılmaz', () {
    expect(index.categories, {
      ScreenshotCategory.tickets,
      ScreenshotCategory.receipts,
    });
    expect(SearchIndex([_entry('x', pending: true)]).isEmpty, isTrue);
  });

  test('sık etiketler çoktan aza, eşitlikte ilk görülen önce', () {
    final SearchIndex tags = SearchIndex([
      _entry('a', tags: ['Kahve', 'tarif']),
      _entry('b', tags: ['kahve', 'menü']),
      _entry('c', tags: ['tarif', ' ']),
      _entry('d', tags: ['kahve']),
    ]);
    expect(tags.topTags(10), ['Kahve', 'tarif', 'menü']);
    expect(tags.topTags(1), ['Kahve']);
  });
}

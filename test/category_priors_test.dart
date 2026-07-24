// CategoryPriors saf mantığı: düzeltmelerden öğrenme ve konservatif öneri eşikleri.
import 'package:ai_gallery_organizer/core/models/screenshot_category.dart';
import 'package:ai_gallery_organizer/core/services/category_priors_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Aynı [tag] için [to] kategorisine [times] kez düzeltme uygular.
  PriorsMap trainTag(String tag, ScreenshotCategory to, int times) {
    PriorsMap map = {};
    for (int i = 0; i < times; i++) {
      map = CategoryPriors.record(map, ScreenshotCategory.other, to, [tag]);
    }
    return map;
  }

  group('CategoryPriors.record', () {
    test('from == to düzeltme sayılmaz, harita değişmez', () {
      const map = <String, Map<int, int>>{};
      final result = CategoryPriors.record(
        map,
        ScreenshotCategory.food,
        ScreenshotCategory.food,
        ['tag'],
      );
      expect(identical(result, map), isTrue);
    });

    test('etiketler normalize edilip oy biriktirir', () {
      final map = CategoryPriors.record(
        {},
        ScreenshotCategory.other,
        ScreenshotCategory.finance,
        ['  Bank  ', 'BANK', ''],
      );
      // 'bank' tek anahtara iner, boş etiket atlanır.
      expect(map.keys, ['bank']);
      expect(map['bank'], {ScreenshotCategory.finance.index: 1});
    });
  });

  group('CategoryPriors.suggest', () {
    test('3x aynı etiket→kategori sonrası o kategoriyi önerir', () {
      final map = trainTag('receipt', ScreenshotCategory.receipts, 3);
      expect(
        CategoryPriors.suggest(map, ['receipt']),
        ScreenshotCategory.receipts,
      );
    });

    test('minVotes eşiğinin altında (2x) öneri yok', () {
      final map = trainTag('receipt', ScreenshotCategory.receipts, 2);
      expect(CategoryPriors.suggest(map, ['receipt']), isNull);
    });

    test('baskınlık eşiğinin altında (karışık oy) öneri yok', () {
      // 'x' 2x food, 'y' 2x finance → toplam 4 oy ama baskınlık %50.
      PriorsMap map = trainTag('x', ScreenshotCategory.food, 2);
      for (int i = 0; i < 2; i++) {
        map = CategoryPriors.record(
          map,
          ScreenshotCategory.other,
          ScreenshotCategory.finance,
          ['y'],
        );
      }
      expect(CategoryPriors.suggest(map, ['x', 'y']), isNull);
    });

    test('bilinmeyen etiket için öneri yok', () {
      final map = trainTag('receipt', ScreenshotCategory.receipts, 5);
      expect(CategoryPriors.suggest(map, ['unknown']), isNull);
    });
  });
}

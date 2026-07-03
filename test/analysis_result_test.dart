// AnalysisResult JSON çözümlemesinin savunmacı davranış testleri.
import 'package:ai_gallery_organizer/core/models/screenshot_category.dart';
import 'package:ai_gallery_organizer/features/analysis/data/analysis_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalysisResult.fromJsonString', () {
    test('geçerli yanıtı çözer', () {
      final result = AnalysisResult.fromJsonString(
        '{"category":"receipts","tags":["fatura","market","fiş"],'
        '"ocr_text":"Toplam 149,90 TL"}',
      );
      expect(result.category, ScreenshotCategory.receipts);
      expect(result.tags, ['fatura', 'market', 'fiş']);
      expect(result.ocrText, 'Toplam 149,90 TL');
    });

    test('bilinmeyen kategori other kategorisine düşer', () {
      final result = AnalysisResult.fromJsonString(
        '{"category":"memes","tags":[],"ocr_text":""}',
      );
      expect(result.category, ScreenshotCategory.other);
    });

    test('boş/eksik ocr_text null olur', () {
      final result = AnalysisResult.fromJsonString(
        '{"category":"social","tags":["a"],"ocr_text":"  "}',
      );
      expect(result.ocrText, isNull);
    });

    test('fazla ve bozuk etiketler temizlenir', () {
      final result = AnalysisResult.fromJsonString(
        '{"category":"social","tags":["a","", "b", 3, "c", "d"]}',
      );
      // Boş/string olmayan etiketler atılır, ilk 3 tanesi kalır.
      expect(result.tags, ['a', 'b', 'c']);
    });

    test('JSON nesnesi olmayan yanıt FormatException fırlatır', () {
      expect(
        () => AnalysisResult.fromJsonString('["liste"]'),
        throwsFormatException,
      );
      expect(
        () => AnalysisResult.fromJsonString('bozuk'),
        throwsFormatException,
      );
    });
  });
}

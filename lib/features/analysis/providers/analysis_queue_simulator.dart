// DEBUG analiz simülasyonunun saf parçaları: sahte tur öğeleri ve tempo.
import 'dart:math';

import '../../../core/models/screenshot_category.dart';
import '../../../core/models/screenshot_entry.dart';
import 'analysis_queue_state.dart';

/// Sahte tur adımları arasındaki en kısa gecikme (ms).
const int _minDelayMs = 250;

/// Gecikmeye eklenen rastgele aralık (ms): Gemini dönüşlerinin düzensiz
/// temposunu taklit eder.
const int _delayJitterMs = 450;

/// [entries]'in ilk [count] kaydı için sahte analiz sonuçları. Kategoriler
/// yalnız halihazırda dolu olanlardan seçilir ki uçan küçük resimler ekranda
/// gerçekten var olan karolara insin; hiç yoksa (ilk kurulum) tüm
/// kategorilerden.
List<AnalyzedItem> simulatedRun(
  List<ScreenshotEntry> entries, {
  required int count,
  required Random random,
}) {
  final List<ScreenshotCategory> filled = [
    for (final ScreenshotCategory category in ScreenshotCategory.values)
      if (entries.any((entry) => entry.category == category)) category,
  ];
  final List<ScreenshotCategory> categories = filled.isNotEmpty
      ? filled
      : ScreenshotCategory.values;
  return [
    for (final ScreenshotEntry entry in entries.take(count))
      AnalyzedItem(
        assetId: entry.assetId,
        category: categories[random.nextInt(categories.length)],
      ),
  ];
}

/// Sahte turda iki sonuç arasındaki rastgele bekleme.
Duration simulatedDelay(Random random) =>
    Duration(milliseconds: _minDelayMs + random.nextInt(_delayJitterMs));

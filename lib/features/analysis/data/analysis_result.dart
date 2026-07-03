// Gemini yanıtının tip güvenli karşılığı ve savunmacı JSON çözümleme.
import 'dart:convert';

import '../../../core/constants/ai_constants.dart';
import '../../../core/models/screenshot_category.dart';

/// Tek screenshot için AI analiz sonucu.
class AnalysisResult {
  const AnalysisResult({
    required this.category,
    required this.tags,
    this.ocrText,
  });

  final ScreenshotCategory category;
  final List<String> tags;
  final String? ocrText;

  /// Gemini'nin JSON yanıtını çözer.
  /// Şema dışı değerlerde güvenli düşüş yapar (bilinmeyen kategori → other,
  /// bozuk tags → boş liste); geçersiz JSON'da [FormatException] fırlatır.
  factory AnalysisResult.fromJsonString(String source) {
    final Object? decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Model yanıtı JSON nesnesi değil');
    }

    final List<String> tags = switch (decoded['tags']) {
      final List<dynamic> raw =>
        raw
            .whereType<String>()
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .take(AiConfig.maxTags)
            .toList(),
      _ => const [],
    };

    final Object? rawOcr = decoded['ocr_text'];
    final String? ocrText = rawOcr is String && rawOcr.trim().isNotEmpty
        ? rawOcr.trim()
        : null;

    return AnalysisResult(
      category: ScreenshotCategory.fromWire(decoded['category'] as String?),
      tags: tags,
      ocrText: ocrText,
    );
  }
}

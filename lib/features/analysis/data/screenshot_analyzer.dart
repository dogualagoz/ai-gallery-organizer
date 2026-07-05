// Gemini (firebase_ai) ile screenshot analizi: görsel gönder, structured output al.
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/constants/ai_constants.dart';
import '../../../core/models/screenshot_category.dart';
import 'analysis_exceptions.dart';
import 'analysis_result.dart';
import 'retry_policy.dart';

final screenshotAnalyzerProvider = Provider<ScreenshotAnalyzer>((ref) {
  return ScreenshotAnalyzer();
});

/// Tek screenshot'ı Gemini'ye gönderip [AnalysisResult] üretir.
class ScreenshotAnalyzer {
  GenerativeModel? _model;

  /// Model tembel oluşturulur — Firebase.initializeApp main'de tamamlanmış olmalı.
  GenerativeModel get _generativeModel {
    return _model ??= FirebaseAI.googleAI().generativeModel(
      model: AiConfig.modelName,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _responseSchema,
        temperature: AiConfig.temperature,
        maxOutputTokens: AiConfig.maxOutputTokens,
      ),
    );
  }

  /// Structured output şeması: kategori enum'u + etiketler + OCR metni.
  static final Schema _responseSchema = Schema.object(
    properties: {
      'category': Schema.enumString(
        enumValues: [
          for (final ScreenshotCategory category in ScreenshotCategory.values)
            category.wireName,
        ],
        description: 'Best matching category for the screenshot.',
      ),
      'tags': Schema.array(
        items: Schema.string(),
        description:
            'Exactly ${AiConfig.maxTags} short lowercase content tags.',
      ),
      'ocr_text': Schema.string(
        description: 'All readable text in the image, empty if none.',
      ),
    },
  );

  static const RetryPolicy _retryPolicy = RetryPolicy(
    maxAttempts: AiConfig.maxAttempts,
    baseDelay: AiConfig.retryBaseDelay,
  );

  /// [asset] görselini analiz eder; geçici hatalarda backoff'la yeniden
  /// dener. Denemeler biterse hata çağırana fırlar (kuyruk katmanı ele alır);
  /// kalıcı 429 [AnalysisRateLimitException] olarak tiplenir.
  Future<AnalysisResult> analyze(AssetEntity asset) async {
    final Uint8List? bytes = await asset.thumbnailDataWithSize(
      const ThumbnailSize(AiConfig.imageWidth, AiConfig.imageHeight),
      quality: AiConfig.imageQuality,
    );
    if (bytes == null) {
      throw StateError('Screenshot verisi okunamadı: ${asset.id}');
    }

    final Content content = Content.multi([
      InlineDataPart('image/jpeg', bytes),
      TextPart(AiConfig.prompt),
    ]);

    int attempt = 0;
    while (true) {
      attempt++;
      try {
        return await _request(content);
      } catch (error) {
        if (!_retryPolicy.shouldRetry(error, attempt)) {
          if (error is QuotaExceeded) {
            throw AnalysisRateLimitException(error.message);
          }
          rethrow;
        }
        await Future<void>.delayed(_retryPolicy.delayFor(attempt));
      }
    }
  }

  Future<AnalysisResult> _request(Content content) async {
    final GenerateContentResponse response = await _generativeModel
        .generateContent([content])
        .timeout(AiConfig.requestTimeout);
    final String? text = response.text;
    if (text == null || text.isEmpty) {
      throw const FormatException('Model boş yanıt döndürdü');
    }
    return AnalysisResult.fromJsonString(text);
  }
}

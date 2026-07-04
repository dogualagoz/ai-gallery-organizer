// Analiz pipeline'ına özgü tiplenmiş hatalar.

/// Tüm denemelere rağmen kota/429 hatası sürdüğünde fırlatılır.
///
/// Kuyruk katmanı bu hatayı görünce koşuyu durdurur ve durumu
/// "günlük limit doldu" olarak işaretler; kalan öğeler pending kalır.
class AnalysisRateLimitException implements Exception {
  const AnalysisRateLimitException(this.message);

  final String message;

  @override
  String toString() => 'AnalysisRateLimitException: $message';
}

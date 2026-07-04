// Analiz isteklerinin retry/backoff karar mantığı (saf Dart, test edilebilir).
import 'dart:math';

import 'package:firebase_ai/firebase_ai.dart';

/// Hangi hatanın yeniden denenebileceğine ve bekleme süresine karar verir.
///
/// Denylist yaklaşımı: kalıcı yapılandırma hataları (geçersiz anahtar vb.)
/// dışındaki her şey geçici sayılır — ağ hataları SDK'dan farklı tiplerle
/// gelebildiği için allowlist güvenilir değil.
class RetryPolicy {
  const RetryPolicy({required this.maxAttempts, required this.baseDelay});

  final int maxAttempts;
  final Duration baseDelay;

  /// [attempt] 1'den başlar; deneme hakkı varsa ve hata geçiciyse true.
  bool shouldRetry(Object error, int attempt) {
    if (attempt >= maxAttempts) return false;
    return isTransient(error);
  }

  /// Kalıcı hatalar: yapılandırma sorunları ve programlama hataları.
  bool isTransient(Object error) {
    if (error is Error) return false;
    if (error is InvalidApiKey ||
        error is ServiceApiNotEnabled ||
        error is UnsupportedUserLocation) {
      return false;
    }
    return true;
  }

  /// Exponential backoff + jitter: base * 2^(attempt-1) * [0.75, 1.25).
  Duration delayFor(int attempt, {Random? random}) {
    final Random rng = random ?? Random();
    final double factor = (1 << (attempt - 1)) * (0.75 + rng.nextDouble() / 2);
    return Duration(
      milliseconds: (baseDelay.inMilliseconds * factor).round(),
    );
  }
}

// RetryPolicy'nin retry kararı ve backoff süre hesabı testleri.
import 'dart:async';
import 'dart:math';

import 'package:ai_gallery_organizer/features/analysis/data/retry_policy.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policy = RetryPolicy(maxAttempts: 3, baseDelay: Duration(seconds: 2));

  group('RetryPolicy.shouldRetry', () {
    test('geçici hatalar deneme hakkı varken yeniden denenir', () {
      expect(policy.shouldRetry(TimeoutException('t'), 1), isTrue);
      expect(policy.shouldRetry(const FormatException('f'), 2), isTrue);
      expect(policy.shouldRetry(QuotaExceeded('429'), 1), isTrue);
      expect(policy.shouldRetry(ServerException('500'), 1), isTrue);
    });

    test('deneme hakkı bitince false döner', () {
      expect(policy.shouldRetry(TimeoutException('t'), 3), isFalse);
      expect(policy.shouldRetry(QuotaExceeded('429'), 4), isFalse);
    });

    test('kalıcı yapılandırma hataları hiç denenmez', () {
      expect(policy.shouldRetry(InvalidApiKey('bad key'), 1), isFalse);
      expect(policy.shouldRetry(ServiceApiNotEnabled('off'), 1), isFalse);
      expect(policy.shouldRetry(UnsupportedUserLocation(), 1), isFalse);
      expect(policy.shouldRetry(StateError('bug'), 1), isFalse);
    });
  });

  group('RetryPolicy.delayFor', () {
    test('exponential artar ve jitter [0.75, 1.25) aralığında kalır', () {
      final Random rng = Random(42);
      for (int attempt = 1; attempt <= 3; attempt++) {
        final int base = 2000 * (1 << (attempt - 1));
        final Duration delay = policy.delayFor(attempt, random: rng);
        expect(delay.inMilliseconds, greaterThanOrEqualTo((base * 0.75).round()));
        expect(delay.inMilliseconds, lessThan((base * 1.25).round()));
      }
    });
  });
}

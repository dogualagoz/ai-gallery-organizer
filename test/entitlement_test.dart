// EntitlementService: free/kredi tüketim sırası ve yetki matrisi testleri.
import 'package:ai_gallery_organizer/core/constants/app_constants.dart';
import 'package:ai_gallery_organizer/core/services/entitlement_service.dart';
import 'package:ai_gallery_organizer/core/services/preferences_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container({
  Map<String, Object> initialValues = const {},
}) async {
  SharedPreferences.setMockInitialValues(initialValues);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  return container;
}

void main() {
  group('EntitlementState.canAnalyze matrisi', () {
    test('free kullanıcı kota bitmeden analiz edebilir', () async {
      final container = await _container();
      final state = container.read(entitlementProvider);
      expect(state.isPro, isFalse);
      expect(state.canAnalyze, isTrue);
      expect(state.totalRemainingAnalysis, FreeLimits.aiAnalysis);
    });

    test('free kota bitince ve kredi yoksa analiz edemez', () async {
      final container = await _container();
      final notifier = container.read(entitlementProvider.notifier);
      await notifier.registerAnalysis(FreeLimits.aiAnalysis);
      final state = container.read(entitlementProvider);
      expect(state.canAnalyze, isFalse);
      expect(state.totalRemainingAnalysis, 0);
    });

    test('Pro kullanıcı kota tükense de analiz edebilir', () async {
      final container = await _container();
      final notifier = container.read(entitlementProvider.notifier);
      await notifier.setPro(true);
      await notifier.registerAnalysis(FreeLimits.aiAnalysis);
      expect(container.read(entitlementProvider).canAnalyze, isTrue);
    });
  });

  group('kredi tüketim sırası', () {
    test('free kota biterse taşan kısım kredilerden düşer', () async {
      final container = await _container();
      final notifier = container.read(entitlementProvider.notifier);
      await notifier.addCredits(50);

      // Free kotanın tamamını + 20 fazlasını tüket.
      await notifier.registerAnalysis(FreeLimits.aiAnalysis + 20);

      final state = container.read(entitlementProvider);
      expect(state.aiAnalysisUsed, FreeLimits.aiAnalysis);
      expect(state.remainingFreeAnalysis, 0);
      expect(state.analysisCredits, 30);
      expect(state.totalRemainingAnalysis, 30);
    });

    test('free kota dolmadan tüketim yalnız free sayaca yazılır', () async {
      final container = await _container();
      final notifier = container.read(entitlementProvider.notifier);
      await notifier.addCredits(50);
      await notifier.registerAnalysis(10);

      final state = container.read(entitlementProvider);
      expect(state.aiAnalysisUsed, 10);
      expect(state.analysisCredits, 50);
    });

    test('kredi negatife düşmez', () async {
      final container = await _container();
      final notifier = container.read(entitlementProvider.notifier);
      await notifier.addCredits(5);
      await notifier.registerAnalysis(FreeLimits.aiAnalysis + 5);

      expect(container.read(entitlementProvider).analysisCredits, 0);
    });
  });

  group('haftalık kota penceresi', () {
    test('migration: pencere anahtarı yoksa sayaç sıfırlanıp pencere açılır',
        () async {
      // Ömürlük-kota sürümünden gelen kullanıcı: kullanım var ama pencere yok.
      final container = await _container(
        initialValues: {PrefKeys.aiAnalysisUsed: 80},
      );
      final state = container.read(entitlementProvider);
      expect(state.aiAnalysisUsed, 0);
      expect(state.weekStartMs, greaterThan(0));
      expect(state.remainingFreeAnalysis, FreeLimits.aiAnalysis);
    });

    test('dolmamış pencere ve sayaç korunur', () async {
      final int recentStart = DateTime.now()
          .subtract(const Duration(days: 1))
          .millisecondsSinceEpoch;
      final container = await _container(
        initialValues: {
          PrefKeys.aiAnalysisUsed: 40,
          PrefKeys.aiWeekStart: recentStart,
        },
      );
      final state = container.read(entitlementProvider);
      expect(state.aiAnalysisUsed, 40);
      expect(state.weekStartMs, recentStart);
    });

    test('süresi dolmuş pencere build sırasında sıfırlanır', () async {
      final int oldStart = DateTime.now()
          .subtract(FreeLimits.aiAnalysisWindow + const Duration(hours: 1))
          .millisecondsSinceEpoch;
      final container = await _container(
        initialValues: {
          PrefKeys.aiAnalysisUsed: 100,
          PrefKeys.aiWeekStart: oldStart,
        },
      );
      final state = container.read(entitlementProvider);
      expect(state.aiAnalysisUsed, 0);
      expect(state.weekStartMs, greaterThan(oldStart));
    });

    test('ensureWeeklyWindow süre dolunca free sayacı sıfırlar, kredi kalır',
        () async {
      final container = await _container();
      final notifier = container.read(entitlementProvider.notifier);
      await notifier.addCredits(50);
      await notifier.registerAnalysis(FreeLimits.aiAnalysis);
      expect(container.read(entitlementProvider).canAnalyze, isTrue);

      final DateTime later = DateTime.now().add(
        FreeLimits.aiAnalysisWindow + const Duration(minutes: 1),
      );
      notifier.ensureWeeklyWindow(now: later);

      final state = container.read(entitlementProvider);
      expect(state.aiAnalysisUsed, 0);
      expect(state.remainingFreeAnalysis, FreeLimits.aiAnalysis);
      expect(state.analysisCredits, 50);
    });

    test('ensureWeeklyWindow pencere dolmadıysa hiçbir şeyi değiştirmez',
        () async {
      final container = await _container();
      final notifier = container.read(entitlementProvider.notifier);
      await notifier.registerAnalysis(30);
      final int weekStart = container.read(entitlementProvider).weekStartMs;

      notifier.ensureWeeklyWindow();

      final state = container.read(entitlementProvider);
      expect(state.aiAnalysisUsed, 30);
      expect(state.weekStartMs, weekStart);
    });

    test('nextWeeklyReset pencere başlangıcı + 7 gündür', () async {
      final container = await _container();
      final state = container.read(entitlementProvider);
      expect(
        state.nextWeeklyReset,
        DateTime.fromMillisecondsSinceEpoch(
          state.weekStartMs,
        ).add(FreeLimits.aiAnalysisWindow),
      );
    });
  });

  group('trial analiz sınırı', () {
    test('yıllık satın alma trial penceresini açar ve sınır uygulanır',
        () async {
      final container = await _container();
      final notifier = container.read(entitlementProvider.notifier);
      await notifier.setProFromPurchase(productId: ProductIds.yearly);

      var state = container.read(entitlementProvider);
      expect(state.isInTrialWindow, isTrue);
      expect(state.remainingTrialAnalysis, TrialLimits.aiAnalysis);
      expect(state.canAnalyze, isTrue);

      await notifier.registerAnalysis(TrialLimits.aiAnalysis);
      state = container.read(entitlementProvider);
      expect(state.remainingTrialAnalysis, 0);
      expect(state.canAnalyze, isFalse);
      // Haftalık free sayaç trial tüketiminden etkilenmez.
      expect(state.aiAnalysisUsed, 0);
    });

    test('pencere geçmişte kaldıysa Pro sınırsızdır', () async {
      final container = await _container();
      final notifier = container.read(entitlementProvider.notifier);
      final int oldMs = DateTime.now()
          .subtract(TrialLimits.window + const Duration(hours: 1))
          .millisecondsSinceEpoch;
      await notifier.setProFromPurchase(
        productId: ProductIds.yearly,
        purchaseMs: oldMs,
      );

      final state = container.read(entitlementProvider);
      expect(state.isInTrialWindow, isFalse);
      expect(state.canAnalyze, isTrue);
    });

    test('aylık/lifetime satın almada trial penceresi oluşmaz', () async {
      final container = await _container();
      final notifier = container.read(entitlementProvider.notifier);
      await notifier.setProFromPurchase(productId: ProductIds.lifetime);
      expect(container.read(entitlementProvider).isInTrialWindow, isFalse);
    });

    test('trial sınırı dolunca krediler kullanılabilir', () async {
      final container = await _container();
      final notifier = container.read(entitlementProvider.notifier);
      await notifier.setProFromPurchase(productId: ProductIds.yearly);
      await notifier.addCredits(10);
      await notifier.registerAnalysis(TrialLimits.aiAnalysis + 4);

      final state = container.read(entitlementProvider);
      expect(state.remainingTrialAnalysis, 0);
      expect(state.analysisCredits, 6);
      expect(state.canAnalyze, isTrue);
    });

    test('setPro(false) trial izlerini temizler, free hafta korunur',
        () async {
      final container = await _container();
      final notifier = container.read(entitlementProvider.notifier);
      // Önce free kullanıcı olarak biraz kota harca.
      await notifier.registerAnalysis(20);
      await notifier.setProFromPurchase(productId: ProductIds.yearly);
      await notifier.registerAnalysis(50);
      await notifier.setPro(false);

      final state = container.read(entitlementProvider);
      expect(state.isPro, isFalse);
      expect(state.isInTrialWindow, isFalse);
      expect(state.proProductId, isNull);
      expect(state.trialAnalysisUsed, 0);
      // Trial'a girmeden önceki free kullanım aynen durur.
      expect(state.aiAnalysisUsed, 20);
    });
  });

  group('canCreateBoards', () {
    test('free kullanıcı özel pano oluşturamaz', () async {
      final container = await _container();
      expect(container.read(entitlementProvider).canCreateBoards, isFalse);
    });

    test('Pro kullanıcı özel pano oluşturabilir', () async {
      final container = await _container();
      await container.read(entitlementProvider.notifier).setPro(true);
      expect(container.read(entitlementProvider).canCreateBoards, isTrue);
    });
  });
}

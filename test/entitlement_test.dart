// EntitlementService: free/kredi tüketim sırası ve yetki matrisi testleri.
import 'package:ai_gallery_organizer/core/constants/app_constants.dart';
import 'package:ai_gallery_organizer/core/services/entitlement_service.dart';
import 'package:ai_gallery_organizer/core/services/preferences_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
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

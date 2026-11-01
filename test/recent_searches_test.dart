// Son aramalar: başa ekleme, harf/Türkçe karakter farkı gözetmeyen tekrar
// eleme, sınır, boş sorgu ve SharedPreferences'a kalıcı yazım.
import 'package:ai_gallery_organizer/core/constants/app_constants.dart';
import 'package:ai_gallery_organizer/core/services/preferences_service.dart';
import 'package:ai_gallery_organizer/core/services/recent_searches_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('pushRecentSearch', () {
    test('yeni sorgu başa gelir, kenar boşlukları kırpılır', () {
      expect(pushRecentSearch(['fatura'], '  bilet '), ['bilet', 'fatura']);
    });

    test('aynı sorgu harf ve Türkçe karakter farkıyla da tekrar etmez', () {
      expect(pushRecentSearch(['bilet', 'Kış', 'fatura'], 'KIS'), [
        'KIS',
        'bilet',
        'fatura',
      ]);
    });

    test('boş sorgu listeyi değiştirmez', () {
      final List<String> recent = ['bilet'];
      expect(pushRecentSearch(recent, '   '), same(recent));
    });

    test('liste sınırda kırpılır, en eskisi düşer', () {
      final List<String> full = [
        for (int i = 0; i < SearchLimits.recent; i++) 'q$i',
      ];
      final List<String> next = pushRecentSearch(full, 'yeni');
      expect(next.length, SearchLimits.recent);
      expect(next.first, 'yeni');
      expect(next, isNot(contains('q${SearchLimits.recent - 1}')));
    });
  });

  group('RecentSearchesNotifier', () {
    late SharedPreferences prefs;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        PrefKeys.recentSearches: ['eski'],
      });
      prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
    });

    tearDown(() => container.dispose());

    test('kayıtlı geçmişi okur, eklenen sorguyu kalıcı yazar', () async {
      expect(container.read(recentSearchesProvider), ['eski']);
      await container.read(recentSearchesProvider.notifier).add('yeni');
      expect(container.read(recentSearchesProvider), ['yeni', 'eski']);
      expect(prefs.getStringList(PrefKeys.recentSearches), ['yeni', 'eski']);
    });

    test('temizle geçmişi siler', () async {
      await container.read(recentSearchesProvider.notifier).clear();
      expect(container.read(recentSearchesProvider), isEmpty);
      expect(prefs.getStringList(PrefKeys.recentSearches), isEmpty);
    });
  });
}

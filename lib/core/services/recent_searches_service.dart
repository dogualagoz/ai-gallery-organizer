// Son aramalar: SharedPreferences'ta saklanan, en yenisi başta, sınırlı liste.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../utils/text_normalize.dart';
import 'preferences_service.dart';

/// [query]'yi [recent] listesinin başına koyar. Boş sorgu yok sayılır;
/// aynı sorgunun eski kaydı (büyük/küçük harf ve Türkçe karakter farkı
/// gözetmeden) düşer; liste [limit] ile kırpılır.
List<String> pushRecentSearch(
  List<String> recent,
  String query, {
  int limit = SearchLimits.recent,
}) {
  final String trimmed = query.trim();
  if (trimmed.isEmpty) return recent;
  final String key = normalizeForSearch(trimmed);
  return [
    trimmed,
    ...recent.where((item) => normalizeForSearch(item) != key),
  ].take(limit).toList();
}

/// Son aramalar (en yenisi başta).
final recentSearchesProvider =
    NotifierProvider<RecentSearchesNotifier, List<String>>(
      RecentSearchesNotifier.new,
    );

/// Son aramaları ekler, siler ve kalıcı yazar.
class RecentSearchesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() =>
      ref
          .read(sharedPreferencesProvider)
          .getStringList(PrefKeys.recentSearches) ??
      const [];

  /// [query]'yi en başa alır.
  Future<void> add(String query) => _save(pushRecentSearch(state, query));

  /// Tüm geçmişi siler.
  Future<void> clear() => _save(const []);

  /// Bellekteki liste hemen güncellenir; kalıcı yazım başarısızsa yalnız
  /// loglanır (geçmiş bu oturumda yine çalışır, kayıp küçük).
  Future<void> _save(List<String> next) async {
    if (listEquals(next, state)) return;
    state = next;
    try {
      final bool saved = await ref
          .read(sharedPreferencesProvider)
          .setStringList(PrefKeys.recentSearches, next);
      if (!saved) debugPrint('Son aramalar kaydedilemedi');
    } catch (error, stackTrace) {
      debugPrint('Son aramalar kaydedilemedi: $error\n$stackTrace');
    }
  }
}

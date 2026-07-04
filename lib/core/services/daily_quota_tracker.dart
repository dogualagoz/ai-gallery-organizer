// Günlük Gemini istek sayacı — ücretsiz katmanın istek/gün tavanını izler.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'preferences_service.dart';

final dailyQuotaTrackerProvider = Provider<DailyQuotaTracker>((ref) {
  return DailyQuotaTracker(ref.watch(sharedPreferencesProvider));
});

/// Prefs tabanlı günlük istek sayacı.
///
/// Google kota günü Pasifik gece yarısında sıfırlanır; yerel tarih
/// yaklaşıklığı yeterli — sayaç güvenlik payı olarak kullanılıyor,
/// kesin muhasebe API tarafında.
class DailyQuotaTracker {
  DailyQuotaTracker(this._prefs);

  final SharedPreferences _prefs;

  String get _today {
    final DateTime now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  /// Bugün yapılmış istek sayısı (gün değiştiyse 0).
  int get usedToday {
    if (_prefs.getString(PrefKeys.aiDailyDate) != _today) return 0;
    return _prefs.getInt(PrefKeys.aiDailyCount) ?? 0;
  }

  /// [dailyCap] null ise sınırsız (ücretli katman).
  bool canRequest(int? dailyCap) => dailyCap == null || usedToday < dailyCap;

  /// Bir isteği sayaca işler; gün değiştiyse sayaç sıfırdan başlar.
  Future<void> register() async {
    final int next = usedToday + 1;
    await _prefs.setString(PrefKeys.aiDailyDate, _today);
    await _prefs.setInt(PrefKeys.aiDailyCount, next);
  }
}

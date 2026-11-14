// DailyQuotaTracker: sayaç, gün değişimi ve eşzamanlı register'da kayıp güncelleme olmaması.
import 'package:ai_gallery_organizer/core/services/daily_quota_tracker.dart';
import 'package:ai_gallery_organizer/core/services/preferences_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<DailyQuotaTracker> _tracker(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return DailyQuotaTracker(await SharedPreferences.getInstance());
}

void main() {
  test('boş başlar, register sayacı artırır', () async {
    final DailyQuotaTracker tracker = await _tracker({});
    expect(tracker.usedToday, 0);

    await tracker.register();
    await tracker.register();

    expect(tracker.usedToday, 2);
  });

  test(
    'önceki günün sayacı bugün 0 sayılır ve register sıfırdan başlar',
    () async {
      final DailyQuotaTracker tracker = await _tracker({
        PrefKeys.aiDailyDate: '2000-1-1',
        PrefKeys.aiDailyCount: 900,
      });
      expect(tracker.usedToday, 0);

      await tracker.register();

      expect(tracker.usedToday, 1);
    },
  );

  test('eşzamanlı register çağrıları güncelleme kaybetmez', () async {
    final DailyQuotaTracker tracker = await _tracker({});

    await Future.wait([for (int i = 0; i < 5; i++) tracker.register()]);

    expect(tracker.usedToday, 5);
  });

  test('canRequest: tavan null ise sınırsız, doluysa false', () async {
    final DailyQuotaTracker tracker = await _tracker({});
    await Future.wait([for (int i = 0; i < 3; i++) tracker.register()]);

    expect(tracker.canRequest(null), isTrue);
    expect(tracker.canRequest(4), isTrue);
    expect(tracker.canRequest(3), isFalse);
  });
}

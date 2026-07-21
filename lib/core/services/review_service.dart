// App Store değerlendirme istemini (in_app_review) olumlu anlarda, kendi
// cooldown penceremizle tetikleyen servis. iOS'un yıllık 3-çağrı sınırı doğal
// throttle; bu servis ayrıca gereksiz sık denemeleri de engeller.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import 'preferences_service.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService(ref.read(sharedPreferencesProvider));
});

class ReviewService {
  ReviewService(this._prefs);

  final SharedPreferences _prefs;
  final InAppReview _inAppReview = InAppReview.instance;

  /// Olumlu bir andan sonra çağrılır: cooldown dolduysa ve platform
  /// destekliyorsa sistem değerlendirme sheet'ini ister. Sık çağrılması
  /// güvenlidir — koşullar sağlanmazsa sessizce döner.
  Future<void> requestIfAppropriate() async {
    final int lastMs = _prefs.getInt(PrefKeys.lastReviewRequestMs) ?? 0;
    final DateTime last = DateTime.fromMillisecondsSinceEpoch(lastMs);
    if (DateTime.now().difference(last) < ReviewConfig.minInterval) return;
    if (!await _inAppReview.isAvailable()) return;
    // İstenmeden önce zamanı yaz: iOS sheet'i göstermese bile cooldown işler.
    await _prefs.setInt(
      PrefKeys.lastReviewRequestMs,
      DateTime.now().millisecondsSinceEpoch,
    );
    await _inAppReview.requestReview();
  }

  /// Uygulama açılışını sayar; eşiğe ulaşınca değerlendirme ister.
  Future<void> registerAppOpen() async {
    final int count = (_prefs.getInt(PrefKeys.appOpenCount) ?? 0) + 1;
    await _prefs.setInt(PrefKeys.appOpenCount, count);
    if (count >= ReviewConfig.appOpenThreshold) {
      await requestIfAppropriate();
    }
  }
}

// SharedPreferences kaynağı ve tercih anahtarları.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// main() içinde gerçek instance ile override edilir — böylece router
/// redirect'i gibi senkron yerlerden okunabilir.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('main() içinde override edilmeli');
});

/// Tercih anahtarları — string tekrarını önler.
abstract final class PrefKeys {
  static const String onboardingComplete = 'onboarding_complete';
  static const String themeMode = 'theme_mode';
  static const String aiAnalysisUsed = 'ai_analysis_used';
  static const String aiWeekStart = 'ai_week_start';
  static const String swipesUsed = 'swipes_used';
  static const String isPro = 'is_pro';
  static const String proPurchaseMs = 'pro_purchase_ms';
  static const String proProductId = 'pro_product_id';
  static const String trialAnalysisUsed = 'trial_analysis_used';
  static const String aiDailyCount = 'ai_daily_count';
  static const String aiDailyDate = 'ai_daily_date';
  static const String analysisCredits = 'analysis_credits';
  static const String deliveredPackTxIds = 'delivered_pack_tx_ids';
  static const String autoSortEnabled = 'auto_sort_enabled';
  static const String autoSortHintDismissed = 'auto_sort_hint_dismissed';
  static const String appLocale = 'app_locale';
  static const String lastReviewRequestMs = 'last_review_request_ms';
  static const String appOpenCount = 'app_open_count';
  static const String recentSearches = 'recent_searches';
}

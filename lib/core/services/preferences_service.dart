// SharedPreferences sarmalayıcısı: onboarding bayrağı ve tema tercihi.
import 'package:flutter/material.dart';
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
  static const String appLocale = 'app_locale';
}

/// Onboarding tamamlandı bilgisi (router redirect bunu izler).
final onboardingCompleteProvider =
    NotifierProvider<OnboardingCompleteNotifier, bool>(
      OnboardingCompleteNotifier.new,
    );

class OnboardingCompleteNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref
            .read(sharedPreferencesProvider)
            .getBool(PrefKeys.onboardingComplete) ??
        false;
  }

  Future<void> markComplete() async {
    state = true;
    await ref
        .read(sharedPreferencesProvider)
        .setBool(PrefKeys.onboardingComplete, true);
  }

  /// Yalnız debug ayarlar ekranından çağrılır: bayrağı sıfırlar, router
  /// redirect'i otomatik olarak onboarding'e yönlendirir (store ekran
  /// görüntüleri için akışı baştan izlemeyi sağlar).
  Future<void> resetForDebug() async {
    state = false;
    await ref
        .read(sharedPreferencesProvider)
        .setBool(PrefKeys.onboardingComplete, false);
  }
}

/// Kullanıcının tema tercihi (açık default).
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final String? stored = ref
        .read(sharedPreferencesProvider)
        .getString(PrefKeys.themeMode);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      // Ürün kararı: default açık tema (sistem değil).
      orElse: () => ThemeMode.light,
    );
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await ref
        .read(sharedPreferencesProvider)
        .setString(PrefKeys.themeMode, mode.name);
  }
}

/// Pro kullanıcının auto-sort tercihi (default açık). Free'de anlamsız —
/// entitlement kontrolü ayrı yapılır, bu yalnız kullanıcı tercihini tutar.
final autoSortEnabledProvider = NotifierProvider<AutoSortEnabledNotifier, bool>(
  AutoSortEnabledNotifier.new,
);

class AutoSortEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref
            .read(sharedPreferencesProvider)
            .getBool(PrefKeys.autoSortEnabled) ??
        true;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await ref
        .read(sharedPreferencesProvider)
        .setBool(PrefKeys.autoSortEnabled, enabled);
  }
}

/// Kullanıcının uygulama dili tercihi. `null` = sistem dilini takip et.
final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    final String? stored = ref
        .read(sharedPreferencesProvider)
        .getString(PrefKeys.appLocale);
    return stored == null ? null : Locale(stored);
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    final prefs = ref.read(sharedPreferencesProvider);
    if (locale == null) {
      await prefs.remove(PrefKeys.appLocale);
    } else {
      await prefs.setString(PrefKeys.appLocale, locale.languageCode);
    }
  }
}

// Kullanıcının uygulama dili tercihi (null = sistem dili).
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pref_keys.dart';

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

// Otomatik sıralama tercihi ve Kütüphane'deki ipucunun kapatılma bilgisi.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/app_logger.dart';
import 'pref_keys.dart';

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

/// Free kullanıcıya Kütüphane'de gösterilen otomatik sıralama ipucu bir kez
/// kapatılınca bir daha çıkmaz.
final autoSortHintDismissedProvider =
    NotifierProvider<AutoSortHintDismissedNotifier, bool>(
      AutoSortHintDismissedNotifier.new,
    );

class AutoSortHintDismissedNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref
            .read(sharedPreferencesProvider)
            .getBool(PrefKeys.autoSortHintDismissed) ??
        false;
  }

  Future<void> dismiss() async {
    state = true;
    try {
      await ref
          .read(sharedPreferencesProvider)
          .setBool(PrefKeys.autoSortHintDismissed, true);
    } catch (error, stackTrace) {
      // Bu oturumda gizli kalır; kalıcı yazılamadıysa sonraki açılışta döner.
      logError('İpucu kapatma kaydedilemedi', error, stackTrace);
    }
  }
}

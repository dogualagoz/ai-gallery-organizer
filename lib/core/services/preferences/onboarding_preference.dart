// Onboarding tamamlandı bayrağı (router redirect'i izler).
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pref_keys.dart';

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

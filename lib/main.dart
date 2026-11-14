// Uygulama giriş noktası: Firebase + Hive + SharedPreferences başlatılır, ProviderScope kurulur.
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/l10n/l10n_extension.dart';
import 'core/router/app_router.dart';
import 'core/services/hive_service.dart';
import 'core/services/preferences_service.dart';
import 'core/startup/startup_error_app.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/launch_reveal.dart';
import 'features/paywall/providers/purchase_provider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Router redirect'i senkron okuma yaptığı için prefs açılışta yüklenir.
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await _openStorageAndRun(prefs);
}

/// Yerel depolamayı açıp uygulamayı başlatır; açılamazsa kullanıcıya yeniden
/// dene / onaylı sıfırla seçenekleri sunan kurtarma ekranını gösterir
/// ([reset] true ise önce yerel box'lar silinir).
Future<void> _openStorageAndRun(
  SharedPreferences prefs, {
  bool reset = false,
}) async {
  try {
    if (reset) await HiveService.resetAll();
    await HiveService.init();
  } catch (error, stackTrace) {
    debugPrint('Yerel depolama açılamadı: $error\n$stackTrace');
    runApp(
      StartupErrorApp(
        onRetry: () => _openStorageAndRun(prefs),
        onReset: () => _openStorageAndRun(prefs, reset: true),
      ),
    );
    return;
  }
  await _initFirebase();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const SnaplyApp(),
    ),
  );
}

/// Firebase + App Check başlatma (AI analizi için gerekli).
Future<void> _initFirebase() async {
  // options ile plist'e bağımlılık kalmaz.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // App Check: API anahtarının uygulama dışından kötüye kullanımını engeller.
  // Debug'da debug provider (token konsola yazılır, Firebase Console'a eklenir);
  // release'de App Attest, eski cihazlarda DeviceCheck'e düşer.
  try {
    await FirebaseAppCheck.instance.activate(
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
  } catch (error, stackTrace) {
    // Aktivasyon hatası açılışı engellememeli; enforcement kapalıyken istekler yine geçer.
    debugPrint('App Check aktivasyon hatası: $error\n$stackTrace');
  }
}

class SnaplyApp extends ConsumerWidget {
  const SnaplyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Paywall ekranı kapalıyken tamamlanan/restore edilen satın almaları
    // yakalayabilmek için stream dinleyicisini uygulama boyunca canlı tutar.
    // listen (watch değil): durum değişimleri kök ağacı yeniden build etmesin.
    ref.listen(purchaseFlowProvider, (_, _) {});
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      locale: ref.watch(localeProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) =>
          LaunchReveal(child: child ?? const SizedBox.shrink()),
    );
  }
}

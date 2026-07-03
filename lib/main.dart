// Uygulama giriş noktası: Hive + SharedPreferences başlatılır, ProviderScope kurulur.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/l10n/l10n_extension.dart';
import 'core/router/app_router.dart';
import 'core/services/hive_service.dart';
import 'core/services/preferences_service.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Router redirect'i senkron okuma yaptığı için prefs açılışta yüklenir.
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await HiveService.init();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const SnaplyApp(),
    ),
  );
}

class SnaplyApp extends ConsumerWidget {
  const SnaplyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}

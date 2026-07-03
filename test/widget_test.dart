// Uygulama kabuğunun ayağa kalktığını doğrulayan smoke test.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_gallery_organizer/core/services/preferences_service.dart';
import 'package:ai_gallery_organizer/core/theme/app_theme.dart';
import 'package:ai_gallery_organizer/features/settings/settings_screen.dart';
import 'package:ai_gallery_organizer/l10n/app_localizations.dart';

void main() {
  testWidgets('Ayarlar ekranı tema seçenekleriyle açılır', (tester) async {
    // Hive gerektirmeden test edilebilen bir ekran üzerinden smoke test.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      ),
    );

    expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
  });
}

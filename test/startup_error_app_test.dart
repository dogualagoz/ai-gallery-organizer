// StartupErrorApp: yeniden dene doğrudan, sıfırla yalnız onay sonrası çalışır.
import 'package:ai_gallery_organizer/core/startup/startup_error_app.dart';
import 'package:ai_gallery_organizer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<AppLocalizations> pump(
    WidgetTester tester, {
    required Future<void> Function() onRetry,
    required Future<void> Function() onReset,
  }) async {
    await tester.pumpWidget(
      StartupErrorApp(onRetry: onRetry, onReset: onReset),
    );
    await tester.pumpAndSettle();
    return AppLocalizations.of(tester.element(find.byType(Scaffold)));
  }

  testWidgets('Tekrar dene onaysız çalışır', (tester) async {
    int retries = 0;
    int resets = 0;
    final l10n = await pump(
      tester,
      onRetry: () async => retries++,
      onReset: () async => resets++,
    );

    await tester.tap(find.text(l10n.retryAction));
    await tester.pumpAndSettle();

    expect(retries, 1);
    expect(resets, 0);
  });

  testWidgets('Sıfırla onay verilmeden çalışmaz, onayla çalışır', (
    tester,
  ) async {
    int resets = 0;
    final l10n = await pump(
      tester,
      onRetry: () async {},
      onReset: () async => resets++,
    );

    await tester.tap(find.text(l10n.startupErrorReset));
    await tester.pumpAndSettle();
    expect(find.text(l10n.startupErrorResetConfirmTitle), findsOneWidget);
    expect(resets, 0);

    // Onay sayfasındaki kırmızı eylem (ikinci "Sıfırla" etiketi).
    await tester.tap(find.text(l10n.startupErrorReset).last);
    await tester.pumpAndSettle();
    expect(resets, 1);
  });
}

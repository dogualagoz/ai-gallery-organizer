// Ortak bileşen kiti (Pressable, StatusToast, app_dialogs) davranış testleri.
import 'package:ai_gallery_organizer/core/constants/motion_constants.dart';
import 'package:ai_gallery_organizer/core/constants/ui_constants.dart';
import 'package:ai_gallery_organizer/core/theme/app_theme.dart';
import 'package:ai_gallery_organizer/core/widgets/app_dialogs.dart';
import 'package:ai_gallery_organizer/core/widgets/pressable.dart';
import 'package:ai_gallery_organizer/core/widgets/status_toast.dart';
import 'package:ai_gallery_organizer/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testlerin ortak kabuğu: tema + l10n (İngilizce) + tek gövde.
Widget _app(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

/// Butona basınca [action]'ı context ile çalıştıran yardımcı gövde.
Widget _launcher(void Function(BuildContext context) action) {
  return Builder(
    builder: (context) =>
        TextButton(onPressed: () => action(context), child: const Text('open')),
  );
}

void main() {
  group('Pressable', () {
    testWidgets('dokunuş eylemi çalıştırır', (tester) async {
      int taps = 0;
      await tester.pumpWidget(
        _app(
          Pressable(
            onPressed: () => taps++,
            child: const SizedBox(width: 100, height: 60),
          ),
        ),
      );
      await tester.tap(find.byType(Pressable));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('dokunma eşiğinden fazla kayınca eylem çalışmaz', (
      tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(
        _app(
          Pressable(
            onPressed: () => taps++,
            child: const SizedBox(width: 200, height: 60),
          ),
        ),
      );
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(Pressable)),
      );
      await gesture.moveBy(const Offset(60, 0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(taps, 0);
    });

    testWidgets('basılıyken küçülür, bırakınca geri döner', (tester) async {
      await tester.pumpWidget(
        _app(
          Pressable(
            onPressed: () {},
            child: const SizedBox(width: 100, height: 60),
          ),
        ),
      );
      double scale() {
        final Transform transform = tester.widget<Transform>(
          find.descendant(
            of: find.byType(Pressable),
            matching: find.byType(Transform),
          ),
        );
        // Matris köşegeninin x bileşeni (z ölçeği 1 kalır, max ölçek yanıltır).
        return transform.transform.storage[0];
      }

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(Pressable)),
      );
      await tester.pumpAndSettle();
      expect(scale(), lessThan(1));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(scale(), closeTo(1, 1e-3));
    });
    testWidgets('kaydırılabilir içerikte basılı görünüm gecikir', (
      tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(
        _app(
          ListView(
            children: [
              Pressable(
                onPressed: () => taps++,
                child: const SizedBox(height: 60),
              ),
            ],
          ),
        ),
      );
      double scale() => tester
          .widget<Transform>(
            find.descendant(
              of: find.byType(Pressable),
              matching: find.byType(Transform),
            ),
          )
          .transform
          .storage[0];

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(Pressable)),
      );
      await tester.pump(AppMotion.scrollPressDelay ~/ 2);
      expect(scale(), 1);
      await tester.pump(AppMotion.scrollPressDelay);
      await tester.pumpAndSettle();
      expect(scale(), lessThan(1));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(taps, 1);
    });
  });

  group('StatusToast', () {
    testWidgets('görünür ve süre dolunca kalkar', (tester) async {
      await tester.pumpWidget(
        _app(_launcher((context) => showStatusToast(context, 'Saved'))),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsOneWidget);

      await tester.pump(AppToast.duration);
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsNothing);
    });

    testWidgets('yenisi eskisinin yerini alır', (tester) async {
      int count = 0;
      await tester.pumpWidget(
        _app(_launcher((context) => showStatusToast(context, 'T${++count}'))),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('T1'), findsNothing);
      expect(find.text('T2'), findsOneWidget);
      await tester.pump(AppToast.duration);
      await tester.pumpAndSettle();
    });

    testWidgets('aksiyon çalışır ve toast kapanır', (tester) async {
      int undone = 0;
      await tester.pumpWidget(
        _app(
          _launcher(
            (context) => showStatusToast(
              context,
              'Moved',
              actionLabel: 'Undo',
              onAction: () => undone++,
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(undone, 1);
      expect(find.text('Moved'), findsNothing);
    });
  });

  group('app_dialogs', () {
    testWidgets('yıkıcı onay: onay true, iptal false döner', (tester) async {
      final List<bool> results = [];
      await tester.pumpWidget(
        _app(
          _launcher((context) async {
            results.add(
              await showDestructiveConfirm(
                context,
                title: 'Delete?',
                confirmLabel: 'Delete',
              ),
            );
          }),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(results, [true, false]);
    });

    testWidgets('metin girişi: boşken pasif, kırpılmış metni döndürür', (
      tester,
    ) async {
      String? result;
      await tester.pumpWidget(
        _app(
          _launcher((context) async {
            result = await showTextPrompt(
              context,
              title: 'New board',
              confirmLabel: 'Create',
            );
          }),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      CupertinoDialogAction create() => tester.widget<CupertinoDialogAction>(
        find.widgetWithText(CupertinoDialogAction, 'Create'),
      );
      expect(create().onPressed, isNull);

      await tester.enterText(find.byType(CupertinoTextField), '  Trips  ');
      await tester.pump();
      expect(create().onPressed, isNotNull);

      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(result, 'Trips');
    });
  });
}

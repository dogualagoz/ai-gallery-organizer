// Kutlama sahnesi: giriş rota yerleşince başlar, haptik rozetin tepesinde bir
// kez gelir; Reduce Motion'da sahne son haliyle durur, haptik yine bir kez.
import 'package:ai_gallery_organizer/core/theme/app_theme.dart';
import 'package:ai_gallery_organizer/features/analysis/widgets/milestone_celebration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Yakalanan `HapticFeedback.vibrate` çağrıları.
List<Object?> _captureHaptics(WidgetTester tester) {
  final List<Object?> calls = [];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') calls.add(call.arguments);
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return calls;
}

/// Rozetin anlık ölçeği (sahnedeki son Transform.scale).
double _badgeScale(WidgetTester tester) {
  final Transform transform = tester.widget<Transform>(
    find
        .descendant(
          of: find.byType(MilestoneCelebration),
          matching: find.byType(Transform),
        )
        .last,
  );
  // Transform.scale z eksenini 1 bırakır; yatay ölçek okunur.
  return transform.transform.entry(0, 0);
}

Future<NavigatorState> _pumpHost(
  WidgetTester tester, {
  required bool reduceMotion,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: const Scaffold(),
    ),
  );
  return tester.state<NavigatorState>(find.byType(Navigator));
}

void _pushScene(NavigatorState navigator) {
  navigator.push(
    MaterialPageRoute<void>(
      builder: (_) =>
          const Scaffold(body: Center(child: MilestoneCelebration())),
    ),
  );
}

void main() {
  testWidgets('giriş rota yerleşince başlar, haptik tepede bir kez', (
    tester,
  ) async {
    final List<Object?> haptics = _captureHaptics(tester);
    final NavigatorState navigator = await _pumpHost(
      tester,
      reduceMotion: false,
    );
    _pushScene(navigator);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Rota hâlâ kayıyor: rozet görünmez, haptik yok.
    expect(_badgeScale(tester), 0);
    expect(haptics, isEmpty);

    // Geçiş biter, yay başlar; tepeyi geçene kadar ilerlet.
    await tester.pump(const Duration(milliseconds: 400));
    double peak = 0;
    for (int i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final double scale = _badgeScale(tester);
      if (scale > peak) peak = scale;
    }

    expect(peak, greaterThan(1), reason: 'kutlama yayı hafifçe taşar');
    expect(haptics, hasLength(1));
  });

  testWidgets('Reduce Motion: rozet hemen tam boy, haptik bir kez', (
    tester,
  ) async {
    final List<Object?> haptics = _captureHaptics(tester);
    final NavigatorState navigator = await _pumpHost(
      tester,
      reduceMotion: true,
    );
    _pushScene(navigator);
    await tester.pumpAndSettle();

    expect(_badgeScale(tester), 1);
    expect(haptics, hasLength(1));
    // Döngü yok: sahne durgun, bekleyen kare kalmaz.
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}

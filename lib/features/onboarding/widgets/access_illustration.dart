// Onboarding 3. sayfa illüstrasyonu: kategori ikonlu kutucukların
// sırayla belirdiği 3x3 ızgara — "kütüphanen düzene giriyor" hissi.
import 'package:flutter/material.dart';

import '../../../core/constants/app_curves.dart';
import '../../../core/constants/feature/onboarding_constants.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/category_labels.dart';
import '../../../core/models/screenshot_category.dart';
import 'illustration_loop.dart';

class AccessIllustration extends StatefulWidget {
  const AccessIllustration({super.key});

  @override
  State<AccessIllustration> createState() => _AccessIllustrationState();
}

class _AccessIllustrationState extends State<AccessIllustration>
    with SingleTickerProviderStateMixin, IllustrationLoop<AccessIllustration> {
  late final AnimationController _controller;

  // Kutucuklar gerçek sistem kategorilerinin ikonlarını taşır.
  static const List<ScreenshotCategory> _categories = [
    ScreenshotCategory.lockScreen,
    ScreenshotCategory.messages,
    ScreenshotCategory.shopping,
    ScreenshotCategory.notesPasswords,
    ScreenshotCategory.receipts,
    ScreenshotCategory.other,
    ScreenshotCategory.social,
    ScreenshotCategory.qrCodes,
    ScreenshotCategory.tickets,
  ];

  @override
  AnimationController get controller => _controller;

  /// Hareket azaltıldığında ızgara doğrudan tamamlanmış görünür.
  @override
  double get stillValue => 1;

  // Sayfa görünür olduğunda tek seferlik giriş animasyonu oynar.
  @override
  void play() => _controller.forward();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AccessArt.loop);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Center(
      child: SizedBox(
        width:
            AccessArt.columns * AccessArt.tileSize +
            (AccessArt.columns - 1) * AppSpacing.sm,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (int i = 0; i < _categories.length; i++)
                  _buildTile(i, scheme),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTile(int index, ColorScheme scheme) {
    // Kutucuklar soldan sağa, yukarıdan aşağıya sırayla belirir. Eğri
    // doğrudan uygulanır: her karede CurvedAnimation kurmak dinleyici sızdırır.
    final double t = Interval(
      index * AccessArt.staggerStart,
      AccessArt.firstEnd + index * AccessArt.staggerEnd,
      curve: AppCurves.settle,
    ).transform(_controller.value);

    return Transform.scale(
      scale: AccessArt.enterScale + (1 - AccessArt.enterScale) * t,
      child: Opacity(
        opacity: t.clamp(0, 1),
        child: Container(
          width: AccessArt.tileSize,
          height: AccessArt.tileSize,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: scheme.outline),
          ),
          child: Icon(
            _categories[index].icon,
            // Her satırın ortası aksan renginde.
            color: index % AccessArt.columns == 1
                ? scheme.primary
                : scheme.onSurfaceVariant,
            size: AccessArt.tileIcon,
          ),
        ),
      ),
    );
  }
}

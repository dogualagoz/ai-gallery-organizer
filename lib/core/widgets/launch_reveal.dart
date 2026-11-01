// Native launch screen'den ilk ekrana kısa çapraz geçiş (logo/ses yok — HIG).
import 'package:flutter/material.dart';

import '../constants/motion_constants.dart';
import '../theme/app_theme.dart';

/// Uygulamanın ilk karesini launch screen ile aynı zeminden kısa bir
/// opaklık geçişiyle açar. `MaterialApp.builder` içinde navigator'ı sarar.
/// Zemin geçiş bitince kalkar: iOS sheet'lerinin arkasında siyah zemin
/// görünmeli. Navigator Stack'te aynı sırada kalır, yeniden kurulmaz.
class LaunchReveal extends StatefulWidget {
  const LaunchReveal({super.key, required this.child});

  final Widget child;

  @override
  State<LaunchReveal> createState() => _LaunchRevealState();
}

class _LaunchRevealState extends State<LaunchReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: AppMotion.launchReveal,
  )..forward().whenComplete(_onRevealed);

  bool _revealed = false;

  static const ValueKey<String> _childKey = ValueKey<String>('launchChild');

  late final CurvedAnimation _opacity = CurvedAnimation(
    parent: _fade,
    curve: Curves.easeOut,
  );

  void _onRevealed() {
    if (mounted) setState(() => _revealed = true);
  }

  @override
  void dispose() {
    _opacity.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Native launch screen uygulama tercihini bilemez; varsayılan tema
        // açık olduğu için storyboard açık grouped background'dur. Zemin de
        // seçili temadan değil açık paletten gelir ki ilk kare birebir tutsun.
        if (!_revealed)
          ColoredBox(color: AppTheme.light.colorScheme.surfaceContainer),
        // Anahtar: zemin listeden çıkınca navigator elementi (go_router ve
        // sekme stack'leri) yeniden kurulmasın.
        FadeTransition(key: _childKey, opacity: _opacity, child: widget.child),
      ],
    );
  }
}

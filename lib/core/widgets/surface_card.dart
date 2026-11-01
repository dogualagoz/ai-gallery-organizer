// Gruplu zemin üstündeki standart yüzey kartı (iOS inset grouped hücresi
// gibi): kart rengi, büyük köşe; öneri/eylem kartları için aksan tonu.
import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.tinted = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// true ise zemin aksan rengiyle hafifçe tonlanır.
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tinted
            ? Color.alphaBlend(
                scheme.primary.withValues(alpha: AppOpacities.accentTint),
                scheme.surface,
              )
            : scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

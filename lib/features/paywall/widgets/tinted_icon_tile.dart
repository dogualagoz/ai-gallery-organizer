// Paywall satırlarının ortak ikon karosu: aksan tonlu zemin üstünde glif.
import 'package:flutter/material.dart';

import '../../../core/constants/ui_constants.dart';

/// Dekoratif ikon karosu; yanındaki metin anlamı taşıdığı için VoiceOver'a
/// okunmaz. [circle] true ise yuvarlak (zaman çizelgesi adımları).
class TintedIconTile extends StatelessWidget {
  const TintedIconTile({super.key, required this.icon, this.circle = false});

  final IconData icon;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        width: AppPaywall.iconTile,
        height: AppPaywall.iconTile,
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: AppOpacities.iconTileTint),
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, size: AppPaywall.iconGlyph, color: scheme.primary),
      ),
    );
  }
}

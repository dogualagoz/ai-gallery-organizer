// Pro üyeliği gösteren kompakt kapsül: Kütüphane büyük başlığının yanında.
import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../constants/ui_constants.dart';
import '../l10n/l10n_extension.dart';

/// Aksan dolgulu küçük "PRO" kapsülü. Dolgu ve metin rengi tema
/// rollerinden gelir (onPrimary/primary), küçük metinde de 4.5:1 kontrast
/// sağlar.
class ProBadge extends StatelessWidget {
  const ProBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs / 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.pro,
              size: AppSizes.proBadgeGlyph,
              color: scheme.onPrimary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              context.l10n.proBadgeLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

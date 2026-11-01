// Kapsül çip: etiket önerileri ve kategori filtreleri. Seçiliyken aksan
// dolgulu; görünür kapsül küçük kalırken dokunma alanı 44pt'ye uzanır.
import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';
import 'pressable.dart';

/// Basılabilir kapsül çip.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.selected = false,
    this.background,
    this.semanticLabel,
  });

  final String label;

  /// null ise pasif bilgi kapsülü: basış geri bildirimi olmaz.
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Filtre çipinde seçili durum (aksan dolgu, VoiceOver'da "seçili").
  final bool selected;

  /// Seçili değilken dolgu; verilmezse kart üstü ton
  /// (`surfaceContainerHigh`). Gruplu zemin üstünde `surface` verilir.
  final Color? background;

  /// VoiceOver etiketi; verilmezse [label] okunur.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color fill = selected
        ? scheme.primary
        : background ?? scheme.surfaceContainerHigh;
    final Color foreground = selected ? scheme.onPrimary : scheme.onSurface;
    final IconData? glyph = icon;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      child: Semantics(
        selected: selected,
        child: Padding(
          // Saydam pay: kapsül küçük görünür, dokunma alanı 44pt olur.
          padding: const EdgeInsets.symmetric(vertical: AppSizes.chipHitInset),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.chipPaddingH,
                vertical: AppSizes.chipPaddingV,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (glyph != null) ...[
                    Icon(glyph, size: AppSizes.chipIcon, color: foreground),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: foreground),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

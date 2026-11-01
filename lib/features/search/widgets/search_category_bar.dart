// Arama filtre çubuğu: sonuçlarda geçen kategoriler yatay kayan çipler
// olarak, Kütüphane'deki sırayla; seçili çip aramayı o kategoriye daraltır.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/category_labels.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/models/screenshot_category.dart';
import '../../../core/services/category_names_service.dart';
import '../../../core/services/category_order_service.dart';
import '../../../core/widgets/app_chip.dart';

/// Kategori filtre çipleri; seçili çipe yeniden dokunmak filtreyi kaldırır.
class SearchCategoryBar extends ConsumerWidget {
  const SearchCategoryBar({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final Set<ScreenshotCategory> categories;
  final ScreenshotCategory? selected;
  final ValueChanged<ScreenshotCategory> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final Map<int, String> names = ref.watch(categoryNamesProvider);
    ref.watch(categoryOrderProvider);
    final List<ScreenshotCategory> ordered = ref
        .read(categoryOrderProvider.notifier)
        .sortVisible(categories.toList());
    final Color background = Theme.of(context).colorScheme.surface;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        spacing: AppSpacing.sm,
        children: [
          for (final ScreenshotCategory category in ordered)
            AppChip(
              icon: category.icon,
              label: category.displayName(l10n, names),
              selected: category == selected,
              background: background,
              onPressed: () => onSelected(category),
            ),
        ],
      ),
    );
  }
}

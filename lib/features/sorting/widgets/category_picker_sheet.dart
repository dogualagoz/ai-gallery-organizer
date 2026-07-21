// Swipe ekranında "yukarı" atamasının hedef kategorisini seçtiren bottom sheet.
// Tüm kategorileri (ikon + görünen ad) listeler; `other` fallback kovası hariç.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/category_labels.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/models/screenshot_category.dart';
import '../../../core/services/category_names_service.dart';

/// Kategori seçimini bottom sheet olarak açar; seçilen kategoriyi döndürür.
Future<ScreenshotCategory?> showCategoryPickerSheet(
  BuildContext context, {
  ScreenshotCategory? selected,
}) {
  return showModalBottomSheet<ScreenshotCategory>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _CategoryPickerSheet(selected: selected),
  );
}

class _CategoryPickerSheet extends ConsumerWidget {
  const _CategoryPickerSheet({this.selected});

  final ScreenshotCategory? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Map<int, String> overrides = ref.watch(categoryNamesProvider);
    final List<ScreenshotCategory> categories = [
      for (final category in ScreenshotCategory.values)
        if (category != ScreenshotCategory.other) category,
    ];

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.sortCategoryPickerTitle,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final ScreenshotCategory category = categories[index];
                final bool isSelected = category == selected;
                return ListTile(
                  leading: Icon(
                    category.icon,
                    color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                  title: Text(category.displayName(l10n, overrides)),
                  trailing: isSelected
                      ? Icon(Icons.check_rounded, color: scheme.primary)
                      : null,
                  onTap: () => Navigator.of(context).pop(category),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

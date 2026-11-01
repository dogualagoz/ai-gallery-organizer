// Temizle'de yukarı kaydırmanın hedef kategorisini seçtiren sheet: sistem
// kategorileri Kütüphane'deki sırayla, "Diğer" yedek kovası hariç.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/l10n/category_labels.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/models/screenshot_category.dart';
import '../../../core/services/category_names_service.dart';
import '../../../core/services/category_order_service.dart';
import '../../../core/widgets/app_nav_scaffold.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/grouped_section.dart';

/// Hedef kategoriyi seçtirir; iptalde null.
Future<ScreenshotCategory?> showCategoryPickerSheet(
  BuildContext context, {
  required ScreenshotCategory selected,
}) {
  return showAppSheet<ScreenshotCategory>(
    context,
    builder: (context, controller) =>
        _CategoryPickerSheet(controller: controller, selected: selected),
  );
}

class _CategoryPickerSheet extends ConsumerWidget {
  const _CategoryPickerSheet({
    required this.controller,
    required this.selected,
  });

  final ScrollController controller;
  final ScreenshotCategory selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Map<int, String> names = ref.watch(categoryNamesProvider);
    ref.watch(categoryOrderProvider);
    final List<ScreenshotCategory> categories = ref
        .read(categoryOrderProvider.notifier)
        .sortVisible([
          for (final ScreenshotCategory category in ScreenshotCategory.values)
            if (category != ScreenshotCategory.other) category,
        ]);

    return AppNavScaffold(
      title: l10n.sortCategoryPickerTitle,
      controller: controller,
      leading: NavBarButton.text(
        label: l10n.cancelAction,
        onPressed: () => Navigator.of(context).pop(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: GroupedSection(
            footer: l10n.cleanTargetFooter,
            children: [
              for (final ScreenshotCategory category in categories)
                GroupedRow(
                  icon: category.icon,
                  title: category.displayName(l10n, names),
                  showChevron: false,
                  trailing: category == selected
                      ? Icon(AppIcons.check, color: scheme.primary)
                      : null,
                  onTap: () => Navigator.of(context).pop(category),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

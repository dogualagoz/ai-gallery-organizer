// Boş sorguda gösterilen öneriler: son aramalar (tek dokunuşla yeniden
// aranır, toplu temizlenir) ve galeride en sık geçen etiketler.
import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/grouped_section.dart';
import '../../../core/widgets/section_header.dart';

/// Son aramalar bölümü: başlıkta "Temizle", her satır o sorguyu uygular.
class SearchRecents extends StatelessWidget {
  const SearchRecents({
    super.key,
    required this.recents,
    required this.onSelect,
    required this.onClear,
  });

  final List<String> recents;
  final ValueChanged<String> onSelect;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: SectionHeader(
            title: l10n.searchRecentTitle,
            actionLabel: l10n.searchClearRecent,
            onAction: onClear,
          ),
        ),
        GroupedSection(
          // Kart kenarı bölüm başlığıyla aynı hizada.
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          children: [
            for (final String query in recents)
              GroupedRow(
                icon: AppIcons.schedule,
                title: query,
                showChevron: false,
                onTap: () => onSelect(query),
              ),
          ],
        ),
      ],
    );
  }
}

/// Sık etiketler bölümü: dokunulan etiket sorgu olur.
class SearchTagSuggestions extends StatelessWidget {
  const SearchTagSuggestions({
    super.key,
    required this.tags,
    required this.onSelect,
  });

  final List<String> tags;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final Color background = Theme.of(context).colorScheme.surface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: l10n.searchTagsTitle),
          // Çiplerin saydam dokunma payı satır aralığını da verir.
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final String tag in tags)
                AppChip(
                  label: tag,
                  background: background,
                  semanticLabel: l10n.searchTagLabel(tag),
                  onPressed: () => onSelect(tag),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

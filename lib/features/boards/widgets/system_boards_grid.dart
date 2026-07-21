// Sistem kategorileri (içerik içerenler) ızgarası — Home ekranında kullanılır.
import 'package:flutter/material.dart';

import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/category_labels.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/models/screenshot_category.dart';
import '../../../core/models/screenshot_entry.dart';
import '../../../core/widgets/fade_in_up.dart';
import '../../gallery/data/screenshot_repository.dart';
import '../board_detail_screen.dart';
import 'board_covers.dart';
import 'board_tile.dart';

/// Kademeli giriş için kartlar arası gecikme.
const Duration boardStaggerStep = Duration(milliseconds: 40);

/// Kapak thumbnail'lı kartlar için kart oranı.
const double boardCardAspectRatio = 1.05;

/// [categories] listesindeki (genelde içerik>0 olan) sistem kategorileri ızgarası.
class SystemBoardsGrid extends StatelessWidget {
  const SystemBoardsGrid({
    super.key,
    required this.categories,
    required this.entries,
    required this.repo,
  });

  final List<ScreenshotCategory> categories;
  final List<ScreenshotEntry> entries;
  final ScreenshotRepository repo;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return GridView.builder(
      shrinkWrap: true,
      // shrinkWrap grid, MediaQuery safe-area padding'ini örtük olarak
      // devralır (SliverAppBar'lı gövdede üstte boşluk yaratır) — sıfırla.
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: boardCardAspectRatio,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final ScreenshotCategory category = categories[index];
        final List<ScreenshotEntry> categoryEntries = entries
            .where((entry) => entry.category == category)
            .toList();
        return FadeInUp(
          delay: boardStaggerStep * index,
          child: BoardTile(
            icon: category.icon,
            label: category.label(l10n),
            count: categoryEntries.length,
            covers: boardCovers(repo, categoryEntries),
            openBuilder: (context) =>
                BoardDetailScreen.category(category: category),
          ),
        );
      },
    );
  }
}

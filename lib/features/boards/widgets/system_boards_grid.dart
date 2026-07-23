// Sistem kategorileri (içerik içerenler) ızgarası — Home ekranında kullanılır.
// Düzenleme modunda kategoriler sürüklenerek yeniden sıralanabilir (silme/ad yok).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/category_labels.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/models/screenshot_category.dart';
import '../../../core/models/screenshot_entry.dart';
import '../../../core/services/category_order_service.dart';
import '../../../core/widgets/fade_in_up.dart';
import '../../../core/widgets/reorderable_tile_grid.dart';
import '../../analysis/widgets/category_target_scope.dart';
import '../../gallery/data/screenshot_repository.dart';
import '../board_detail_screen.dart';
import '../providers/board_provider.dart';
import 'board_covers.dart';
import 'board_edit_actions.dart';
import 'board_tile.dart';
import 'long_press_edit_wrapper.dart';

/// Kademeli giriş için kartlar arası gecikme.
const Duration boardStaggerStep = Duration(milliseconds: 40);

/// Kapak thumbnail'lı kartlar için kart oranı.
const double boardCardAspectRatio = 1.05;

/// [categories] listesindeki (genelde içerik>0 olan) sistem kategorileri ızgarası.
/// Liste çağıran tarafça [categoryOrderProvider] ile sıralanmış gelir.
class SystemBoardsGrid extends ConsumerWidget {
  const SystemBoardsGrid({
    super.key,
    required this.categories,
    required this.entries,
    required this.repo,
    this.categoryNames = const {},
  });

  final List<ScreenshotCategory> categories;
  final List<ScreenshotEntry> entries;
  final ScreenshotRepository repo;

  /// Kategori index → kullanıcı özel adı (yoksa çeviri etiketi kullanılır).
  final Map<int, String> categoryNames;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final bool editing = ref.watch(boardsEditModeProvider);

    return ReorderableTileGrid(
      itemCount: categories.length,
      editing: editing,
      crossAxisCount: 2,
      childAspectRatio: boardCardAspectRatio,
      keyBuilder: (index) => ValueKey<int>(categories[index].index),
      onReorder: (from, to) {
        final List<ScreenshotCategory> reordered = [...categories];
        final ScreenshotCategory moved = reordered.removeAt(from);
        reordered.insert(to.clamp(0, reordered.length), moved);
        ref.read(categoryOrderProvider.notifier).reorderVisible(reordered);
      },
      itemBuilder: (context, index) {
        final ScreenshotCategory category = categories[index];
        final List<ScreenshotEntry> categoryEntries = entries
            .where((entry) => entry.category == category)
            .toList();
        final label = category.displayName(l10n, categoryNames);
        final covers = boardCovers(repo, categoryEntries);

        if (editing) {
          return GestureDetector(
            onTap: () => showBoardEditActions(context, ref, category: category),
            child: BoardTileStatic(
              icon: category.icon,
              label: label,
              count: categoryEntries.length,
              covers: covers,
            ),
          );
        }

        // Uçan fotoğrafların ineceği hedef olarak kategori karosunu kaydeder.
        return KeyedSubtree(
          key: CategoryTargetScope.of(context)?.keyFor(category),
          child: LongPressEditWrapper(
            child: FadeInUp(
              delay: boardStaggerStep * index,
              child: BoardTile(
                icon: category.icon,
                label: label,
                count: categoryEntries.length,
                covers: covers,
                openBuilder: (context) =>
                    BoardDetailScreen.category(category: category),
              ),
            ),
          ),
        );
      },
    );
  }
}

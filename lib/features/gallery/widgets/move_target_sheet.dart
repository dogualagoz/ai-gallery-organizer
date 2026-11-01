// Taşıma hedefi seçici: kullanıcı panoları ve sistem kategorileri, alttan
// açılan sheet'te iOS gruplu liste olarak (Kütüphane'deki sırayla).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/l10n/category_labels.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/models/board.dart';
import '../../../core/models/screenshot_category.dart';
import '../../../core/services/category_names_service.dart';
import '../../../core/services/category_order_service.dart';
import '../../../core/widgets/app_nav_scaffold.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/grouped_section.dart';
import '../../boards/providers/board_provider.dart';

/// Seçilen taşıma hedefi: bir sistem kategorisi ya da bir kullanıcı panosu.
class MoveTarget {
  const MoveTarget.category(ScreenshotCategory this.category, this.label)
    : boardId = null;
  const MoveTarget.board(String this.boardId, this.label) : category = null;

  final ScreenshotCategory? category;
  final String? boardId;

  /// Bildirimde görünen hedef adı.
  final String label;
}

/// Hedef seçtirir; iptalde null. Ekran görüntüsünün şu anki kategorisi/panosu
/// ([currentCategory], [currentBoardId]) listede gösterilmez.
Future<MoveTarget?> showMoveTargetSheet(
  BuildContext context, {
  ScreenshotCategory? currentCategory,
  String? currentBoardId,
}) {
  return showAppSheet<MoveTarget>(
    context,
    builder: (context, controller) => _MoveTargetSheet(
      controller: controller,
      currentCategory: currentCategory,
      currentBoardId: currentBoardId,
    ),
  );
}

class _MoveTargetSheet extends ConsumerWidget {
  const _MoveTargetSheet({
    required this.controller,
    required this.currentCategory,
    required this.currentBoardId,
  });

  final ScrollController controller;
  final ScreenshotCategory? currentCategory;
  final String? currentBoardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final Map<int, String> names = ref.watch(categoryNamesProvider);
    ref.watch(categoryOrderProvider);
    final List<ScreenshotCategory> categories = ref
        .read(categoryOrderProvider.notifier)
        .sortVisible([
          for (final ScreenshotCategory category in ScreenshotCategory.values)
            if (category != currentCategory) category,
        ]);
    final List<Board> boards = [
      for (final Board board in ref.watch(boardsProvider).value ?? const [])
        if (board.id != currentBoardId) board,
    ];

    void choose(MoveTarget target) => Navigator.of(context).pop(target);

    return AppNavScaffold(
      title: l10n.moveSheetTitle,
      controller: controller,
      leading: NavBarButton.text(
        label: l10n.cancelAction,
        onPressed: () => Navigator.of(context).pop(),
      ),
      slivers: [
        if (boards.isNotEmpty)
          SliverToBoxAdapter(
            child: GroupedSection(
              header: l10n.moveSectionBoards,
              children: [
                for (final Board board in boards)
                  GroupedRow(
                    icon: AppIcons.board,
                    title: board.name,
                    showChevron: false,
                    onTap: () => choose(MoveTarget.board(board.id, board.name)),
                  ),
              ],
            ),
          ),
        SliverToBoxAdapter(
          child: GroupedSection(
            header: l10n.moveSectionCategories,
            children: [
              for (final ScreenshotCategory category in categories)
                GroupedRow(
                  icon: category.icon,
                  title: category.displayName(l10n, names),
                  showChevron: false,
                  onTap: () => choose(
                    MoveTarget.category(
                      category,
                      category.displayName(l10n, names),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

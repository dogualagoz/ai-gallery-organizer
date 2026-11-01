// Kullanıcı panoları ızgarası + sonda "Yeni pano" kartı — Kütüphane'de
// kullanılır. Davranış sistem kategorileriyle aynı: dokun → aç, uzun bas →
// bağlam menüsü; düzenleme modunda sürükle-sırala ve yönetim sayfası.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/models/board.dart';
import '../../../core/models/screenshot_entry.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/reorderable_tile_grid.dart';
import '../../../core/widgets/surface_card.dart';
import '../../gallery/data/screenshot_repository.dart';
import '../providers/board_provider.dart';
import 'board_context_menu.dart';
import 'board_covers.dart';
import 'board_edit_actions.dart';
import 'board_tile.dart';

/// Kullanıcı panoları + sonuna eklenen "yeni pano" kartı.
class CustomBoardsGrid extends ConsumerWidget {
  const CustomBoardsGrid({
    super.key,
    required this.boards,
    required this.entries,
    required this.repo,
    required this.canCreate,
  });

  final List<Board> boards;
  final List<ScreenshotEntry> entries;
  final ScreenshotRepository repo;
  final bool canCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool editing = ref.watch(boardsEditModeProvider);

    return ReorderableTileGrid(
      itemCount: boards.length,
      editing: editing,
      keyBuilder: (index) => ValueKey<String>(boards[index].id),
      // Düzenleme modunda "yeni pano" kartı gizlenir (yalnız sıralama).
      trailing: editing ? null : _NewBoardTile(canCreate: canCreate),
      onReorder: (from, to) {
        final List<String> ids = boards.map((b) => b.id).toList();
        final String moved = ids.removeAt(from);
        ids.insert(to.clamp(0, ids.length), moved);
        ref.read(boardsProvider.notifier).reorder(ids);
      },
      itemBuilder: (context, index) {
        final Board board = boards[index];
        final List<ScreenshotEntry> boardEntries = entries
            .where((entry) => entry.boardId == board.id)
            .toList();
        final Widget tile = BoardTile(
          icon: AppIcons.board,
          label: board.name,
          count: boardEntries.length,
          covers: boardCovers(repo, boardEntries),
          onPressed: editing
              ? () => showBoardEditActions(context, ref, board: board)
              : () => context.push(AppRoutes.board(board.id)),
        );
        if (editing) return tile;
        return BoardContextMenu(
          board: board,
          isEmpty: boardEntries.isEmpty,
          child: tile,
        );
      },
    );
  }
}

/// Yeni pano kartı; Pro değilse kilitli görünür ve paywall'a yönlendirir.
class _NewBoardTile extends ConsumerWidget {
  const _NewBoardTile({required this.canCreate});

  final bool canCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Pressable(
      onPressed: () => canCreate
          ? _showCreateDialog(context, ref)
          : context.push(AppRoutes.paywall),
      child: SurfaceCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              canCreate ? AppIcons.add : AppIcons.lock,
              size: AppSizes.statusIcon,
              color: scheme.primary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              canCreate ? l10n.boardsNewBoardAction : l10n.boardsLimitTitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: canCreate ? scheme.primary : scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final String? name = await showTextPrompt(
      context,
      title: l10n.boardsNewBoardDialogTitle,
      confirmLabel: l10n.boardsCreateAction,
      placeholder: l10n.boardsNewBoardHint,
    );
    if (name == null || !context.mounted) return;
    await ref.read(boardsProvider.notifier).create(name);
  }
}

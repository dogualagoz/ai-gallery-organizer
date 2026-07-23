// Kullanıcı board'ları ızgarası + yeni board kartı — Home ekranında kullanılır.
// Düzenleme modunda: sürükle-sırala + karo köşesinden silme/yeniden adlandırma.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/models/board.dart';
import '../../../core/models/screenshot_entry.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/confirm_sheet.dart';
import '../../../core/widgets/fade_in_up.dart';
import '../../../core/widgets/reorderable_tile_grid.dart';
import '../../gallery/data/screenshot_repository.dart';
import '../board_detail_screen.dart';
import '../providers/board_provider.dart';
import 'board_covers.dart';
import 'board_name_dialog.dart';
import 'board_tile.dart';
import 'long_press_edit_wrapper.dart';
import 'system_boards_grid.dart' show boardStaggerStep, boardCardAspectRatio;

/// Kullanıcı board'ları + sonuna eklenen "yeni pano" kartı.
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
      crossAxisCount: 2,
      childAspectRatio: boardCardAspectRatio,
      keyBuilder: (index) => ValueKey<String>(boards[index].id),
      // Düzenleme modunda "yeni pano" kartı gizlenir (iOS jiggle davranışı).
      trailing: editing
          ? null
          : FadeInUp(
              delay: boardStaggerStep * boards.length,
              child: _NewBoardTile(canCreate: canCreate),
            ),
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
        final covers = boardCovers(repo, boardEntries);

        if (editing) {
          return _EditableBoardTile(
            board: board,
            count: boardEntries.length,
            covers: covers,
          );
        }

        return LongPressEditWrapper(
          child: FadeInUp(
            delay: boardStaggerStep * index,
            child: BoardTile(
              icon: Icons.folder_outlined,
              label: board.name,
              count: boardEntries.length,
              covers: covers,
              openBuilder: (context) =>
                  BoardDetailScreen.custom(boardId: board.id),
            ),
          ),
        );
      },
    );
  }
}

/// Düzenleme modundaki özel pano karosu: sabit kart + köşe aksiyon rozetleri.
class _EditableBoardTile extends ConsumerWidget {
  const _EditableBoardTile({
    required this.board,
    required this.count,
    required this.covers,
  });

  final Board board;
  final int count;
  final List<AssetEntity> covers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        BoardTileStatic(
          icon: Icons.folder_outlined,
          label: board.name,
          count: count,
          covers: covers,
        ),
        Positioned(
          top: 4,
          left: 4,
          child: _TileBadge(
            icon: Icons.close,
            destructive: true,
            onTap: () => _confirmDelete(context, ref),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: _TileBadge(
            icon: Icons.edit_outlined,
            destructive: false,
            onTap: () => _rename(context, ref),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final bool confirmed = await showConfirmSheet(
      context,
      title: l10n.boardsDeleteConfirmTitle,
      body: l10n.boardsDeleteConfirmBody,
      confirmLabel: l10n.boardsDeleteAction,
      icon: Icons.delete_outline,
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(boardsProvider.notifier).delete(board.id);
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final String? name = await showDialog<String>(
      context: context,
      builder: (_) => BoardNameDialog(
        title: l10n.boardsRenameDialogTitle,
        confirmLabel: l10n.boardsRenameAction,
        initialValue: board.name,
      ),
    );
    if (name == null || name.isEmpty) return;
    await ref.read(boardsProvider.notifier).rename(board.id, name);
  }
}

/// Karo köşesindeki dairesel aksiyon rozeti (sil / yeniden adlandır).
class _TileBadge extends StatelessWidget {
  const _TileBadge({
    required this.icon,
    required this.destructive,
    required this.onTap,
  });

  final IconData icon;
  final bool destructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color bg = destructive ? scheme.error : scheme.primary;
    final Color fg = destructive ? scheme.onError : scheme.onPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: scheme.surface, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(icon, size: 15, color: fg),
      ),
    );
  }
}

/// Yeni board oluşturma kartı; Pro değilse kilitli görünür ve paywall'a yönlendirir.
class _NewBoardTile extends ConsumerWidget {
  const _NewBoardTile({required this.canCreate});

  final bool canCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => canCreate
          ? _showCreateDialog(context, ref)
          : context.push(AppRoutes.paywall),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outline),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  canCreate ? Icons.add : Icons.lock_outline,
                  size: 20,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                canCreate ? l10n.boardsNewBoardAction : l10n.boardsLimitTitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final String? name = await showDialog<String>(
      context: context,
      builder: (_) => BoardNameDialog(
        title: l10n.boardsNewBoardDialogTitle,
        confirmLabel: l10n.boardsCreateAction,
      ),
    );
    if (name == null || name.isEmpty) return;
    await ref.read(boardsProvider.notifier).create(name);
  }
}

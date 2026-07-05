// Kullanıcı board'ları ızgarası + yeni board kartı — Home ekranında kullanılır.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/models/board.dart';
import '../../../core/models/screenshot_entry.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/fade_in_up.dart';
import '../../gallery/data/screenshot_repository.dart';
import '../board_detail_screen.dart';
import '../providers/board_provider.dart';
import 'board_covers.dart';
import 'board_name_dialog.dart';
import 'board_tile.dart';
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: boardCardAspectRatio,
      ),
      itemCount: boards.length + 1,
      itemBuilder: (context, index) {
        if (index == boards.length) {
          return FadeInUp(
            delay: boardStaggerStep * index,
            child: _NewBoardTile(canCreate: canCreate),
          );
        }
        final Board board = boards[index];
        final List<ScreenshotEntry> boardEntries = entries
            .where((entry) => entry.boardId == board.id)
            .toList();
        return FadeInUp(
          delay: boardStaggerStep * index,
          child: BoardTile(
            icon: Icons.folder_outlined,
            label: board.name,
            count: boardEntries.length,
            covers: boardCovers(repo, boardEntries),
            openBuilder: (context) =>
                BoardDetailScreen.custom(boardId: board.id),
          ),
        );
      },
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

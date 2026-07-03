// Tek board/kategori detayı: filtrelenmiş screenshot ızgarası + (özel board'da) yönetim aksiyonları.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/ui_constants.dart';
import '../../core/l10n/category_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/board.dart';
import '../../core/models/screenshot_category.dart';
import '../../core/models/screenshot_entry.dart';
import '../../core/widgets/screenshot_results_grid.dart';
import '../gallery/providers/gallery_provider.dart';
import 'providers/board_provider.dart';
import 'widgets/board_name_dialog.dart';

class BoardDetailScreen extends ConsumerWidget {
  const BoardDetailScreen.category({super.key, required this.category})
    : boardId = null;

  const BoardDetailScreen.custom({super.key, required this.boardId})
    : category = null;

  final ScreenshotCategory? category;
  final String? boardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final List<ScreenshotEntry> entries =
        ref.watch(galleryProvider).value ?? const [];

    final List<ScreenshotEntry> filtered = category != null
        ? entries.where((entry) => entry.category == category).toList()
        : entries.where((entry) => entry.boardId == boardId).toList();

    final Board? board = boardId == null
        ? null
        : ref.watch(boardsProvider).value?.firstWhereOrNull(
            (b) => b.id == boardId,
          );

    final String title = category != null
        ? category!.label(l10n)
        : (board?.name ?? l10n.boardsTitle);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (boardId != null && board != null)
            IconButton(
              tooltip: l10n.boardsRenameAction,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showRenameDialog(context, ref, board),
            ),
          if (boardId != null)
            IconButton(
              tooltip: l10n.boardsDeleteAction,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showDeleteConfirm(context, ref, boardId!),
            ),
        ],
      ),
      body: filtered.isEmpty
          ? _EmptyBoard(text: l10n.boardDetailEmpty)
          : ScreenshotResultsGrid(entries: filtered),
    );
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    Board board,
  ) async {
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

  Future<void> _showDeleteConfirm(
    BuildContext context,
    WidgetRef ref,
    String boardId,
  ) async {
    final l10n = context.l10n;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.boardsDeleteConfirmTitle),
        content: Text(l10n.boardsDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.boardsDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(boardsProvider.notifier).delete(boardId);
    if (context.mounted) Navigator.of(context).pop();
  }
}

extension _FirstWhereOrNull<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final T element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

/// Board/kategori boşken gösterilen sade durum.
class _EmptyBoard extends StatelessWidget {
  const _EmptyBoard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_outlined,
              size: 40,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Board'lar ekranı: sistem kategorileri (7'li) + kullanıcı board'ları.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/ui_constants.dart';
import '../../core/l10n/category_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/board.dart';
import '../../core/models/screenshot_category.dart';
import '../../core/models/screenshot_entry.dart';
import '../../core/router/app_router.dart';
import '../../core/services/entitlement_service.dart';
import '../gallery/providers/gallery_provider.dart';
import 'providers/board_provider.dart';
import 'widgets/board_name_dialog.dart';
import 'widgets/board_tile.dart';

class BoardsScreen extends ConsumerWidget {
  const BoardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final List<ScreenshotEntry> entries =
        ref.watch(galleryProvider).value ?? const [];
    final AsyncValue<List<Board>> boardsAsync = ref.watch(boardsProvider);
    final EntitlementState entitlement = ref.watch(entitlementProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.boardsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(l10n.boardsSystemSection, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.5,
            ),
            itemCount: ScreenshotCategory.values.length,
            itemBuilder: (context, index) {
              final ScreenshotCategory category =
                  ScreenshotCategory.values[index];
              final int count = entries
                  .where((entry) => entry.category == category)
                  .length;
              return BoardTile(
                icon: category.icon,
                label: category.label(l10n),
                count: count,
                onTap: () =>
                    context.push(AppRoutes.boardCategory(category)),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.boardsCustomSection, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          boardsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (boards) => _CustomBoards(
              boards: boards,
              entries: entries,
              canCreate: entitlement.canCreateBoard(boards.length),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kullanıcı board'ları ızgarası + yeni board kartı.
class _CustomBoards extends ConsumerWidget {
  const _CustomBoards({
    required this.boards,
    required this.entries,
    required this.canCreate,
  });

  final List<Board> boards;
  final List<ScreenshotEntry> entries;
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
        childAspectRatio: 1.5,
      ),
      itemCount: boards.length + 1,
      itemBuilder: (context, index) {
        if (index == boards.length) {
          return _NewBoardTile(canCreate: canCreate);
        }
        final Board board = boards[index];
        final int count = entries
            .where((entry) => entry.boardId == board.id)
            .length;
        return BoardTile(
          icon: Icons.folder_outlined,
          label: board.name,
          count: count,
          onTap: () => context.push(AppRoutes.boardCustom(board.id)),
        );
      },
    );
  }
}

/// Yeni board oluşturma kartı; free limit dolmuşsa kilitli görünür ve paywall'a yönlendirir.
class _NewBoardTile extends ConsumerWidget {
  const _NewBoardTile({required this.canCreate});

  final bool canCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => canCreate
          ? _showCreateDialog(context, ref)
          : context.push(AppRoutes.paywall),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                canCreate ? Icons.add : Icons.lock_outline,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.xs),
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

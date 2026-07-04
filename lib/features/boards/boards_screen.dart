// Board'lar ekranı: sistem kategorileri (7'li) + kullanıcı board'ları,
// kapak thumbnail'lı kartlar ve kademeli giriş animasyonu.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/constants/ui_constants.dart';
import '../../core/l10n/category_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/board.dart';
import '../../core/models/screenshot_category.dart';
import '../../core/models/screenshot_entry.dart';
import '../../core/router/app_router.dart';
import '../../core/services/entitlement_service.dart';
import '../../core/widgets/fade_in_up.dart';
import '../gallery/data/screenshot_repository.dart';
import '../gallery/providers/gallery_provider.dart';
import 'providers/board_provider.dart';
import 'widgets/board_name_dialog.dart';
import 'widgets/board_tile.dart';

/// Kademeli giriş için kartlar arası gecikme.
const Duration _staggerStep = Duration(milliseconds: 40);

/// Kapak thumbnail'lı kartlar için kart oranı.
const double _boardCardAspectRatio = 1.05;

class BoardsScreen extends ConsumerWidget {
  const BoardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final List<ScreenshotEntry> entries =
        ref.watch(galleryProvider).value ?? const [];
    final AsyncValue<List<Board>> boardsAsync = ref.watch(boardsProvider);
    final EntitlementState entitlement = ref.watch(entitlementProvider);
    final ScreenshotRepository repo = ref.watch(screenshotRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.boardsTitle)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          // Yüzen navbar içeriği örtmesin diye alt boşluk eklenir.
          MediaQuery.paddingOf(context).bottom + AppSpacing.md,
        ),
        children: [
          Text(
            l10n.boardsSystemSection,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          _SystemBoardsGrid(entries: entries, repo: repo),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.boardsCustomSection,
            style: Theme.of(context).textTheme.titleMedium,
          ),
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
              repo: repo,
              canCreate: entitlement.canCreateBoards,
            ),
          ),
        ],
      ),
    );
  }
}

/// Board içeriğinden kapakta gösterilecek asset'leri seçer.
List<AssetEntity> _covers(
  ScreenshotRepository repo,
  List<ScreenshotEntry> boardEntries,
) {
  return boardEntries
      .map((entry) => repo.assetFor(entry.assetId))
      .whereType<AssetEntity>()
      .take(kBoardCoverCount)
      .toList();
}

/// Sistem kategorileri (7'li) ızgarası.
class _SystemBoardsGrid extends StatelessWidget {
  const _SystemBoardsGrid({required this.entries, required this.repo});

  final List<ScreenshotEntry> entries;
  final ScreenshotRepository repo;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: _boardCardAspectRatio,
      ),
      itemCount: ScreenshotCategory.values.length,
      itemBuilder: (context, index) {
        final ScreenshotCategory category = ScreenshotCategory.values[index];
        final List<ScreenshotEntry> categoryEntries = entries
            .where((entry) => entry.category == category)
            .toList();
        return FadeInUp(
          delay: _staggerStep * index,
          child: BoardTile(
            icon: category.icon,
            label: category.label(l10n),
            count: categoryEntries.length,
            covers: _covers(repo, categoryEntries),
            onTap: () => context.push(AppRoutes.boardCategory(category)),
          ),
        );
      },
    );
  }
}

/// Kullanıcı board'ları ızgarası + yeni board kartı.
class _CustomBoards extends ConsumerWidget {
  const _CustomBoards({
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
        childAspectRatio: _boardCardAspectRatio,
      ),
      itemCount: boards.length + 1,
      itemBuilder: (context, index) {
        if (index == boards.length) {
          return FadeInUp(
            delay: _staggerStep * index,
            child: _NewBoardTile(canCreate: canCreate),
          );
        }
        final Board board = boards[index];
        final List<ScreenshotEntry> boardEntries = entries
            .where((entry) => entry.boardId == board.id)
            .toList();
        return FadeInUp(
          delay: _staggerStep * index,
          child: BoardTile(
            icon: Icons.folder_outlined,
            label: board.name,
            count: boardEntries.length,
            covers: _covers(repo, boardEntries),
            onTap: () => context.push(AppRoutes.boardCustom(board.id)),
          ),
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

// Swipe sıralama ekranı: analiz edilmemiş/"diğer" screenshot'lar için
// sola sil / sağa panoya ata / yukarı atla kart akışı.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/constants/ui_constants.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/board.dart';
import '../../core/models/screenshot_category.dart';
import '../../core/models/screenshot_entry.dart';
import '../../core/router/app_router.dart';
import '../../core/services/entitlement_service.dart';
import '../boards/providers/board_provider.dart';
import '../boards/widgets/board_name_dialog.dart';
import '../gallery/data/screenshot_repository.dart';
import '../gallery/providers/gallery_provider.dart';
import 'widgets/swipe_card.dart';

/// Board seçici sheet'inde "yeni pano oluştur" satırını işaretleyen sentinel.
const String _createNewBoardSentinel = '__create_new_board__';

class SortingScreen extends ConsumerStatefulWidget {
  const SortingScreen({super.key});

  @override
  ConsumerState<SortingScreen> createState() => _SortingScreenState();
}

class _SortingScreenState extends ConsumerState<SortingScreen> {
  /// Bu oturumda "atla" denen kartlar — kalıcı değil, ekran kapanınca sıfırlanır.
  final Set<String> _skippedIds = {};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final EntitlementState entitlement = ref.watch(entitlementProvider);
    final List<ScreenshotEntry> entries =
        ref.watch(galleryProvider).value ?? const [];
    final ScreenshotRepository repo = ref.watch(screenshotRepositoryProvider);

    final List<ScreenshotEntry> queue = entries
        .where(
          (entry) =>
              entry.boardId == null &&
              (entry.isPending || entry.category == ScreenshotCategory.other) &&
              !_skippedIds.contains(entry.assetId),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sortingTitle)),
      body: !entitlement.canSwipe
          ? const _SortingLimit()
          : queue.isEmpty
          ? const _SortingEmpty()
          : _SortingDeck(
              top: queue.first,
              next: queue.length > 1 ? queue[1] : null,
              remaining: queue.length,
              asset: repo.assetFor(queue.first.assetId),
              onDelete: () => _handleDelete(queue.first.assetId),
              onSkip: () {
                HapticFeedback.selectionClick();
                setState(() => _skippedIds.add(queue.first.assetId));
              },
              onAssign: () => _handleAssign(queue.first.assetId),
            ),
    );
  }

  Future<bool> _handleDelete(String assetId) async {
    List<String> deleted;
    try {
      deleted = await PhotoManager.editor.deleteWithIds([assetId]);
    } catch (error, stackTrace) {
      debugPrint('Sıralama sil hatası ($assetId): $error\n$stackTrace');
      if (mounted) _showSnack(context.l10n.sortingDeleteFailed);
      return false;
    }
    if (deleted.isEmpty) return false;
    HapticFeedback.mediumImpact();
    await ref.read(screenshotRepositoryProvider).removeEntry(assetId);
    await ref.read(entitlementProvider.notifier).registerSwipe();
    return true;
  }

  Future<void> _handleAssign(String assetId) async {
    final List<Board> boards = ref.read(boardsProvider).value ?? const [];
    final String? choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _BoardPickerSheet(boards: boards),
    );
    if (choice == null || !mounted) return;

    if (choice == _createNewBoardSentinel) {
      await _createBoardAndAssign(assetId);
      return;
    }
    HapticFeedback.lightImpact();
    await ref.read(screenshotRepositoryProvider).assignToBoard(assetId, choice);
    await ref.read(entitlementProvider.notifier).registerSwipe();
  }

  Future<void> _createBoardAndAssign(String assetId) async {
    final l10n = context.l10n;
    if (!ref.read(entitlementProvider).canCreateBoards) {
      if (mounted) context.push(AppRoutes.paywall);
      return;
    }
    final String? name = await showDialog<String>(
      context: context,
      builder: (_) => BoardNameDialog(
        title: l10n.boardsNewBoardDialogTitle,
        confirmLabel: l10n.boardsCreateAction,
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;
    final Board created = await ref.read(boardsProvider.notifier).create(name);
    await ref
        .read(screenshotRepositoryProvider)
        .assignToBoard(assetId, created.id);
    await ref.read(entitlementProvider.notifier).registerSwipe();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Üstteki (etkileşimli) kart + arkada beliren bir sonraki kartın önizlemesi.
class _SortingDeck extends StatelessWidget {
  const _SortingDeck({
    required this.top,
    required this.next,
    required this.remaining,
    required this.asset,
    required this.onDelete,
    required this.onSkip,
    required this.onAssign,
  });

  final ScreenshotEntry top;
  final ScreenshotEntry? next;
  final int remaining;
  final AssetEntity? asset;
  final Future<bool> Function() onDelete;
  final VoidCallback onSkip;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Text(
            context.l10n.sortingRemainingCount(remaining),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (next != null)
                  Transform.scale(
                    scale: 0.94,
                    child: Opacity(
                      opacity: 0.6,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: AspectRatio(
                          aspectRatio: 9 / 16,
                          child: ColoredBox(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                    ),
                  ),
                SwipeCard(
                  key: ValueKey(top.assetId),
                  asset: asset,
                  onDelete: onDelete,
                  onSkip: onSkip,
                  onAssign: onAssign,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardPickerSheet extends StatelessWidget {
  const _BoardPickerSheet({required this.boards});

  final List<Board> boards;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.sortingAssignSheetTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final Board board in boards)
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(board.name),
                onTap: () => Navigator.of(context).pop(board.id),
              ),
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(l10n.boardsNewBoardAction),
              onTap: () => Navigator.of(context).pop(_createNewBoardSentinel),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortingEmpty extends StatelessWidget {
  const _SortingEmpty();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.checklist_rtl_outlined,
                size: 40,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.sortingEmptyTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.sortingEmptyBody,
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

class _SortingLimit extends StatelessWidget {
  const _SortingLimit();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.workspace_premium_outlined,
                size: 40,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.sortingLimitTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.sortingLimitBody,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => context.push(AppRoutes.paywall),
              child: Text(l10n.paywallTitle),
            ),
          ],
        ),
      ),
    );
  }
}

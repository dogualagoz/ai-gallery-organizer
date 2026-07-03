// Tek board/kategori detayı: filtrelenmiş screenshot ızgarası + (özel board'da)
// yönetim aksiyonları + kategori bazlı toplu silme (Pro).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../../core/constants/ui_constants.dart';
import '../../core/l10n/category_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/board.dart';
import '../../core/models/screenshot_category.dart';
import '../../core/models/screenshot_entry.dart';
import '../../core/router/app_router.dart';
import '../../core/services/entitlement_service.dart';
import '../../core/widgets/screenshot_results_grid.dart';
import '../gallery/data/screenshot_repository.dart';
import '../gallery/providers/gallery_provider.dart';
import 'providers/board_provider.dart';
import 'widgets/board_name_dialog.dart';

class BoardDetailScreen extends ConsumerStatefulWidget {
  const BoardDetailScreen.category({super.key, required this.category})
    : boardId = null;

  const BoardDetailScreen.custom({super.key, required this.boardId})
    : category = null;

  final ScreenshotCategory? category;
  final String? boardId;

  @override
  ConsumerState<BoardDetailScreen> createState() => _BoardDetailScreenState();
}

class _BoardDetailScreenState extends ConsumerState<BoardDetailScreen> {
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};
  bool _bulkDeleting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final List<ScreenshotEntry> entries =
        ref.watch(galleryProvider).value ?? const [];

    final List<ScreenshotEntry> filtered = widget.category != null
        ? entries.where((entry) => entry.category == widget.category).toList()
        : entries.where((entry) => entry.boardId == widget.boardId).toList();

    final Board? board = widget.boardId == null
        ? null
        : ref
              .watch(boardsProvider)
              .value
              ?.firstWhereOrNull((b) => b.id == widget.boardId);

    final String title = widget.category != null
        ? widget.category!.label(l10n)
        : (board?.name ?? l10n.boardsTitle);

    final bool canBulkDelete = ref.watch(entitlementProvider).canBulkDelete;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectionMode ? l10n.bulkSelectionCount(_selectedIds.length) : title,
        ),
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelection,
              )
            : null,
        actions: _selectionMode
            ? [
                IconButton(
                  tooltip: l10n.bulkDeleteAction,
                  icon: _bulkDeleting
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline),
                  onPressed: _selectedIds.isEmpty || _bulkDeleting
                      ? null
                      : _bulkDelete,
                ),
              ]
            : [
                if (filtered.isNotEmpty)
                  IconButton(
                    tooltip: l10n.bulkSelectAction,
                    icon: const Icon(Icons.checklist_outlined),
                    onPressed: () => canBulkDelete
                        ? setState(() => _selectionMode = true)
                        : context.push(AppRoutes.paywall),
                  ),
                if (widget.boardId != null && board != null)
                  IconButton(
                    tooltip: l10n.boardsRenameAction,
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _showRenameDialog(context, board),
                  ),
                if (widget.boardId != null)
                  IconButton(
                    tooltip: l10n.boardsDeleteAction,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () =>
                        _showDeleteConfirm(context, widget.boardId!),
                  ),
              ],
      ),
      body: filtered.isEmpty
          ? _EmptyBoard(text: l10n.boardDetailEmpty)
          : _selectionMode
          ? _SelectableGrid(
              entries: filtered,
              selectedIds: _selectedIds,
              onToggle: (assetId) => setState(() {
                if (!_selectedIds.remove(assetId)) _selectedIds.add(assetId);
              }),
            )
          : ScreenshotResultsGrid(entries: filtered),
    );
  }

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _bulkDelete() async {
    final String failureMessage = context.l10n.bulkDeleteFailed;
    setState(() => _bulkDeleting = true);
    final ScreenshotRepository repo = ref.read(screenshotRepositoryProvider);
    List<String> deleted;
    try {
      deleted = await PhotoManager.editor.deleteWithIds(_selectedIds.toList());
    } catch (error, stackTrace) {
      debugPrint('Toplu silme hatası: $error\n$stackTrace');
      if (mounted) {
        setState(() => _bulkDeleting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failureMessage)));
      }
      return;
    }
    for (final String assetId in deleted) {
      await repo.removeEntry(assetId);
    }
    if (!mounted) return;
    setState(() {
      _bulkDeleting = false;
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _showRenameDialog(BuildContext context, Board board) async {
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

  Future<void> _showDeleteConfirm(BuildContext context, String boardId) async {
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

/// Seçim modunda gösterilen ızgara: dokununca navigasyon yerine seçimi değiştirir.
class _SelectableGrid extends ConsumerWidget {
  const _SelectableGrid({
    required this.entries,
    required this.selectedIds,
    required this.onToggle,
  });

  final List<ScreenshotEntry> entries;
  final Set<String> selectedIds;
  final void Function(String assetId) onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ScreenshotRepository repo = ref.watch(screenshotRepositoryProvider);

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.xs,
        crossAxisSpacing: AppSpacing.xs,
        childAspectRatio: 9 / 16,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final ScreenshotEntry entry = entries[index];
        final bool selected = selectedIds.contains(entry.assetId);
        return _SelectableTile(
          asset: repo.assetFor(entry.assetId),
          selected: selected,
          onTap: () => onToggle(entry.assetId),
        );
      },
    );
  }
}

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  final AssetEntity? asset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (asset != null)
              AssetEntityImage(
                asset!,
                isOriginal: false,
                thumbnailSize: const ThumbnailSize.square(300),
                fit: BoxFit.cover,
              )
            else
              ColoredBox(color: scheme.surfaceContainerHighest),
            if (selected)
              Container(color: scheme.primary.withValues(alpha: 0.35)),
            Positioned(
              top: AppSpacing.xs,
              right: AppSpacing.xs,
              child: Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? scheme.primary : Colors.white,
                shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
              ),
            ),
          ],
        ),
      ),
    );
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

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
import '../../core/services/category_names_service.dart';
import '../../core/services/entitlement_service.dart';
import '../../core/widgets/confirm_sheet.dart';
import '../../core/widgets/edge_swipe_back.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/screenshot_results_grid.dart';
import '../analysis/providers/analysis_queue_provider.dart';
import '../gallery/data/screenshot_repository.dart';
import '../gallery/providers/gallery_provider.dart';
import 'providers/board_provider.dart';
import 'widgets/board_name_dialog.dart';

class BoardDetailScreen extends ConsumerStatefulWidget {
  const BoardDetailScreen.category({
    super.key,
    required this.category,
    this.startInSelection = false,
  }) : boardId = null;

  const BoardDetailScreen.custom({
    super.key,
    required this.boardId,
    this.startInSelection = false,
  }) : category = null;

  final ScreenshotCategory? category;
  final String? boardId;

  /// Ekran açılır açılmaz seçim moduna girsin mi (düzenleme aksiyon sayfasından
  /// "Fotoğrafları seç" ile gelindiğinde true).
  final bool startInSelection;

  @override
  ConsumerState<BoardDetailScreen> createState() => _BoardDetailScreenState();
}

class _BoardDetailScreenState extends ConsumerState<BoardDetailScreen> {
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};
  bool _bulkDeleting = false;

  @override
  void initState() {
    super.initState();
    _selectionMode = widget.startInSelection;
  }

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

    final Map<int, String> categoryNames = ref.watch(categoryNamesProvider);
    final String title = widget.category != null
        ? widget.category!.displayName(l10n, categoryNames)
        : (board?.name ?? l10n.boardsTitle);

    final bool canBulkDelete = ref.watch(entitlementProvider).canBulkDelete;

    return EdgeSwipeBack(
      // Seçim modunda kenar-swipe kapalı: yanlışlıkla ekrandan çıkmayı önler.
      enabled: !_selectionMode,
      onBack: () => Navigator.maybePop(context),
      child: Scaffold(
        body: Column(
          children: [
            _buildHeader(context, title, filtered, board, canBulkDelete),
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyBoard(text: l10n.boardDetailEmpty)
                  : _selectionMode
                  ? _SelectableGrid(
                      entries: filtered,
                      selectedIds: _selectedIds,
                      onToggle: (assetId) => setState(() {
                        if (!_selectedIds.remove(assetId)) {
                          _selectedIds.add(assetId);
                        }
                      }),
                    )
                  : ScreenshotResultsGrid(entries: filtered),
            ),
          ],
        ),
      ),
    );
  }

  /// AppBar yerine sayfaya gömülü header: geri chevron + başlık + aksiyonlar.
  /// Seçim modunda kapat + "N seçildi" + Taşı/Sil varyantına geçer.
  Widget _buildHeader(
    BuildContext context,
    String title,
    List<ScreenshotEntry> filtered,
    Board? board,
    bool canBulkDelete,
  ) {
    final l10n = context.l10n;
    if (_selectionMode) {
      return PageHeader(
        title: l10n.bulkSelectionCount(_selectedIds.length),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _exitSelection,
        ),
        actions: [
          IconButton(
            tooltip: l10n.moveAction,
            icon: const Icon(Icons.drive_file_move_outline),
            onPressed: _selectedIds.isEmpty || _bulkDeleting
                ? null
                : _moveSelected,
          ),
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
        ],
      );
    }
    return PageHeader(
      title: title,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => Navigator.maybePop(context),
      ),
      actions: [
        if (widget.category != null && filtered.isNotEmpty)
          IconButton(
            tooltip: l10n.categoryReanalyzeAction,
            icon: const Icon(Icons.auto_awesome_outlined),
            onPressed: () => _reanalyzeCategory(filtered),
          ),
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
            onPressed: () => _showDeleteConfirm(context, widget.boardId!),
          ),
        if (widget.category != null)
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () => _showCategoryActions(filtered),
          ),
      ],
    );
  }

  /// Kategori "..." aksiyonları: eski açılır menü yerine iOS-tarzı aksiyon sheet.
  Future<void> _showCategoryActions(List<ScreenshotEntry> filtered) async {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.categoryRenameAction),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _renameCategory(widget.category!);
              },
            ),
            if (filtered.isNotEmpty)
              ListTile(
                leading: Icon(Icons.delete_outline, color: scheme.error),
                title: Text(
                  l10n.categoryDeleteAllAction,
                  style: TextStyle(color: scheme.error),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _deleteAllCategory(filtered);
                },
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  /// Kategoriyi yeniden analiz eder: onaydan sonra kayıtları pending'e alıp
  /// anasayfaya döner; analiz animasyonu orada oynar, haftalık kotadan harcanır.
  Future<void> _reanalyzeCategory(List<ScreenshotEntry> filtered) async {
    final l10n = context.l10n;
    final bool confirmed = await showConfirmSheet(
      context,
      title: l10n.categoryReanalyzeConfirmTitle,
      body: l10n.categoryReanalyzeConfirmBody,
      confirmLabel: l10n.categoryReanalyzeAction,
      icon: Icons.auto_awesome_outlined,
    );
    if (!confirmed || !mounted) return;

    final ScreenshotRepository repo = ref.read(screenshotRepositoryProvider);
    final List<String> ids = filtered.map((e) => e.assetId).toList();
    for (final String assetId in ids) {
      await repo.markPending(assetId);
    }
    if (!mounted) return;
    // Analiz kartı anasayfada; kullanıcı animasyonu görsün diye geri dön.
    Navigator.of(context).maybePop();
    ref.read(analysisQueueProvider.notifier).start(onlyAssetIds: ids);
  }

  /// Kategoriye özel ad verir; varsayılan etiketle aynıysa override'ı temizler.
  Future<void> _renameCategory(ScreenshotCategory category) async {
    final l10n = context.l10n;
    final Map<int, String> names = ref.read(categoryNamesProvider);
    final String current = names[category.index] ?? category.label(l10n);
    final String? name = await showDialog<String>(
      context: context,
      builder: (_) => BoardNameDialog(
        title: l10n.categoryRenameDialogTitle,
        confirmLabel: l10n.categoryRenameAction,
        initialValue: current,
      ),
    );
    if (name == null || !mounted) return;
    final CategoryNamesNotifier notifier = ref.read(
      categoryNamesProvider.notifier,
    );
    if (name.trim() == category.label(l10n)) {
      await notifier.clear(category);
    } else {
      await notifier.setName(category, name);
    }
  }

  /// Kategorideki tüm fotoğrafları tek onayla (tek deleteWithIds) siler.
  Future<void> _deleteAllCategory(List<ScreenshotEntry> filtered) async {
    if (filtered.isEmpty) return;
    final l10n = context.l10n;
    final int count = filtered.length;
    final bool confirmed = await showConfirmSheet(
      context,
      title: l10n.categoryDeleteAllConfirmTitle(count),
      body: l10n.categoryDeleteAllConfirmBody,
      confirmLabel: l10n.categoryDeleteAllAction,
      icon: Icons.delete_sweep_outlined,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _bulkDeleting = true);
    final ScreenshotRepository repo = ref.read(screenshotRepositoryProvider);
    final List<String> ids = filtered.map((e) => e.assetId).toList();
    List<String> deleted;
    try {
      deleted = await PhotoManager.editor.deleteWithIds(ids);
    } catch (error, stackTrace) {
      debugPrint('Kategori toplu silme hatası: $error\n$stackTrace');
      if (mounted) {
        setState(() => _bulkDeleting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.bulkDeleteFailed)));
      }
      return;
    }
    for (final String assetId in deleted) {
      await repo.removeEntry(assetId);
    }
    if (mounted) setState(() => _bulkDeleting = false);
  }

  /// Seçili fotoğrafları başka bir sistem kategorisine veya özel panoya taşır.
  Future<void> _moveSelected() async {
    final List<Board> boards = ref.read(boardsProvider).value ?? const [];
    final Map<int, String> names = ref.read(categoryNamesProvider);
    final _MoveTarget? target = await showModalBottomSheet<_MoveTarget>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _MoveTargetSheet(
        boards: boards,
        categoryNames: names,
        currentCategory: widget.category,
      ),
    );
    if (target == null || !mounted) return;

    final ScreenshotRepository repo = ref.read(screenshotRepositoryProvider);
    for (final String assetId in _selectedIds) {
      if (target.category != null) {
        await repo.setCategory(assetId, target.category!);
      } else if (target.boardId != null) {
        await repo.assignToBoard(assetId, target.boardId);
      }
    }
    if (!mounted) return;
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureMessage)));
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

/// Taşıma hedefi: ya bir sistem kategorisi ya da bir özel pano.
class _MoveTarget {
  const _MoveTarget.category(this.category) : boardId = null;
  const _MoveTarget.board(this.boardId) : category = null;

  final ScreenshotCategory? category;
  final String? boardId;
}

/// Seçili fotoğrafların taşınacağı hedefi seçtiren alt sayfa: sistem
/// kategorileri + özel panolar.
class _MoveTargetSheet extends StatelessWidget {
  const _MoveTargetSheet({
    required this.boards,
    required this.categoryNames,
    required this.currentCategory,
  });

  final List<Board> boards;
  final Map<int, String> categoryNames;
  final ScreenshotCategory? currentCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<ScreenshotCategory> categories = ScreenshotCategory.values
        .where((c) => c != currentCategory)
        .toList();

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(l10n.moveSheetTitle, style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.moveSectionCategories,
              style: textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            for (final ScreenshotCategory category in categories)
              ListTile(
                leading: Icon(category.icon),
                title: Text(category.displayName(l10n, categoryNames)),
                onTap: () =>
                    Navigator.of(context).pop(_MoveTarget.category(category)),
              ),
            if (boards.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.moveSectionBoards,
                style: textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              for (final Board board in boards)
                ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(board.name),
                  onTap: () =>
                      Navigator.of(context).pop(_MoveTarget.board(board.id)),
                ),
            ],
          ],
        ),
      ),
    );
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
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

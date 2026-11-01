// Kategori/pano detayı: büyük başlıklı sıkı ızgara, başlıkta "Seç" ve "…"
// menüsü; seçim modunda sekme çubuğunun yerini cam araç çubuğu alır.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/ui_constants.dart';
import '../../core/l10n/category_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/board.dart';
import '../../core/models/screenshot_category.dart';
import '../../core/models/screenshot_entry.dart';
import '../../core/router/tab_bar_visibility.dart';
import '../../core/services/category_names_service.dart';
import '../../core/services/entitlement_service.dart';
import '../../core/widgets/app_menus.dart';
import '../../core/widgets/app_nav_scaffold.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/selection_toolbar.dart';
import '../../core/widgets/spring_visibility.dart';
import '../analysis/providers/recent_distribution_provider.dart';
import '../gallery/providers/gallery_provider.dart';
import '../gallery/screenshot_actions.dart';
import '../gallery/widgets/screenshot_grid.dart';
import '../paywall/open_paywall.dart';
import 'providers/board_provider.dart';
import 'widgets/board_edit_actions.dart';

/// Bir sistem kategorisinin ya da kullanıcı panosunun ekran görüntüleri;
/// toplu işlem (seç → paylaş/taşı/sil) Pro'ya bağlıdır.
class BoardDetailScreen extends ConsumerStatefulWidget {
  const BoardDetailScreen.category({
    super.key,
    required ScreenshotCategory this.category,
    this.startInSelection = false,
  }) : boardId = null;

  const BoardDetailScreen.custom({
    super.key,
    required String this.boardId,
    this.startInSelection = false,
  }) : category = null;

  final ScreenshotCategory? category;
  final String? boardId;

  /// Ekran doğrudan seçim modunda açılsın mı (bağlam menüsündeki "Seç").
  final bool startInSelection;

  @override
  ConsumerState<BoardDetailScreen> createState() => _BoardDetailScreenState();
}

class _BoardDetailScreenState extends ConsumerState<BoardDetailScreen> {
  /// dispose'da ref kullanılamadığı için baştan alınır.
  late final TabBarHiddenNotifier _tabBar;

  final Set<String> _selectedIds = {};
  bool _selecting = false;

  /// Paylaşım dosyaları hazırlanırken ya da silme onayı beklenirken true.
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tabBar = ref.read(tabBarHiddenProvider.notifier);
    if (widget.startInSelection &&
        ref.read(entitlementProvider).canBulkDelete) {
      _selecting = true;
      // initState ağaç kurulurken çalışır; provider bir sonraki mikro görevde
      // değişir.
      scheduleMicrotask(_syncTabBar);
    }
    final ScreenshotCategory? category = widget.category;
    if (category != null) {
      // Kategori görüldü: Kütüphane'deki "+N" rozeti kalkar.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(recentDistributionProvider.notifier).clear(category);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Dal arka plana geçerse (programatik sekme geçişi) seçim kapanır; gizli
    // sekme çubuğu başka sekmede asılı kalmasın.
    if (_selecting && !TickerMode.valuesOf(context).enabled) {
      scheduleMicrotask(() {
        if (mounted) _setSelecting(false);
      });
    }
  }

  @override
  void dispose() {
    // Ağaç kilitliyken provider değişmez; bırakma sonraki mikro göreve kalır.
    final TabBarHiddenNotifier tabBar = _tabBar;
    final Object owner = this;
    scheduleMicrotask(() => tabBar.release(owner));
    super.dispose();
  }

  void _syncTabBar() {
    if (!mounted) return;
    if (_selecting) {
      _tabBar.hide(this);
    } else {
      _tabBar.release(this);
    }
  }

  void _setSelecting(bool selecting) {
    setState(() {
      _selecting = selecting;
      _selectedIds.clear();
    });
    _syncTabBar();
  }

  void _toggle(String assetId) {
    setState(() {
      if (!_selectedIds.remove(assetId)) _selectedIds.add(assetId);
    });
  }

  /// Panoyu geride bırakan eylemlerden sonra (pano silindi, yeniden analiz
  /// başladı) Kütüphane'ye döner; analiz modülü orada oynar.
  void _leave() {
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ScreenshotCategory? category = widget.category;
    final List<ScreenshotEntry> entries = [
      for (final ScreenshotEntry entry
          in ref.watch(galleryProvider).value ?? const <ScreenshotEntry>[])
        if (category != null
            ? entry.category == category
            : entry.boardId == widget.boardId)
          entry,
    ];
    final Board? board = widget.boardId == null
        ? null
        : (ref.watch(boardsProvider).value ?? const <Board>[])
              .where((candidate) => candidate.id == widget.boardId)
              .firstOrNull;
    final String title = category != null
        ? category.displayName(l10n, ref.watch(categoryNamesProvider))
        : (board?.name ?? l10n.boardsTitle);
    // Silinen ya da başka yere taşınanlar seçimden kendiliğinden düşer.
    final List<String> selected = [
      for (final ScreenshotEntry entry in entries)
        if (_selectedIds.contains(entry.assetId)) entry.assetId,
    ];

    return PopScope(
      // Seçim modunda geri jesti önce seçimi kapatır, ekrandan çıkmaz.
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _setSelecting(false);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          AppNavScaffold(
            title: title,
            leading: _selecting ? _selectAllButton(entries, selected) : null,
            trailing: _selecting
                ? NavBarButton.text(
                    label: l10n.cancelAction,
                    onPressed: () => _setSelecting(false),
                  )
                : _trailing(entries, board),
            slivers: _slivers(entries),
          ),
          _toolbar(selected),
        ],
      ),
    );
  }

  /// Normal mod: "Seç" (Pro değilse kilitli) + "…" menüsü.
  Widget _trailing(List<ScreenshotEntry> entries, Board? board) {
    final l10n = context.l10n;
    final bool canSelect = ref.watch(entitlementProvider).canBulkDelete;
    // Pano henüz yüklenmediyse ya da silindiyse menü gösterilmez.
    final bool hasTarget = widget.category != null || board != null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (entries.isNotEmpty)
          NavBarButton.text(
            label: l10n.bulkSelectAction,
            locked: !canSelect,
            onPressed: canSelect
                ? () => _setSelecting(true)
                : () => openPaywall(context),
          ),
        if (hasTarget) ...[
          const SizedBox(width: AppSpacing.sm),
          AppMoreMenuButton(
            label: l10n.moreActionsLabel,
            actions: boardMenuActions(
              context,
              ref,
              isEmpty: entries.isEmpty,
              board: board,
              category: widget.category,
              onLeave: _leave,
            ),
          ),
        ],
      ],
    );
  }

  /// Seçim modu: hepsi seçiliyse "Seçimi Kaldır", değilse "Tümünü Seç".
  Widget _selectAllButton(
    List<ScreenshotEntry> entries,
    List<String> selected,
  ) {
    final l10n = context.l10n;
    final bool allSelected =
        entries.isNotEmpty && selected.length == entries.length;
    return NavBarButton.text(
      label: allSelected ? l10n.deselectAllAction : l10n.selectAllAction,
      onPressed: () => setState(() {
        _selectedIds.clear();
        if (!allSelected) {
          _selectedIds.addAll(entries.map((entry) => entry.assetId));
        }
      }),
    );
  }

  List<Widget> _slivers(List<ScreenshotEntry> entries) {
    final l10n = context.l10n;
    final ScreenshotCategory? category = widget.category;
    if (entries.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateView(
            icon: category?.icon ?? AppIcons.board,
            title: l10n.boardDetailEmpty,
            message: category != null
                ? l10n.categoryEmptyBody
                : l10n.boardEmptyBody,
          ),
        ),
      ];
    }
    return [
      if (entries.any((entry) => entry.isPending))
        const SliverToBoxAdapter(child: ScreenshotPendingLegend()),
      ScreenshotGrid(
        entries: entries,
        selectedIds: _selecting ? _selectedIds : null,
        onToggle: _toggle,
      ),
    ];
  }

  /// Sekme çubuğunun yerinde duran seçim araç çubuğu; yalnız seçim modunda
  /// görünür (çubukla aynı yaylı geçişle yer değiştirir).
  Widget _toolbar(List<String> selected) {
    final l10n = context.l10n;
    final bool none = selected.isEmpty;
    // Kabuk Scaffold'u gövdeden cihaz alt boşluğunu çıkarır; sekme çubuğuyla
    // aynı hizaya oturmak için pencerenin kendi değeri okunur.
    final double deviceInset = MediaQueryData.fromView(View.of(context))
        .padding
        .bottom;
    return Positioned(
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      bottom: AppSizes.navBarBottomGap(deviceInset),
      child: SpringVisibility(
        visible: _selecting,
        child: SelectionToolbar(
          busy: _busy,
          status: none
              ? l10n.selectItemsTitle
              : l10n.bulkSelectionCount(selected.length),
          leading: [
            ToolbarAction(
              icon: AppIcons.share,
              label: l10n.shareAction,
              onPressed: none
                  ? null
                  : () => _whileBusy(
                      () => shareScreenshots(context, ref, selected),
                    ),
            ),
          ],
          trailing: [
            ToolbarAction(
              icon: AppIcons.move,
              label: l10n.moveAction,
              onPressed: none ? null : () => _move(selected),
            ),
            ToolbarAction(
              icon: AppIcons.delete,
              label: l10n.deleteAction,
              destructive: true,
              onPressed: none ? null : () => _delete(selected),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _whileBusy(Future<void> Function() task) async {
    setState(() => _busy = true);
    try {
      await task();
    } finally {
      // Beklenmedik hata olsa da araç çubuğu kilitli kalmaz.
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _move(List<String> ids) async {
    final bool moved = await moveScreenshots(
      context,
      ref,
      ids,
      currentCategory: widget.category,
      currentBoardId: widget.boardId,
    );
    if (moved && mounted) _setSelecting(false);
  }

  /// Onayı iOS'un kendi silme diyaloğu ister; silindiyse seçim kapanır.
  Future<void> _delete(List<String> ids) async {
    List<String> deleted = const [];
    await _whileBusy(() async {
      deleted = await deleteScreenshots(context, ref, ids);
    });
    if (deleted.isNotEmpty && mounted) _setSelecting(false);
  }
}

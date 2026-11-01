// Fotoğraflar tarzı görüntüleyici: açıldığı koleksiyonda sayfa sayfa kaydırma,
// aşağı çekip kapatma, yukarı çekince bilgi paneli; dokunuş arayüzü gizler ve
// zemini siyaha çevirir. Alt cam çubukta Paylaş / Bilgi / Taşı / Sil.
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/cupertino.dart' show kMinInteractiveDimensionCupertino;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/motion_constants.dart';
import '../../core/constants/ui_constants.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/screenshot_entry.dart';
import '../../core/router/app_router.dart';
import '../../core/services/haptic_service.dart';
import '../../core/utils/motion_physics.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/glass_toolbar.dart';
import '../gallery/data/screenshot_repository.dart';
import '../gallery/providers/gallery_provider.dart';
import '../gallery/screenshot_actions.dart';
import '../gallery/widgets/screenshot_grid_tile.dart';
import '../search/search_request_provider.dart';
import 'viewer_motion.dart';
import 'widgets/info_panel.dart';
import 'widgets/photo_page.dart';
import 'widgets/viewer_top_bar.dart';

/// Ekran görüntüsü görüntüleyicisi. [scope] açıldığı koleksiyonun sırasıdır;
/// verilmezse (deep link) yalnız [assetId] gösterilir.
class DetailScreen extends ConsumerStatefulWidget {
  const DetailScreen({super.key, required this.assetId, this.scope});

  /// Açılışta gösterilen screenshot'ın photo_manager asset kimliği.
  final String assetId;

  /// Kaydırılabilen koleksiyonun sırası ([ViewerScope] rota ekinden).
  final List<String>? scope;

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen>
    with TickerProviderStateMixin {
  late final List<String> _scope;
  late String _currentId;
  late int _index;
  late final PageController _pages;
  late final ViewerMotion _motion;

  /// 1 = arayüz görünür (sistem zemini), 0 = gizli (siyah zemin).
  late final AnimationController _chrome;

  bool _chromeVisible = true;

  /// Görünen sayfa yakınlaştırılmışken kaydırma ve aşağı çekiş kilitlenir.
  bool _zoomed = false;

  /// Paylaşım dosyaları hazırlanırken ya da silme onayı beklenirken true.
  bool _busy = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _scope = _initialScope();
    _currentId = widget.assetId;
    _index = _scope.indexOf(widget.assetId);
    _pages = PageController(initialPage: _index);
    _motion = ViewerMotion(
      vsync: this,
      onDismiss: _close,
      onInfoChanged: _onInfoChanged,
    );
    _chrome = AnimationController.unbounded(vsync: this, value: 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _precacheNeighbors(_scope, _index);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion.reduceMotion = context.reduceMotion;
  }

  @override
  void dispose() {
    _pages.dispose();
    _motion.dispose();
    _chrome.dispose();
    super.dispose();
  }

  List<String> _initialScope() {
    final List<String>? scope = widget.scope;
    return scope != null && scope.contains(widget.assetId)
        ? List.unmodifiable(scope)
        : [widget.assetId];
  }

  @override
  Widget build(BuildContext context) {
    // Kayıt değişince (analiz, taşıma, silme) görüntüleyici tazelenir.
    ref.watch(galleryProvider);
    final ScreenshotRepository repo = ref.watch(screenshotRepositoryProvider);
    final List<String> ids = [
      for (final String id in _scope)
        if (repo.entryFor(id) != null) id,
    ];
    final Widget body;
    if (ids.isNotEmpty) {
      body = _viewer(repo, ids);
    } else if (_closing || _busy) {
      // Son görüntü silinirken ya da kapanırken "bulunamadı" ekranı
      // görünmez; görüntüleyici solarak çekilir.
      body = const SizedBox.shrink();
    } else {
      body = _MissingScreenshot(onClose: _close);
    }
    return Material(type: MaterialType.transparency, child: body);
  }

  Widget _viewer(ScreenshotRepository repo, List<String> ids) {
    _syncIndex(ids);
    final ScreenshotEntry entry = repo.entryFor(_currentId)!;
    final bool lightBackground =
        _chromeVisible && Theme.of(context).brightness == Brightness.light;
    final double toolbarBottom = AppSizes.navBarBottomGap(
      MediaQuery.paddingOf(context).bottom,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: lightBackground
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double height = constraints.maxHeight;
          return Stack(
            fit: StackFit.expand,
            children: [
              _backdrop(height),
              _pagesLayer(repo, ids, height),
              _infoLayer(entry, height, toolbarBottom),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _chromeFade(
                  height,
                  ViewerTopBar(createdAt: entry.createdAt, onBack: _close),
                ),
              ),
              Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: toolbarBottom,
                child: _chromeFade(height, _toolbar(entry)),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Liste değişince (silme) bulunulan öğe yeniden konumlanır: silinenin
  /// yerine sıradaki gelir (Fotoğraflar), sondaysa bir öncekine geçilir.
  /// build içinde çalışır çünkü liste yalnız build'de (galeri izlenirken)
  /// bilinir; sayfa denetleyicisi kare sonrasında hizalanır.
  void _syncIndex(List<String> ids) {
    final int found = ids.indexOf(_currentId);
    final int index = found >= 0 ? found : math.min(_index, ids.length - 1);
    if (found < 0) {
      _currentId = ids[index];
      _zoomed = false;
    }
    if (index == _index) return;
    _index = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pages.hasClients) _pages.jumpToPage(_index);
    });
  }

  /// Arayüz açıkken sistem zemini, gizliyken siyah; aşağı çekişte solar ve
  /// arkadaki ızgara görünür.
  Widget _backdrop(double height) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: Listenable.merge([_chrome, _motion.drag]),
      builder: (context, _) {
        final Color color = Color.lerp(
          scheme.scrim,
          scheme.surfaceContainerLowest,
          _chrome.value.clamp(0.0, 1.0),
        )!;
        return ColoredBox(
          color: color.withValues(alpha: 1 - _motion.dismissProgress(height)),
        );
      },
    );
  }

  /// Sayfalar: panel açıldıkça üst çubukla panel arasına sığar; aşağı
  /// çekişte parmağı izleyip küçülür.
  Widget _pagesLayer(
    ScreenshotRepository repo,
    List<String> ids,
    double height,
  ) {
    final double panel = ViewerMotion.panelHeight(height);
    final double barBottom =
        MediaQuery.paddingOf(context).top +
        kMinInteractiveDimensionCupertino +
        AppSpacing.sm;
    final bool canDrag = !_zoomed;

    return AnimatedBuilder(
      animation: _motion.info,
      builder: (context, child) {
        final double open = math.max(0, _motion.info.value);
        return Positioned(
          left: 0,
          right: 0,
          top: barBottom * math.min(open, 1),
          bottom: panel * open,
          child: child!,
        );
      },
      child: GestureDetector(
        onVerticalDragStart: canDrag ? _motion.dragStart : null,
        onVerticalDragUpdate: canDrag
            ? (details) => _motion.dragUpdate(details, height)
            : null,
        onVerticalDragEnd: canDrag
            ? (details) => _motion.dragEnd(details, height)
            : null,
        onVerticalDragCancel: canDrag ? () => _motion.dragCancel(height) : null,
        child: ValueListenableBuilder<Offset>(
          valueListenable: _motion.drag,
          builder: (context, offset, child) => Transform.translate(
            offset: offset,
            child: Transform.scale(
              scale: lerpDouble(
                1,
                AppViewer.dismissMinScale,
                _motion.dismissProgress(height),
              ),
              child: child,
            ),
          ),
          child: _pageView(repo, ids),
        ),
      ),
    );
  }

  Widget _pageView(ScreenshotRepository repo, List<String> ids) {
    final bool reduceMotion = context.reduceMotion;
    final Map<String, int> indexOf = {
      for (int i = 0; i < ids.length; i++) ids[i]: i,
    };
    return PageView.builder(
      controller: _pages,
      physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
      itemCount: ids.length,
      findChildIndexCallback: (key) =>
          key is ValueKey<String> ? indexOf[key.value] : null,
      onPageChanged: (index) => _onPageChanged(ids, index),
      itemBuilder: (context, index) {
        final String id = ids[index];
        return PhotoPage(
          key: ValueKey<String>(id),
          asset: repo.assetFor(id),
          heroTag: screenshotHeroTag(id),
          isCurrent: id == _currentId,
          heroEnabled: id == _currentId && !reduceMotion,
          fitRequested: _motion.infoShown,
          onTap: _toggleChrome,
          onZoomChanged: (zoomed) {
            if (id == _currentId) setState(() => _zoomed = zoomed);
          },
        );
      },
    );
  }

  void _onPageChanged(List<String> ids, int index) {
    setState(() {
      _index = index;
      _currentId = ids[index];
      _zoomed = false;
    });
    _precacheNeighbors(ids, index);
  }

  /// Komşu sayfaların tam çözünürlüğü önceden çözülür: kaydırınca bulanık
  /// kare görünmesin.
  void _precacheNeighbors(List<String> ids, int index) {
    final ScreenshotRepository repo = ref.read(screenshotRepositoryProvider);
    for (final int neighbor in [index - 1, index + 1]) {
      if (neighbor < 0 || neighbor >= ids.length) continue;
      final AssetEntity? asset = repo.assetFor(ids[neighbor]);
      if (asset == null) continue;
      precacheImage(
        AssetEntityImageProvider(
          asset,
          isOriginal: false,
          thumbnailSize: viewerFullSize(asset),
        ),
        context,
      );
    }
  }

  /// Bilgi paneli alttan yükselir; başlığından sürüklenebilir, içeriği
  /// ayrıca kaydırılır.
  Widget _infoLayer(
    ScreenshotEntry entry,
    double height,
    double toolbarBottom,
  ) {
    final double panel = ViewerMotion.panelHeight(height);
    return AnimatedBuilder(
      animation: _motion.info,
      builder: (context, child) {
        final double open = math.max(0, _motion.info.value);
        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          // Yay 1'i aşarsa panel uzar; altında boşluk açılmaz.
          height: panel * math.max(1, open),
          child: Offstage(
            offstage: open <= 0,
            child: Transform.translate(
              offset: Offset(0, panel * (1 - math.min(open, 1))),
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        onVerticalDragStart: _motion.dragStart,
        onVerticalDragUpdate: (details) => _motion.dragUpdate(details, height),
        onVerticalDragEnd: (details) => _motion.dragEnd(details, height),
        onVerticalDragCancel: () => _motion.dragCancel(height),
        child: ViewerInfoPanel(
          key: ValueKey<String>(entry.assetId),
          entry: entry,
          bottomInset: AppSizes.navBarHeight + toolbarBottom + AppSpacing.md,
          onMove: () => _move(entry),
          onTag: _searchTag,
        ),
      ),
    );
  }

  /// Üst çubuk ve araç çubuğu: arayüzle birlikte söner, aşağı çekişte solar.
  Widget _chromeFade(double height, Widget child) {
    return IgnorePointer(
      ignoring: !_chromeVisible,
      child: ExcludeSemantics(
        excluding: !_chromeVisible,
        child: AnimatedBuilder(
          animation: Listenable.merge([_chrome, _motion.drag]),
          child: child,
          builder: (context, child) => Opacity(
            opacity:
                _chrome.value.clamp(0.0, 1.0) *
                (1 - _motion.dismissProgress(height)),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _toolbar(ScreenshotEntry entry) {
    final l10n = context.l10n;
    final bool infoOpen = _motion.infoShown;
    final List<ToolbarAction> actions = [
      ToolbarAction(
        icon: AppIcons.share,
        label: l10n.shareAction,
        onPressed: () =>
            _whileBusy(() => shareScreenshots(context, ref, [entry.assetId])),
      ),
      ToolbarAction(
        icon: infoOpen ? AppIcons.infoFill : AppIcons.info,
        label: l10n.infoAction,
        onPressed: () {
          Haptics.tap();
          _motion.setInfo(!infoOpen);
        },
      ),
      ToolbarAction(
        icon: AppIcons.move,
        label: l10n.moveAction,
        onPressed: () => _move(entry),
      ),
      ToolbarAction(
        icon: AppIcons.delete,
        label: l10n.deleteAction,
        destructive: true,
        onPressed: () => _delete(entry.assetId),
      ),
    ];
    return GlassToolbar(
      alignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final ToolbarAction action in actions)
          ToolbarButton(action: action, enabled: !_busy),
      ],
    );
  }

  /// Tek dokunuş: panel açıksa kapatır, değilse arayüzü gizler/gösterir.
  void _toggleChrome() {
    if (_motion.infoShown) {
      _motion.setInfo(false);
      return;
    }
    _setChrome(!_chromeVisible);
  }

  void _setChrome(bool visible) {
    if (_chromeVisible == visible) return;
    setState(() => _chromeVisible = visible);
    final double target = visible ? 1 : 0;
    if (context.reduceMotion) {
      _chrome.animateTo(target, duration: AppMotion.reducedCrossfade);
      return;
    }
    _chrome.animateWith(
      SpringSimulation(
        AppSprings.snappy,
        _chrome.value,
        target,
        _chrome.velocity,
      ),
    );
  }

  /// Panel açılırken arayüz de görünür olur (araç çubuğu panelin üstünde).
  void _onInfoChanged(bool open) {
    // Bilgi butonunun ikonu ve sayfanın sığdırma isteği panel hedefini izler.
    setState(() {});
    if (open) _setChrome(true);
  }

  void _close() {
    if (_closing || !mounted) return;
    setState(() => _closing = true);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.library);
    }
  }

  Future<T> _whileBusy<T>(Future<T> Function() task) async {
    setState(() => _busy = true);
    try {
      return await task();
    } finally {
      // Beklenmedik hata olsa da araç çubuğu kilitli kalmaz.
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _move(ScreenshotEntry entry) async {
    await moveScreenshots(
      context,
      ref,
      [entry.assetId],
      currentCategory: entry.category,
      currentBoardId: entry.boardId,
    );
  }

  /// Onayı iOS'un kendi silme diyaloğu ister. Kapsamda görüntü kalmadıysa
  /// görüntüleyici kapanır; kaldıysa sıradaki gelir.
  Future<void> _delete(String assetId) async {
    final int deleted = await _whileBusy(
      () => deleteScreenshots(context, ref, [assetId]),
    );
    if (deleted == 0 || !mounted) return;
    final ScreenshotRepository repo = ref.read(screenshotRepositoryProvider);
    if (_scope.every((id) => repo.entryFor(id) == null)) _close();
  }

  /// Etikete dokunuldu: Ara sekmesi o etiketle açılır (görüntüleyici kapanır).
  void _searchTag(String tag) {
    ref.read(searchRequestProvider.notifier).request(tag);
    context.go(AppRoutes.search);
  }
}

/// Açılan görüntü artık yoksa (silinmiş ya da deep link geçersiz): kısa
/// açıklama, ardından görüntüleyici kendiliğinden kapanır.
class _MissingScreenshot extends StatefulWidget {
  const _MissingScreenshot({required this.onClose});

  final VoidCallback onClose;

  @override
  State<_MissingScreenshot> createState() => _MissingScreenshotState();
}

class _MissingScreenshotState extends State<_MissingScreenshot> {
  Timer? _autoClose;

  @override
  void initState() {
    super.initState();
    _autoClose = Timer(AppViewer.missingAutoClose, widget.onClose);
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: SafeArea(
        child: EmptyStateView(
          icon: AppIcons.photo,
          title: l10n.viewerMissingTitle,
          message: l10n.viewerMissingBody,
          actionLabel: l10n.doneAction,
          onAction: widget.onClose,
        ),
      ),
    );
  }
}

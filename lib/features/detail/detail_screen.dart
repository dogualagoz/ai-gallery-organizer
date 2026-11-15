// Fotoğraflar tarzı görüntüleyici: açıldığı koleksiyonda sayfa sayfa kaydırma,
// aşağı çekip kapatma, yukarı çekince bilgi paneli; dokunuş arayüzü gizler ve
// zemini siyaha çevirir. Alt cam çubukta Paylaş / Bilgi / Taşı / Sil.
import 'dart:async';
import 'dart:math' as math;

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
import '../../core/router/app_routes.dart';
import '../../core/services/haptic_service.dart';
import '../../core/utils/motion_physics.dart';
import '../../core/widgets/empty_state_view.dart';
import '../gallery/data/screenshot_repository.dart';
import '../gallery/providers/gallery_provider.dart';
import '../gallery/screenshot_actions.dart';
import '../search/search_request_provider.dart';
import 'viewer_motion.dart';
import 'viewer_scope_snapshot.dart';
import 'widgets/photo_page.dart';
import 'widgets/viewer_layers.dart';
import 'widgets/viewer_toolbar.dart';
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
  late int _index;
  late final PageController _pages;
  late final ViewerMotion _motion;

  /// Görünen sayfanın kimliği. Sayfa değişince ekran yeniden kurulmaz;
  /// yalnız sayfalar, bilgi paneli ve çubuklar bunu dinler.
  late final ValueNotifier<String> _current;

  /// Son kurulumdaki kapsam (kayıtları hâlâ var olanlar).
  List<String> _ids = const [];

  /// 1 = arayüz görünür (sistem zemini), 0 = gizli (siyah zemin).
  late final AnimationController _chrome;

  /// Arayüzün hedef görünürlüğü (dokunuş ve erişilebilirlik için).
  final ValueNotifier<bool> _chromeVisible = ValueNotifier(true);

  /// Görünen sayfa yakınlaştırılmışken kaydırma ve aşağı çekiş kilitlenir.
  final ValueNotifier<bool> _zoomed = ValueNotifier(false);

  late final Listenable _chromeChanges = Listenable.merge([
    _chrome,
    _motion.drag,
  ]);
  late final Listenable _pageState = Listenable.merge([
    _current,
    _motion.infoTarget,
  ]);

  /// Paylaşım dosyaları hazırlanırken ya da silme onayı beklenirken true.
  bool _busy = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _scope = _initialScope();
    _current = ValueNotifier(widget.assetId);
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
    _current.dispose();
    _chromeVisible.dispose();
    _zoomed.dispose();
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
    final ScreenshotRepository repo = ref.watch(screenshotRepositoryProvider);
    // Ekran yalnız kapsamdan kayıt düşünce (silme) ya da görseller yüklenince
    // yeniden kurulur; analiz/taşıma sonuçlarını bilgi paneli kendisi izler.
    // Analiz turunun peş peşe galeri olayları sayfaları yeniden kurmaz.
    final List<String> ids = ref
        .watch(
          galleryProvider.select((_) => ViewerScopeSnapshot.of(repo, _scope)),
        )
        .ids;
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
    final double toolbarBottom = AppSizes.navBarBottomGap(
      MediaQuery.paddingOf(context).bottom,
    );

    return ValueListenableBuilder<bool>(
      valueListenable: _chromeVisible,
      builder: (context, visible, child) => AnnotatedRegion(
        value: visible && Theme.of(context).brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        child: child!,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          fit: StackFit.expand,
          children: [
            ViewerBackdrop(
              chrome: _chrome,
              motion: _motion,
              changes: _chromeChanges,
              height: constraints.maxHeight,
            ),
            _pagesLayer(repo, ids, constraints.maxHeight),
            ..._currentLayers(repo, constraints.maxHeight, toolbarBottom),
          ],
        ),
      ),
    );
  }

  Widget _pagesLayer(
    ScreenshotRepository repo,
    List<String> ids,
    double height,
  ) {
    return ViewerPagesLayer(
      motion: _motion,
      height: height,
      zoomed: _zoomed,
      pages: (context, zoomed) => ViewerPageView(
        controller: _pages,
        ids: ids,
        assetFor: repo.assetFor,
        current: _current,
        infoTarget: _motion.infoTarget,
        pageState: _pageState,
        zoomed: zoomed,
        onPageChanged: _onPageChanged,
        onTap: _toggleChrome,
        onZoomChanged: _onZoomChanged,
      ),
    );
  }

  /// Görünen kayda bağlı katmanlar: bilgi paneli, üst çubuk, araç çubuğu.
  /// Sayfa değişince yalnız bunlar yeniden kurulur.
  List<Widget> _currentLayers(
    ScreenshotRepository repo,
    double height,
    double toolbarBottom,
  ) {
    // Kayıt silinip liste henüz tazelenmediyse katman bir kare boş kalır;
    // ardından _syncIndex sıradaki kayda geçer.
    Widget forCurrent(Widget Function(ScreenshotEntry entry) build) =>
        ValueListenableBuilder<String>(
          valueListenable: _current,
          builder: (context, id, _) {
            final ScreenshotEntry? entry = repo.entryFor(id);
            return entry == null ? const SizedBox.shrink() : build(entry);
          },
        );
    Widget fade(Widget child) => ViewerChromeFade(
      visible: _chromeVisible,
      chrome: _chrome,
      motion: _motion,
      changes: _chromeChanges,
      height: height,
      child: child,
    );

    return [
      forCurrent((entry) => _infoLayer(repo, entry, height, toolbarBottom)),
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: fade(
          forCurrent(
            (entry) => ViewerTopBar(createdAt: entry.createdAt, onBack: _close),
          ),
        ),
      ),
      Positioned(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: toolbarBottom,
        child: fade(forCurrent(_toolbar)),
      ),
    ];
  }

  /// Görünen kaydın bilgi paneli; yalnız bu katman kaydın analiz/taşıma
  /// alanlarını izler (galerinin geri kalanı paneli yenilemez).
  Widget _infoLayer(
    ScreenshotRepository repo,
    ScreenshotEntry entry,
    double height,
    double toolbarBottom,
  ) {
    return Consumer(
      builder: (context, ref, _) {
        ref.watch(
          galleryProvider.select(
            (_) => viewerEntryFields(repo.entryFor(entry.assetId)),
          ),
        );
        return ViewerInfoLayer(
          motion: _motion,
          height: height,
          entry: entry,
          bottomInset: AppSizes.navBarHeight + toolbarBottom + AppSpacing.md,
          onMove: () => _move(entry.assetId),
          onTag: _searchTag,
        );
      },
    );
  }

  /// Liste değişince (silme) bulunulan öğe yeniden konumlanır: silinenin
  /// yerine sıradaki gelir (Fotoğraflar), sondaysa bir öncekine geçilir.
  /// build içinde çalışır çünkü liste yalnız build'de (galeri izlenirken)
  /// bilinir; sayfa denetleyicisi kare sonrasında hizalanır.
  ///
  /// Notifier'lar build içinde yazılabilir: tüm dinleyicileri bu ekranın alt
  /// ağacındadır, bu kare içinde ebeveynden sonra kurulurlar. Ağaç dışından
  /// bir dinleyici eklenirse yazım kare sonrasına alınmalı.
  void _syncIndex(List<String> ids) {
    _ids = ids;
    final int found = ids.indexOf(_current.value);
    final int index = found >= 0 ? found : math.min(_index, ids.length - 1);
    if (found < 0) {
      _current.value = ids[index];
      _zoomed.value = false;
    }
    if (index == _index) return;
    _index = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pages.hasClients) _pages.jumpToPage(_index);
    });
  }

  void _onPageChanged(int index) {
    _index = index;
    _current.value = _ids[index];
    _zoomed.value = false;
    // Silinmiş ama listeden henüz düşmemiş sayfaya gelindiyse kapsam hemen
    // yeniden hesaplanır (eskiden her sayfa değişimi bunu yapardı).
    if (ref.read(screenshotRepositoryProvider).entryFor(_ids[index]) == null) {
      setState(() {});
    }
    _precacheNeighbors(_ids, index);
  }

  void _onZoomChanged(String id, bool zoomed) {
    if (id == _current.value) _zoomed.value = zoomed;
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

  Widget _toolbar(ScreenshotEntry entry) {
    return ViewerToolbar(
      infoOpen: _motion.infoTarget,
      enabled: !_busy,
      onShare: () =>
          _whileBusy(() => shareScreenshots(context, ref, [entry.assetId])),
      onInfo: () {
        Haptics.tap();
        _motion.setInfo(!_motion.infoShown);
      },
      onMove: () => _move(entry.assetId),
      onDelete: () => _delete(entry.assetId),
    );
  }

  /// Tek dokunuş: panel açıksa kapatır, değilse arayüzü gizler/gösterir.
  void _toggleChrome() {
    if (_motion.infoShown) {
      _motion.setInfo(false);
      return;
    }
    _setChrome(!_chromeVisible.value);
  }

  void _setChrome(bool visible) {
    if (_chromeVisible.value == visible) return;
    _chromeVisible.value = visible;
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
  /// Bilgi butonu ve sayfanın sığdırma isteği panel hedefini kendisi izler.
  void _onInfoChanged(bool open) {
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

  /// Güncel yerleşim dokunuş anında okunur (taşıma/analiz sonrası çubuk
  /// yeniden kurulmamış olabilir).
  Future<void> _move(String assetId) async {
    final ScreenshotEntry? entry = ref
        .read(screenshotRepositoryProvider)
        .entryFor(assetId);
    if (entry == null) return;
    await moveScreenshots(
      context,
      ref,
      [assetId],
      currentCategory: entry.category,
      currentBoardId: entry.boardId,
    );
  }

  /// Onayı iOS'un kendi silme diyaloğu ister. Kapsamda görüntü kalmadıysa
  /// görüntüleyici kapanır; kaldıysa sıradaki gelir.
  Future<void> _delete(String assetId) async {
    final List<String> deleted = await _whileBusy(
      () => deleteScreenshots(context, ref, [assetId]),
    );
    if (deleted.isEmpty || !mounted) return;
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

// Temizle sekmesi: analiz bekleyen ya da "Diğer"e düşmüş ekran görüntüleri
// için kart destesi — sola sil (onaylanana kadar bekler), sağa atla, yukarı
// seçili kategoriye ata. Bekleyen silmeler sekme değişse de korunur.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/ui_constants.dart';
import '../../core/l10n/category_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/screenshot_category.dart';
import '../../core/models/screenshot_entry.dart';
import '../../core/services/category_names_service.dart';
import '../../core/services/entitlement_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/review_service.dart';
import '../../core/widgets/app_nav_scaffold.dart';
import '../../core/widgets/status_toast.dart';
import '../gallery/data/screenshot_repository.dart';
import '../gallery/providers/gallery_provider.dart';
import '../gallery/screenshot_actions.dart';
import '../gallery/widgets/gallery_error_view.dart';
import 'providers/clean_session_provider.dart';
import 'swipe_decision.dart';
import 'widgets/category_picker_sheet.dart';
import 'widgets/clean_deck_layout.dart';
import 'widgets/clean_finished_view.dart';
import 'widgets/clean_info_sheet.dart';
import 'widgets/swipe_deck.dart';

class SortingScreen extends ConsumerStatefulWidget {
  const SortingScreen({super.key});

  @override
  ConsumerState<SortingScreen> createState() => _SortingScreenState();
}

class _SortingScreenState extends ConsumerState<SortingScreen> {
  final SwipeDeckController _deck = SwipeDeckController();

  /// Yukarı kaydırmanın hedefi; destenin üstündeki kapsülden değiştirilir.
  ScreenshotCategory _target = ScreenshotCategory.social;

  /// Son çizilen deste sırası: kart gidince kimliği kayda çevirmek için.
  List<ScreenshotEntry> _queue = const [];

  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    // 7 gün boşta kalan kullanıcı ekrana taze haftalık swipe kotasıyla girsin.
    // Pencere dolmuşsa provider state'i değişir; widget kurulurken yazılmasın.
    Future.microtask(() {
      if (mounted) ref.read(entitlementProvider.notifier).ensureWeeklyWindow();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bool canUndo = ref.watch(
      cleanSessionProvider.select((session) => session.canUndo),
    );
    final AsyncValue<List<ScreenshotEntry>> gallery = ref.watch(
      galleryProvider,
    );
    return AppNavScaffold(
      title: l10n.tabClean,
      scrollable: false,
      leading: NavBarButton.icon(
        icon: AppIcons.undo,
        label: l10n.undoAction,
        // Silme sürerken geri alınan kart silinip yine desteye dönmesin.
        onPressed: canUndo && !_deleting ? _undo : null,
      ),
      trailing: NavBarButton.icon(
        icon: AppIcons.info,
        label: l10n.cleanInfoTitle,
        onPressed: _showInfo,
      ),
      slivers: [
        SliverFillRemaining(
          child: Padding(
            // Alt boşluk yüzen sekme çubuğu kadar (kabuk bunu padding'e yazar).
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              MediaQuery.paddingOf(context).bottom,
            ),
            child: gallery.when(
              skipLoadingOnReload: true,
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (error, _) => GalleryErrorView(error: error),
              data: _content,
            ),
          ),
        ),
      ],
    );
  }

  /// Galeri yüklüyken gövde: deste ve altındaki bitiş katmanı (deste bitti
  /// ya da kota doldu). Deste hep kurulu kalır: kotanın son kartı da uçuşunu
  /// tamamlar.
  Widget _content(List<ScreenshotEntry> entries) {
    final CleanSession session = ref.watch(cleanSessionProvider);
    // Deste yalnız swipe hakkını izler; analiz sayaçları yenilemez.
    final (bool canSwipe, bool isPro, int swipesUsed) = ref.watch(
      entitlementProvider.select(
        (state) => (state.canSwipe, state.isPro, state.swipesUsed),
      ),
    );
    final int pending = ref.watch(pendingDeleteIdsProvider).length;
    final List<ScreenshotEntry> queue = session.queue(entries);
    _queue = queue;
    final bool locked = queue.isNotEmpty && !canSwipe;
    final List<ScreenshotEntry> visible = locked ? const [] : queue;
    final ScreenshotRepository repo = ref.watch(screenshotRepositoryProvider);
    final String targetLabel = _target.displayName(
      context.l10n,
      ref.watch(categoryNamesProvider),
    );
    SwipeDeckItem? item(int index) => index < visible.length
        ? SwipeDeckItem(
            visible[index].assetId,
            repo.assetFor(visible[index].assetId),
          )
        : null;

    return CleanDeckLayout(
      top: item(0),
      next: item(1),
      remaining: visible.length,
      finished: _finishedLayer(
        locked: locked,
        empty: queue.isEmpty,
        pending: pending,
        session: session,
        entries: entries,
      ),
      freeSwipesLeft: isPro
          ? null
          : math.max(0, FreeLimits.swipeSorts - swipesUsed),
      assignIcon: _target.icon,
      assignLabel: targetLabel,
      deck: _deck,
      onSwipe: _onSwipe,
      onPickTarget: _pickTarget,
      pending: pending,
      // Deste bitince bekleyenler bitiş görünümünün kendi CTA'sında.
      showPending: queue.isNotEmpty && pending > 0,
      deleting: _deleting,
      onDelete: _commitDeletes,
    );
  }

  /// Destenin altındaki bitiş katmanı: hak dolduysa kilit, deste bittiyse
  /// bitiş görünümü (atlananlar bu oturumda atlanıp galeride duranlardır).
  Widget? _finishedLayer({
    required bool locked,
    required bool empty,
    required int pending,
    required CleanSession session,
    required List<ScreenshotEntry> entries,
  }) {
    if (locked) return const CleanLimitView();
    if (!empty) return null;
    return CleanFinishedView(
      pending: pending,
      skipped: entries
          .where((entry) => session.skipped.contains(entry.assetId))
          .length,
      deleting: _deleting,
      onDelete: _commitDeletes,
    );
  }

  /// Deste kartı gönderdi: haptik aynı karede, kayıt hemen işlenir.
  void _onSwipe(String id, SwipeDirection direction) {
    final ScreenshotEntry? entry = _queue
        .where((candidate) => candidate.assetId == id)
        .firstOrNull;
    if (entry == null) return;
    switch (direction) {
      case SwipeDirection.left:
        Haptics.confirm();
      case SwipeDirection.up:
        Haptics.tick();
      case SwipeDirection.right:
        Haptics.tap();
    }
    _applySwipe(entry, direction);
  }

  Future<void> _applySwipe(
    ScreenshotEntry entry,
    SwipeDirection direction,
  ) async {
    final StatusToaster toaster = StatusToaster.of(context);
    final String failure = context.l10n.cleanAssignFailed;
    final bool applied = await ref
        .read(cleanSessionProvider.notifier)
        .swipe(entry, direction, _target);
    if (!applied) toaster.show(failure, tone: StatusToastTone.error);
  }

  /// Son kaydırmayı geri alır: kart çıktığı kenardan desteye döner.
  Future<void> _undo() async {
    final CleanMove? move = ref.read(cleanSessionProvider).history.lastOrNull;
    if (move == null) return;
    Haptics.tap();
    final StatusToaster toaster = StatusToaster.of(context);
    final String failure = context.l10n.undoFailed;
    final bool restored = await ref
        .read(cleanSessionProvider.notifier)
        .undo(onReturn: () => _deck.expectReturn(move.assetId, move.direction));
    if (!restored) toaster.show(failure, tone: StatusToastTone.error);
  }

  /// Bekleyenleri siler; onayı iOS'un kendi diyaloğu ister. Kullanıcı
  /// vazgeçerse liste olduğu gibi kalır (yeniden sorulmaz, çubuk durur).
  Future<void> _commitDeletes() async {
    final List<String> ids = ref.read(pendingDeleteIdsProvider);
    if (ids.isEmpty || _deleting) return;
    // Oturum widget'tan bağımsız: ekran kapansa da silinenler düşmeli (ref
    // dispose sonrası kullanılamaz, notifier önceden alınır).
    final CleanSessionNotifier session = ref.read(
      cleanSessionProvider.notifier,
    );
    setState(() => _deleting = true);
    final List<String> deleted = await deleteScreenshots(context, ref, ids);
    session.markDeleted(deleted);
    if (!mounted) return;
    setState(() => _deleting = false);
    if (deleted.isEmpty) return;
    Haptics.confirm();
    // Temizlik sonrası olumlu an: değerlendirme iste (cooldown'lı).
    unawaited(ref.read(reviewServiceProvider).requestIfAppropriate());
  }

  Future<void> _pickTarget() async {
    final ScreenshotCategory? picked = await showCategoryPickerSheet(
      context,
      selected: _target,
    );
    if (picked != null && mounted) setState(() => _target = picked);
  }

  void _showInfo() {
    final bool isPro = ref.read(entitlementProvider).isPro;
    showCleanInfoSheet(
      context,
      freeSwipes: isPro ? null : FreeLimits.swipeSorts,
    );
  }
}

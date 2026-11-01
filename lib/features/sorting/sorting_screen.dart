// Temizle sekmesi: analiz bekleyen ya da "Diğer"e düşmüş ekran görüntüleri
// için kart destesi — sola sil (onaylanana kadar bekler), sağa atla, yukarı
// seçili kategoriye ata. Bekleyen silmeler sekme değişse de korunur.
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/ui_constants.dart';
import '../../core/l10n/category_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/screenshot_category.dart';
import '../../core/models/screenshot_entry.dart';
import '../../core/router/app_router.dart';
import '../../core/services/category_names_service.dart';
import '../../core/services/entitlement_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/photo_permission_service.dart';
import '../../core/services/review_service.dart';
import '../../core/widgets/app_nav_scaffold.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/spring_visibility.dart';
import '../../core/widgets/status_toast.dart';
import '../gallery/data/screenshot_repository.dart';
import '../gallery/providers/gallery_provider.dart';
import '../gallery/screenshot_actions.dart';
import '../paywall/open_paywall.dart';
import 'providers/clean_session_provider.dart';
import 'swipe_decision.dart';
import 'widgets/category_picker_sheet.dart';
import 'widgets/clean_controls.dart';
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
    ref.read(entitlementProvider.notifier).ensureWeeklyWindow();
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
              error: (error, _) => error is PhotoAccessDeniedException
                  ? const PermissionDeniedView()
                  : EmptyStateView(
                      icon: AppIcons.error,
                      title: l10n.galleryLoadFailedTitle,
                      message: l10n.galleryLoadFailedBody,
                      actionLabel: l10n.retryAction,
                      onAction: () => ref.invalidate(galleryProvider),
                    ),
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
    final EntitlementState entitlement = ref.watch(entitlementProvider);
    final int pending = ref.watch(pendingDeleteIdsProvider).length;
    final List<ScreenshotEntry> queue = session.queue(entries);
    _queue = queue;
    final bool locked = queue.isNotEmpty && !entitlement.canSwipe;
    return _deckLayout(
      queue: locked ? const [] : queue,
      finished: locked
          ? const _LimitView()
          : queue.isEmpty
          ? _finished(session, entries, pending)
          : null,
      // Deste bitince bekleyenler bitiş görünümünün kendi CTA'sında.
      showPending: queue.isNotEmpty && pending > 0,
      pending: pending,
      freeSwipesLeft: entitlement.isPro
          ? null
          : math.max(0, FreeLimits.swipeSorts - entitlement.swipesUsed),
    );
  }

  /// Durum satırı + deste + bekleyen silme yuvası + eylem satırı. Satırlar
  /// deste bitince de yer kaplar: son kart uçarken kart boyu değişmez.
  Widget _deckLayout({
    required List<ScreenshotEntry> queue,
    required Widget? finished,
    required bool showPending,
    required int pending,
    required int? freeSwipesLeft,
  }) {
    final ScreenshotRepository repo = ref.watch(screenshotRepositoryProvider);
    final String targetLabel = _target.displayName(
      context.l10n,
      ref.watch(categoryNamesProvider),
    );
    final bool hasCards = queue.isNotEmpty;
    SwipeDeckItem? item(int index) => index < queue.length
        ? SwipeDeckItem(
            queue[index].assetId,
            repo.assetFor(queue[index].assetId),
          )
        : null;

    return Column(
      children: [
        SpringVisibility(
          visible: hasCards,
          child: _DeckStatus(
            remaining: queue.length,
            freeSwipesLeft: freeSwipesLeft,
            targetLabel: targetLabel,
            onPickTarget: _pickTarget,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              ?finished,
              SwipeDeck(
                top: item(0),
                next: item(1),
                controller: _deck,
                onSwipe: _onSwipe,
                assignIcon: _target.icon,
                assignLabel: targetLabel,
              ),
            ],
          ),
        ),
        _pendingSlot(pending, visible: showPending),
        SpringVisibility(
          visible: hasCards,
          child: CleanActionRow(
            assignIcon: _target.icon,
            assignLabel: targetLabel,
            onSwipe: hasCards ? _deck.swipe : null,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  /// Bekleyen silme kapsülünün sabit yuvası (yer hep ayrılır).
  Widget _pendingSlot(int pending, {required bool visible}) {
    return SizedBox(
      height: AppDeck.pendingSlot,
      child: Center(
        child: SpringVisibility(
          visible: visible,
          child: PendingDeleteBar(
            count: pending,
            deleting: _deleting,
            onDelete: _commitDeletes,
          ),
        ),
      ),
    );
  }

  /// Deste bitti: bekleyen silme varsa tamamlatır, atlanan varsa yeniden
  /// gösterir, yoksa Kütüphane'ye yönlendirir.
  Widget _finished(
    CleanSession session,
    List<ScreenshotEntry> entries,
    int pending,
  ) {
    final l10n = context.l10n;
    if (pending > 0) {
      return EmptyStateView(
        icon: AppIcons.delete,
        title: l10n.sortingPendingDeleteCount(pending),
        message: l10n.sortingFinishConfirmBody,
        actionLabel: l10n.sortingFinishAction(pending),
        onAction: _deleting ? null : _commitDeletes,
        secondaryActionLabel: l10n.sortingFinishKeep,
        onSecondaryAction: _deleting
            ? null
            : ref.read(cleanSessionProvider.notifier).keepPendingDeletes,
      );
    }
    final int skipped = entries
        .where((entry) => session.skipped.contains(entry.assetId))
        .length;
    void backToLibrary() => context.go(AppRoutes.library);
    if (skipped > 0) {
      return EmptyStateView(
        icon: AppIcons.done,
        title: l10n.cleanDoneTitle,
        message: l10n.cleanSkippedBody(skipped),
        actionLabel: l10n.cleanShowSkipped,
        onAction: ref.read(cleanSessionProvider.notifier).resetSkipped,
        secondaryActionLabel: l10n.cleanBackToLibrary,
        onSecondaryAction: backToLibrary,
      );
    }
    return EmptyStateView(
      icon: AppIcons.done,
      title: l10n.sortingEmptyTitle,
      message: l10n.sortingEmptyBody,
      actionLabel: l10n.cleanBackToLibrary,
      onAction: backToLibrary,
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
    ref.read(reviewServiceProvider).requestIfAppropriate();
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

/// Destenin üstü: kalan sayı (ücretsizde kalan hak) + yukarı hedefi.
class _DeckStatus extends StatelessWidget {
  const _DeckStatus({
    required this.remaining,
    required this.freeSwipesLeft,
    required this.targetLabel,
    required this.onPickTarget,
  });

  final int remaining;
  final int? freeSwipesLeft;
  final String targetLabel;
  final VoidCallback onPickTarget;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final int? swipes = freeSwipesLeft;
    return Row(
      children: [
        Expanded(
          child: Text(
            swipes == null
                ? l10n.sortingRemainingCount(remaining)
                : l10n.cleanStatusWithSwipes(remaining, swipes),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        CleanTargetChip(label: targetLabel, onPressed: onPickTarget),
      ],
    );
  }
}

/// Ücretsiz haftalık kaydırma hakkı bitti.
class _LimitView extends StatelessWidget {
  const _LimitView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return EmptyStateView(
      icon: AppIcons.lock,
      title: l10n.sortingLimitTitle,
      message: l10n.sortingLimitBody,
      actionLabel: l10n.paywallTitle,
      onAction: () => openPaywall(context),
    );
  }
}

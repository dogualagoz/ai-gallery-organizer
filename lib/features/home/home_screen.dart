// Home ekranı: analiz banner'ı + panolar (sistem+özel) + son ekran görüntüleri.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/ui_constants.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/board.dart';
import '../../core/models/screenshot_category.dart';
import '../../core/models/screenshot_entry.dart';
import '../../core/router/app_router.dart';
import '../../core/services/category_names_service.dart';
import '../../core/services/entitlement_service.dart';
import '../../core/services/review_service.dart';
import '../../core/widgets/pro_badge.dart';
import '../analysis/providers/analysis_queue_provider.dart';
import '../analysis/providers/auto_sort_provider.dart';
import '../analysis/widgets/analyze_card.dart';
import '../analysis/widgets/auto_sort_chip.dart';
import '../analysis/widgets/category_target_scope.dart';
import '../analysis/widgets/scene_particles.dart';
import '../analysis/widgets/weekly_limit_badge.dart';
import '../boards/providers/board_provider.dart';
import '../boards/widgets/custom_boards_grid.dart';
import '../boards/widgets/system_boards_grid.dart';
import '../gallery/data/screenshot_repository.dart';
import '../gallery/providers/gallery_provider.dart';
import '../gallery/widgets/gallery_empty_state.dart';
import '../gallery/widgets/screenshot_grid_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ekran boyunca yaşatılır: galeri güncellendikçe Pro kullanıcı için
    // analiz kuyruğunu otomatik tetikler.
    ref.watch(autoSortControllerProvider);
    final gallery = ref.watch(galleryProvider);

    // Oturumda bir kez: uygulama açılışını say (eşik sonrası değerlendirme).
    if (!_appOpenCounted) {
      _appOpenCounted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(reviewServiceProvider).registerAppOpen();
      });
    }

    // Veri varken app bar liste içinde (SliverAppBar) — aşağı kayınca
    // içerikle birlikte gider. Boş/hata/yükleme durumlarında kaydırma
    // olmadığı için klasik sabit app bar kullanılır.
    return gallery.when(
      loading: () => Scaffold(
        appBar: _classicAppBar(context, ref),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: _classicAppBar(context, ref),
        body: GalleryEmptyState(onSync: () => _syncWithFeedback(context, ref)),
      ),
      data: (entries) => entries.isEmpty
          ? Scaffold(
              appBar: _classicAppBar(context, ref),
              body: GalleryEmptyState(
                onSync: () => _syncWithFeedback(context, ref),
              ),
            )
          : Scaffold(body: _HomeContent(entries: entries)),
    );
  }

  AppBar _classicAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      title: const _HomeTitle(),
      actions: [
        const WeeklyLimitBadge(),
        const SizedBox(width: AppSpacing.xs),
        _SyncAction(onSync: () => _syncWithFeedback(context, ref)),
      ],
    );
  }

  /// Eşitlemeyi çalıştırır; hata olursa kullanıcıya snackbar gösterir.
  static Future<void> _syncWithFeedback(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final String failureMessage = context.l10n.gallerySyncFailed;
    try {
      await ref.read(galleryProvider.notifier).sync();
    } catch (error, stackTrace) {
      debugPrint('Galeri manuel eşitleme hatası: $error\n$stackTrace');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  }
}

/// App bar başlığı: galeri adı + Pro rozetinden oluşan satır.
class _HomeTitle extends ConsumerWidget {
  const _HomeTitle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isPro = ref.watch(
      entitlementProvider.select((state) => state.isPro),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.galleryTitle),
        if (isPro) ...[const SizedBox(width: AppSpacing.sm), const ProBadge()],
      ],
    );
  }
}

/// Eşitleme aksiyon butonu.
class _SyncAction extends StatelessWidget {
  const _SyncAction({required this.onSync});

  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: context.l10n.gallerySyncTooltip,
      icon: const Icon(Icons.sync),
      onPressed: onSync,
    );
  }
}

// TEMP-AUTOSIM
bool _tempAutoSimDone = false;

/// Uygulama açılış sayacının bu oturumda bir kez işlendiğini işaretler.
bool _appOpenCounted = false;

/// Analiz kartı + panolar + son ekran görüntüleri ızgarasından oluşan gövde.
class _HomeContent extends ConsumerWidget {
  const _HomeContent({required this.entries});

  final List<ScreenshotEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(screenshotRepositoryProvider);
    final bool isPro = ref.watch(entitlementProvider).isPro;
    // Analiz sürerken anasayfada yukarı süzülen incelikli mor partikül alanı;
    // yalnız o an mount edilir (always-on değil → kayma akıcı kalır).
    final bool analyzing = ref.watch(
      analysisQueueProvider.select((s) => s.isRunning),
    );

    // TEMP-AUTOSIM
    if (kDebugMode && !_tempAutoSimDone) {
      _tempAutoSimDone = true;
      final notifier = ref.read(analysisQueueProvider.notifier);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(seconds: 3), () => notifier.simulate());
      });
    }

    // Uçan analiz fotoğraflarının hedefi olan kategori karoları ile kaynak
    // (AnalyzeCard) aynı kapsamda; uçuşlar kartın dışına çıkıp karolara iner.
    return CategoryTargetProvider(
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => ref.read(galleryProvider.notifier).sync(),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  // Sabitlenmez: aşağı kaydırınca içerikle birlikte gider.
                  pinned: false,
                  title: const _HomeTitle(),
                  // Pro'ya özel incelikli gradient — premium hissi ama sessiz.
                  flexibleSpace: isPro
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Theme.of(context).colorScheme.primaryContainer
                                    .withValues(
                                      alpha: AppOpacities.proAppBarTint,
                                    ),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: const SizedBox.expand(),
                        )
                      : null,
                  actions: [
                    // DEBUG: API harcamadan analiz animasyonunu tetikler.
                    if (kDebugMode)
                      IconButton(
                        tooltip: 'Animasyonu dene (debug)',
                        icon: const Icon(Icons.science_outlined),
                        onPressed: () =>
                            ref.read(analysisQueueProvider.notifier).simulate(),
                      ),
                    const WeeklyLimitBadge(),
                    const SizedBox(width: AppSpacing.xs),
                    _SyncAction(
                      onSync: () => HomeScreen._syncWithFeedback(context, ref),
                    ),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isPro) const AutoSortChip(),
                        AnalyzeCard(entries: entries),
                        const SizedBox(height: AppSpacing.sm),
                        _BoardsSection(entries: entries, repo: repo),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          context.l10n.homeRecentsSection,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                      ],
                    ),
                  ),
                ),
                _RecentsGrid(
                  entries: entries.take(kHomeRecentsLimit).toList(),
                  repo: repo,
                ),
                _RecentsFooter(hasMore: entries.length > kHomeRecentsLimit),
              ],
            ),
          ),
          if (analyzing)
            Positioned.fill(
              child: IgnorePointer(
                child: SceneAmbientParticles(
                  color: Theme.of(context).colorScheme.secondary,
                  count: 18,
                  maxAlpha: 0.12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Sistem kategorileri (içerik>0) + özel panolar bölümü.
class _BoardsSection extends ConsumerWidget {
  const _BoardsSection({required this.entries, required this.repo});

  final List<ScreenshotEntry> entries;
  final ScreenshotRepository repo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final List<ScreenshotCategory> nonEmptyCategories = [
      for (final category in ScreenshotCategory.values)
        if (entries.any((entry) => entry.category == category)) category,
    ];
    final List<Board> boards = ref.watch(boardsProvider).value ?? const [];
    final bool canCreate = ref.watch(entitlementProvider).canCreateBoards;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.boardsSystemSection,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (nonEmptyCategories.isEmpty)
          Text(
            l10n.boardsEmptyHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        else
          SystemBoardsGrid(
            categories: nonEmptyCategories,
            entries: entries,
            repo: repo,
            categoryNames: ref.watch(categoryNamesProvider),
          ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.boardsCustomSection,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        CustomBoardsGrid(
          boards: boards,
          entries: entries,
          repo: repo,
          canCreate: canCreate,
        ),
      ],
    );
  }
}

/// 3 sütunlu son ekran görüntüleri ızgarası.
class _RecentsGrid extends StatelessWidget {
  const _RecentsGrid({required this.entries, required this.repo});

  final List<ScreenshotEntry> entries;
  final ScreenshotRepository repo;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      // Alt boşluk (navbar örtmesin diye) _RecentsFooter'da eklenir.
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: AppSpacing.xs,
          crossAxisSpacing: AppSpacing.xs,
          // Screenshot oranına yakın dikey karo.
          childAspectRatio: 9 / 16,
        ),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final ScreenshotEntry entry = entries[index];
          return ScreenshotGridTile(
            entry: entry,
            asset: repo.assetFor(entry.assetId),
            onTap: () => context.push(AppRoutes.detail(entry.assetId)),
          );
        },
      ),
    );
  }
}

/// Son görüntüler ızgarasının altındaki alan: gerekiyorsa "Daha fazla" butonu
/// + yüzen navbar'ın son satırı örtmemesi için alt boşluk.
class _RecentsFooter extends StatelessWidget {
  const _RecentsFooter({required this.hasMore});

  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          hasMore ? AppSpacing.md : 0,
          AppSpacing.md,
          MediaQuery.paddingOf(context).bottom + AppSpacing.md,
        ),
        child: hasMore
            ? OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.recents),
                icon: const Icon(Icons.grid_view_outlined, size: 18),
                label: Text(context.l10n.homeRecentsMore),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

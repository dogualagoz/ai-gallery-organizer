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
import '../../core/services/category_order_service.dart';
import '../../core/services/entitlement_service.dart';
import '../../core/services/review_service.dart';
import '../../core/widgets/page_header.dart';
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

    // Üst bar sayfaya gömülü (PageHeader). Veri varken header kaydırılabilir
    // listenin ilk elemanı; boş/hata/yükleme durumlarında header + ortalanmış
    // içerik olarak bir Column içinde durur.
    return gallery.when(
      loading: () => Scaffold(
        body: _HomeStateScaffold(
          onSync: () => _syncWithFeedback(context, ref),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => Scaffold(
        body: _HomeStateScaffold(
          onSync: () => _syncWithFeedback(context, ref),
          child: GalleryEmptyState(onSync: () => _syncWithFeedback(context, ref)),
        ),
      ),
      data: (entries) => entries.isEmpty
          ? Scaffold(
              body: _HomeStateScaffold(
                onSync: () => _syncWithFeedback(context, ref),
                child: GalleryEmptyState(
                  onSync: () => _syncWithFeedback(context, ref),
                ),
              ),
            )
          : Scaffold(body: _HomeContent(entries: entries)),
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

/// Sayfaya gömülü üst başlık: galeri adı + Pro rozeti + aksiyonlar
/// (debug animasyon tetiği, haftalık kota rozeti, eşitleme).
class _HomeHeader extends ConsumerWidget {
  const _HomeHeader({required this.onSync});

  final VoidCallback onSync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isPro = ref.watch(
      entitlementProvider.select((state) => state.isPro),
    );
    return PageHeader(
      title: context.l10n.galleryTitle,
      titleTrailing: isPro ? const ProBadge() : null,
      // Başlık ile kota rozeti/eşitleme aynı satırda: üstteki boşluk kalkar.
      inlineTitle: true,
      actions: [
        if (kDebugMode)
          IconButton(
            tooltip: 'Animasyonu dene (debug)',
            icon: const Icon(Icons.science_outlined),
            onPressed: () =>
                ref.read(analysisQueueProvider.notifier).simulate(),
          ),
        const WeeklyLimitBadge(),
        const SizedBox(width: AppSpacing.xs),
        _SyncAction(onSync: onSync),
      ],
    );
  }
}

/// Boş/hata/yükleme durumlarında gömülü header + ortalanmış içerik.
class _HomeStateScaffold extends StatelessWidget {
  const _HomeStateScaffold({required this.onSync, required this.child});

  final VoidCallback onSync;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HomeHeader(onSync: onSync),
        Expanded(child: child),
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

    // Uçan analiz fotoğraflarının hedefi olan kategori karoları ile kaynak
    // (AnalyzeCard) aynı kapsamda; uçuşlar kartın dışına çıkıp karolara iner.
    return CategoryTargetProvider(
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => ref.read(galleryProvider.notifier).sync(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _HomeHeader(
                    onSync: () => HomeScreen._syncWithFeedback(context, ref),
                  ),
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
          // Partiküller alttan yukarı süzülür ama üst menü bar'ın (status bar
          // + toolbar) altında kalmalı; bu yüzden üstten o kadar inset'lenir.
          // Tur bitince katman aniden değil, AnimatedSwitcher ile yavaşça söner.
          Positioned(
            top: MediaQuery.paddingOf(context).top + kToolbarHeight,
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 900),
                child: analyzing
                    ? Stack(
                        key: const ValueKey<String>('analysis-fx'),
                        children: [
                          // En arkada: tabandan yükselen nabızlı mor ışıma.
                          SceneAiGlow(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          // Alttan yükselen mor duman (bir şeyler pişiyor hissi).
                          SceneRisingSmoke(
                            color: Theme.of(context).colorScheme.secondary,
                            count: 20,
                            maxAlpha: 0.26,
                          ),
                          // İnce yükselen zerreler — dumanın üstünde parıltı.
                          SceneAmbientParticles(
                            color: Theme.of(context).colorScheme.secondary,
                            count: 18,
                            maxAlpha: 0.12,
                          ),
                          // Morun içinden yükselen net, opak küçük noktalar.
                          SceneAmbientParticles(
                            color: Theme.of(context).colorScheme.secondary,
                            count: 21,
                            maxAlpha: 0.9,
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
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
    final bool editing = ref.watch(boardsEditModeProvider);
    final List<ScreenshotCategory> nonEmptyCategories = [
      for (final category in ScreenshotCategory.values)
        if (entries.any((entry) => entry.category == category)) category,
    ];
    // Kayıtlı kullanıcı sırasına göre diz (düzenleme modunda sürüklenebilir).
    ref.watch(categoryOrderProvider);
    final List<ScreenshotCategory> sortedCategories = ref
        .read(categoryOrderProvider.notifier)
        .sortVisible(nonEmptyCategories);
    final List<Board> boards = ref.watch(boardsProvider).value ?? const [];
    final bool canCreate = ref.watch(entitlementProvider).canCreateBoards;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: l10n.boardsSystemSection, editing: editing),
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
            categories: sortedCategories,
            entries: entries,
            repo: repo,
            categoryNames: ref.watch(categoryNamesProvider),
          ),
        const SizedBox(height: AppSpacing.lg),
        _SectionHeader(title: l10n.boardsCustomSection, editing: editing),
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

/// Bölüm başlığı; düzenleme modunda sağda "Bitti" butonu gösterir.
class _SectionHeader extends ConsumerWidget {
  const _SectionHeader({required this.title, required this.editing});

  final String title;
  final bool editing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (editing)
          TextButton(
            onPressed: () =>
                ref.read(boardsEditModeProvider.notifier).disable(),
            child: Text(context.l10n.boardsEditDone),
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

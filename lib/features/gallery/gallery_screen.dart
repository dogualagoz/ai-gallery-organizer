// Ana galeri ekranı: screenshot ızgarası + analiz banner'ı + eşitleme + boş/hata durumları.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/ui_constants.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/screenshot_entry.dart';
import '../../core/router/app_router.dart';
import '../analysis/widgets/analysis_banner.dart';
import 'data/screenshot_repository.dart';
import 'providers/gallery_provider.dart';
import 'widgets/gallery_empty_state.dart';
import 'widgets/screenshot_grid_tile.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final gallery = ref.watch(galleryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.galleryTitle),
        actions: [
          IconButton(
            tooltip: l10n.sortingTitle,
            icon: const Icon(Icons.swipe_outlined),
            onPressed: () => context.push(AppRoutes.sorting),
          ),
          IconButton(
            tooltip: l10n.searchTitle,
            icon: const Icon(Icons.search),
            onPressed: () => context.push(AppRoutes.search),
          ),
          IconButton(
            tooltip: l10n.gallerySyncTooltip,
            icon: const Icon(Icons.sync),
            onPressed: () => _syncWithFeedback(context, ref),
          ),
        ],
      ),
      body: gallery.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            GalleryEmptyState(onSync: () => _syncWithFeedback(context, ref)),
        data: (entries) => entries.isEmpty
            ? GalleryEmptyState(onSync: () => _syncWithFeedback(context, ref))
            : _GalleryGrid(entries: entries),
      ),
    );
  }

  /// Eşitlemeyi çalıştırır; hata olursa kullanıcıya snackbar gösterir.
  Future<void> _syncWithFeedback(BuildContext context, WidgetRef ref) async {
    final String failureMessage = context.l10n.gallerySyncFailed;
    try {
      await ref.read(galleryProvider.notifier).sync();
    } catch (error, stackTrace) {
      debugPrint('Galeri manuel eşitleme hatası: $error\n$stackTrace');
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  }
}

/// 3 sütunlu screenshot ızgarası + üstte sayaç satırı.
class _GalleryGrid extends ConsumerWidget {
  const _GalleryGrid({required this.entries});

  final List<ScreenshotEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(screenshotRepositoryProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(galleryProvider.notifier).sync(),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnalysisBanner(
                    pendingCount: entries
                        .where((entry) => entry.isPending)
                        .length,
                  ),
                  Text(
                    context.l10n.galleryCount(entries.length),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              // Yüzen navbar son satırı örtmesin diye alt boşluk eklenir.
              MediaQuery.paddingOf(context).bottom + AppSpacing.md,
            ),
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
          ),
        ],
      ),
    );
  }
}

// Tüm son ekran görüntülerini ızgarada gösteren tam ekran. Kütüphane'deki
// "Son eklenenler" başlığının "Tümü" bağlantısı bu ekranı açar.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/ui_constants.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/screenshot_entry.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/app_nav_scaffold.dart';
import '../gallery/data/screenshot_repository.dart';
import '../gallery/providers/gallery_provider.dart';
import '../gallery/widgets/screenshot_grid_tile.dart';

class RecentsScreen extends ConsumerWidget {
  const RecentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<ScreenshotEntry> entries =
        ref.watch(galleryProvider).value ?? const [];
    final ScreenshotRepository repo = ref.watch(screenshotRepositoryProvider);

    return AppNavScaffold(
      title: context.l10n.recentsScreenTitle,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: kScreenshotGridColumns,
              mainAxisSpacing: AppSpacing.xs,
              crossAxisSpacing: AppSpacing.xs,
              childAspectRatio: kScreenshotTileAspect,
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
    );
  }
}

// Tüm son ekran görüntülerini 3 sütunlu ızgarada gösteren tam ekran.
// Anasayfadaki "Daha fazla" bu ekranı açar; iOS push olduğu için native
// soldan-sağa geri kaydırma kendiliğinden çalışır.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/ui_constants.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/screenshot_entry.dart';
import '../../core/router/app_router.dart';
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

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.recentsScreenTitle)),
      body: GridView.builder(
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

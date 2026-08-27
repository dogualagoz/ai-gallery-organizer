// Board detay ve arama ekranlarında ortak kullanılan screenshot ızgarası.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/gallery/data/screenshot_repository.dart';
import '../../features/gallery/widgets/screenshot_grid_tile.dart';
import '../constants/ui_constants.dart';
import '../models/screenshot_entry.dart';
import '../router/app_router.dart';

class ScreenshotResultsGrid extends ConsumerWidget {
  const ScreenshotResultsGrid({super.key, required this.entries, this.padding});

  final List<ScreenshotEntry> entries;

  /// Izgara iç boşluğu. Verilmezse her yönden [AppSpacing.md]. Yüzen navbar'ın
  /// altında kalan ekranlar (arama) alt boşluğu buradan büyütür.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ScreenshotRepository repo = ref.watch(screenshotRepositoryProvider);

    return GridView.builder(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
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
    );
  }
}

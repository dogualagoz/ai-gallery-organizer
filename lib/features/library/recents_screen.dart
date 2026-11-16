// Tüm son ekran görüntülerini ızgarada gösteren tam ekran. Kütüphane'deki
// "Son eklenenler" başlığının "Tümü" bağlantısı bu ekranı açar.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n_extension.dart';
import '../../core/models/screenshot_entry.dart';
import '../../core/widgets/app_nav_scaffold.dart';
import '../gallery/providers/gallery_provider.dart';
import '../gallery/widgets/screenshot_grid.dart';

class RecentsScreen extends ConsumerWidget {
  const RecentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<ScreenshotEntry> entries =
        ref.watch(galleryProvider).value ?? const [];

    return AppNavScaffold(
      title: context.l10n.recentsScreenTitle,
      slivers: [
        if (entries.any((entry) => entry.isPending))
          const SliverToBoxAdapter(child: ScreenshotPendingLegend()),
        ScreenshotGrid(entries: entries),
      ],
    );
  }
}

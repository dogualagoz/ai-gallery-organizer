// Screenshot detay ekranı: büyük görsel + kategori/etiket/OCR metadata'sı.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../../core/constants/ui_constants.dart';
import '../../core/l10n/category_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/screenshot_entry.dart';
import '../gallery/data/screenshot_repository.dart';
import '../gallery/providers/gallery_provider.dart';

class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.assetId});

  /// Gösterilecek screenshot'ın photo_manager asset kimliği.
  final String assetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Liste değiştiğinde (analiz yazıldığında) detay da tazelensin diye izlenir.
    ref.watch(galleryProvider);
    final repo = ref.watch(screenshotRepositoryProvider);
    final ScreenshotEntry? entry = repo.entryFor(assetId);
    final AssetEntity? asset = repo.assetFor(assetId);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.detailTitle)),
      body: entry == null
          ? Center(child: Text(context.l10n.comingSoon))
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _ScreenshotImage(assetId: assetId, asset: asset),
                const SizedBox(height: AppSpacing.lg),
                _MetadataSection(entry: entry),
              ],
            ),
    );
  }
}

/// Ekranın üst kısmındaki büyük screenshot görseli (grid'den hero geçişli).
class _ScreenshotImage extends StatelessWidget {
  const _ScreenshotImage({required this.assetId, required this.asset});

  final String assetId;
  final AssetEntity? asset;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Hero(
      tag: 'screenshot-$assetId',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: asset == null
              ? ColoredBox(
                  color: scheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.image_outlined,
                    size: 48,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                )
              : AssetEntityImage(
                  asset!,
                  isOriginal: false,
                  // Detayda okunabilirlik için yüksek çözünürlüklü thumbnail;
                  // orijinal dosya (heic olabilir) decode maliyetinden kaçınılır.
                  thumbnailSize: const ThumbnailSize(1080, 1920),
                  fit: BoxFit.cover,
                ),
        ),
      ),
    );
  }
}

/// Kategori çipi, etiketler ve OCR metni; analiz yoksa bekleme durumu.
class _MetadataSection extends StatelessWidget {
  const _MetadataSection({required this.entry});

  final ScreenshotEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    if (entry.isPending) {
      return Row(
        children: [
          Icon(Icons.hourglass_empty, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Text(
            l10n.detailNotAnalyzed,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (entry.category != null)
          Chip(
            avatar: Icon(
              entry.category!.icon,
              size: 18,
              color: scheme.primary,
            ),
            label: Text(entry.category!.label(l10n)),
          ),
        if (entry.tags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(l10n.detailTagsTitle, style: textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final String tag in entry.tags) Chip(label: Text(tag)),
            ],
          ),
        ],
        if (entry.ocrText != null && entry.ocrText!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(l10n.detailOcrTitle, style: textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: SelectableText(
              entry.ocrText!,
              style: textTheme.bodyMedium,
            ),
          ),
        ],
      ],
    );
  }
}

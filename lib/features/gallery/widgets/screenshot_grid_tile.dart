// Galeri ızgarasındaki tek screenshot karosu: thumbnail + analiz durumu.
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../../../core/constants/ui_constants.dart';
import '../../../core/models/screenshot_entry.dart';

class ScreenshotGridTile extends StatelessWidget {
  const ScreenshotGridTile({
    super.key,
    required this.entry,
    required this.asset,
    required this.onTap,
  });

  final ScreenshotEntry entry;

  /// Thumbnail kaynağı; kütüphane henüz eşitlenmediyse null olabilir.
  final AssetEntity? asset;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'screenshot-${entry.assetId}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (asset != null)
                AssetEntityImage(
                  asset!,
                  isOriginal: false,
                  // Grid karosu için düşük çözünürlük yeterli; bellek dostu.
                  thumbnailSize: const ThumbnailSize.square(300),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _TilePlaceholder(scheme: scheme),
                )
              else
                _TilePlaceholder(scheme: scheme),
              // Analiz bekleyenlerde köşede küçük nokta gösterilir.
              if (entry.isPending)
                Positioned(
                  top: AppSpacing.xs,
                  right: AppSpacing.xs,
                  child: Container(
                    width: AppSpacing.sm,
                    height: AppSpacing.sm,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.surface, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thumbnail yüklenemediğinde gösterilen sade dolgu.
class _TilePlaceholder extends StatelessWidget {
  const _TilePlaceholder({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Icon(
        Icons.image_outlined,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
      ),
    );
  }
}

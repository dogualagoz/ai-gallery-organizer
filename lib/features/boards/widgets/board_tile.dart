// Kütüphane karosu: sakin kart — kapak mozaiği, 17pt başlık, footnote sayaç ve
// son analizden gelen yeni öğeler için küçük aksan rozeti. Basış geri
// bildirimi Pressable'dan; dokunma eylemi çağırana ait.
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/surface_card.dart';

/// Kapakta gösterilecek en fazla thumbnail sayısı.
const int kBoardCoverCount = 3;

class BoardTile extends StatelessWidget {
  const BoardTile({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.covers,
    this.newCount = 0,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final int count;

  /// Pano içeriğinden örnek thumbnail'lar (en fazla [kBoardCoverCount]).
  final List<AssetEntity> covers;

  /// Son analizde bu karoya gelen, henüz görülmemiş screenshot sayısı; >0 ise
  /// kapağın köşesinde "+N" rozeti görünür.
  final int newCount;

  /// Dokunma eylemi (pano açma ya da düzenleme modunda eylem sayfası).
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Pressable(
      onPressed: onPressed,
      child: SurfaceCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _CoverMosaic(covers: covers, icon: icon),
                  if (newCount > 0)
                    Positioned(
                      top: AppSpacing.xs,
                      right: AppSpacing.xs,
                      child: _NewBadge(count: newCount),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: AppSizes.boardTileIcon,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      label,
                      style: text.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text(
                context.l10n.galleryCount(count),
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kapak köşesindeki "+N" rozeti: aksan dolgu, üstünde okunur kısa metin.
class _NewBadge extends StatelessWidget {
  const _NewBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs / 2,
        ),
        child: Text(
          context.l10n.boardsNewBadge(count),
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Kapak alanı: içerik varsa yan yana dikey küçük resimler, yoksa ikonlu dolgu.
class _CoverMosaic extends StatelessWidget {
  const _CoverMosaic({required this.covers, required this.icon});

  final List<AssetEntity> covers;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color fill = scheme.surfaceContainerHigh;

    if (covers.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Center(
          child: Icon(
            icon,
            color: scheme.onSurfaceVariant,
            size: AppSizes.statusIcon,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Row(
        children: [
          for (int i = 0; i < kBoardCoverCount; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs / 2),
            Expanded(
              child: SizedBox.expand(
                child: i < covers.length
                    ? AssetEntityImage(
                        covers[i],
                        isOriginal: false,
                        thumbnailSize: const ThumbnailSize.square(
                          AppSizes.coverThumbnailPx,
                        ),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            ColoredBox(color: fill),
                      )
                    : ColoredBox(color: fill),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

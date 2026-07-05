// Board görünümündeki tek kart: kapak thumbnail şeridi + ikon, ad ve sayaç.
// Dokununca Material container transform ile hedef ekrana büyüyerek açılır.
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';

/// Kapakta gösterilecek en fazla thumbnail sayısı.
const int kBoardCoverCount = 3;

class BoardTile extends StatelessWidget {
  const BoardTile({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.covers,
    required this.openBuilder,
  });

  final IconData icon;
  final String label;
  final int count;

  /// Board içeriğinden örnek thumbnail'lar (en fazla [kBoardCoverCount]).
  final List<AssetEntity> covers;

  /// Kartın büyüyerek açılacağı hedef ekranı üretir.
  final WidgetBuilder openBuilder;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return OpenContainer(
      transitionDuration: AppDurations.slow,
      transitionType: ContainerTransitionType.fadeThrough,
      closedElevation: 0,
      openElevation: 0,
      closedColor: scheme.surface,
      openColor: scheme.surface,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      openBuilder: (context, _) => openBuilder(context),
      closedBuilder: (context, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _CoverStrip(covers: covers, icon: icon)),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(icon, size: 16, color: scheme.primary),
                const SizedBox(width: AppSpacing.xs + 2),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              context.l10n.galleryCount(count),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kapak alanı: içerik varsa yan yana mini thumbnail'lar, yoksa ikonlu dolgu.
class _CoverStrip extends StatelessWidget {
  const _CoverStrip({required this.covers, required this.icon});

  final List<AssetEntity> covers;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color tint = scheme.primary.withValues(alpha: 0.06);

    if (covers.isEmpty) {
      return Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: AppSizes.boardCoverMin),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(
          icon,
          color: scheme.primary.withValues(alpha: 0.45),
          size: 28,
        ),
      );
    }

    return Row(
      children: [
        for (int i = 0; i < kBoardCoverCount; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: SizedBox.expand(
                child: i < covers.length
                    ? AssetEntityImage(
                        covers[i],
                        isOriginal: false,
                        // Mini kapak için düşük çözünürlük yeterli.
                        thumbnailSize: const ThumbnailSize.square(200),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            ColoredBox(color: tint),
                      )
                    : ColoredBox(color: tint),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

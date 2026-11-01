// Izgaradaki tek ekran görüntüsü karosu: küçük resim, analiz bekliyor noktası
// ve seçim modunda işaret dairesi. Basış geri bildirimi Pressable'dan gelir.
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/models/screenshot_entry.dart';
import '../../../core/widgets/pressable.dart';

/// Izgara karosu ile görüntüleyicinin paylaştığı Hero etiketi.
String screenshotHeroTag(String assetId) => 'screenshot-$assetId';

class ScreenshotGridTile extends StatelessWidget {
  const ScreenshotGridTile({
    super.key,
    required this.entry,
    required this.asset,
    required this.onPressed,
    this.radius = 0,
    this.selected,
  });

  final ScreenshotEntry entry;

  /// Thumbnail kaynağı; kütüphane henüz eşitlenmediyse null olabilir.
  final AssetEntity? asset;

  final VoidCallback onPressed;

  /// Köşe yarıçapı: tam ekran ızgarada 0 (Fotoğraflar), kart içinde küçük.
  final double radius;

  /// null: seçim modu kapalı. true/false: köşede seçim işareti görünür.
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    // Fotoğraf üstündeki işaretler iki temada da beyaz okunur.
    final Color light = scheme.brightness == Brightness.dark
        ? scheme.onSurface
        : scheme.surface;
    final bool? isSelected = selected;
    final AssetEntity? image = asset;

    return Semantics(
      selected: isSelected ?? false,
      child: Pressable(
        onPressed: onPressed,
        semanticLabel: entry.isPending
            ? l10n.screenshotPendingLabel
            : l10n.screenshotTileLabel,
        child: Hero(
          tag: screenshotHeroTag(entry.assetId),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Küçük resim yüklenirken de karo dolgulu görünür.
                ColoredBox(color: scheme.surfaceContainerHigh),
                if (image == null)
                  const _MissingImage()
                else
                  AssetEntityImage(
                    image,
                    isOriginal: false,
                    thumbnailSize: const ThumbnailSize.square(
                      AppGridTile.thumbnailPx,
                    ),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const _MissingImage(),
                  ),
                if (isSelected ?? false)
                  ColoredBox(
                    color: light.withValues(alpha: AppGridTile.selectionWash),
                  ),
                if (entry.isPending)
                  Positioned(
                    top: AppSpacing.xs,
                    right: AppSpacing.xs,
                    child: PendingDot(ring: scheme.surface),
                  ),
                if (isSelected != null)
                  Positioned(
                    right: AppSpacing.xs,
                    bottom: AppSpacing.xs,
                    child: _SelectionBadge(selected: isSelected, light: light),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Analiz bekliyor işareti: aksan renkli küçük nokta. Fotoğraf üstündeyken
/// [ring] halkası onu zeminden ayırır.
class PendingDot extends StatelessWidget {
  const PendingDot({super.key, this.ring});

  final Color? ring;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppGridTile.pendingDot,
      height: AppGridTile.pendingDot,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
        border: ring == null
            ? null
            : Border.all(color: ring!, width: AppGridTile.pendingDotBorder),
      ),
    );
  }
}

/// Seçim modundaki daire: seçiliyken aksan dolgulu tik, değilken boş halka.
class _SelectionBadge extends StatelessWidget {
  const _SelectionBadge({required this.selected, required this.light});

  final bool selected;
  final Color light;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: AppGridTile.badgeSize,
      height: AppGridTile.badgeSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected
            ? scheme.primary
            : scheme.scrim.withValues(alpha: AppGridTile.emptyBadgeAlpha),
        border: Border.all(color: light, width: AppGridTile.badgeBorder),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(
              alpha: AppGridTile.badgeShadowAlpha,
            ),
            blurRadius: AppGridTile.badgeShadowBlur,
          ),
        ],
      ),
      child: selected
          ? Icon(AppIcons.check, size: AppGridTile.badgeCheck, color: light)
          : null,
    );
  }
}

/// Küçük resim yoksa ya da yüklenemediyse dolgunun ortasındaki fotoğraf glifi.
class _MissingImage extends StatelessWidget {
  const _MissingImage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(AppIcons.photo, color: Theme.of(context).colorScheme.outline),
    );
  }
}

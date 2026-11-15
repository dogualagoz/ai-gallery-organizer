// Ekran görüntüsü küçük resmi ve ortak yer tutucusu (görsel yok/çözülemedi).
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/ui_constants.dart';

/// Kare küçük resim, alanı kaplar. Görsel yoksa ya da çözülemezse
/// [ThumbnailPlaceholder] gösterilir. Aynı [sizePx] isteyen yüzeyler aynı
/// önbellek kaydını paylaşır.
class ScreenshotThumbnail extends StatelessWidget {
  const ScreenshotThumbnail({
    super.key,
    required this.asset,
    this.sizePx = AppGridTile.thumbnailPx,
    this.glyph = true,
  });

  /// Görsel; kütüphane henüz eşitlenmediyse null.
  final AssetEntity? asset;

  /// İstenen kare küçük resmin kenarı (px).
  final int sizePx;

  /// Yer tutucuda fotoğraf glifi gösterilsin mi (küçük yüzeylerde yalnız dolgu).
  final bool glyph;

  @override
  Widget build(BuildContext context) {
    final AssetEntity? image = asset;
    if (image == null) return ThumbnailPlaceholder(glyph: glyph);
    return AssetEntityImage(
      image,
      isOriginal: false,
      thumbnailSize: ThumbnailSize.square(sizePx),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          ThumbnailPlaceholder(glyph: glyph),
    );
  }
}

/// Küçük resmin yer tutucusu: dolgu ve istenirse ortada fotoğraf glifi.
class ThumbnailPlaceholder extends StatelessWidget {
  const ThumbnailPlaceholder({super.key, this.glyph = true});

  /// false iken yalnız dolgu çizilir.
  final bool glyph;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHigh,
      child: glyph
          ? Center(child: Icon(AppIcons.photo, color: scheme.outline))
          : const SizedBox.expand(),
    );
  }
}

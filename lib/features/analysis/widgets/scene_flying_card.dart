// Analiz sahnesinde tek bir screenshot kartının kaynak yığından kategori
// şeridine quadratic bezier yolla süzülüp yumuşak bir yayla oturması.
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../../../core/constants/ui_constants.dart';

/// Uçan kartın ekran ölçüsü — screenshot oranına yakın dikey kart.
const Size sceneCardSize = Size(46, 74);

/// Tek bir uçuşun verisi: yol (start→control→end quadratic bezier) ve oynatıcı.
class SceneFlight {
  SceneFlight({
    required this.asset,
    required this.start,
    required this.control,
    required this.end,
    required this.controller,
  });

  final AssetEntity? asset;
  final Offset start;
  final Offset control;
  final Offset end;
  final AnimationController controller;
}

/// [SceneFlight]'ı çizen kart: bezier boyunca ilerler, inişte hafif overshoot
/// ile (easeOutBack) şeride oturur — küçülüp yok olmaz; iniş anında şeridin
/// mini yığını devralır.
class SceneFlyingCard extends StatelessWidget {
  const SceneFlyingCard({super.key, required this.flight});

  final SceneFlight flight;

  /// P0→C→P1 üzerinden geçen quadratic bezier noktası.
  Offset _bezier(double t) {
    final double u = 1 - t;
    return flight.start * (u * u) +
        flight.control * (2 * u * t) +
        flight.end * (t * t);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: flight.controller,
      builder: (context, child) {
        final double raw = flight.controller.value;
        final double t = Curves.easeInOutCubic.transform(raw);
        final Offset pos = _bezier(t);
        // Yolda hafifçe büyür, sonda küçük bir overshoot ile yerine oturur.
        final double scale = 0.9 + 0.12 * Curves.easeOutBack.transform(raw);
        return Positioned(
          left: pos.dx - sceneCardSize.width / 2,
          top: pos.dy - sceneCardSize.height / 2,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      // IgnorePointer Positioned'ın İÇİNDE olmalı; Positioned doğrudan Stack'in
      // çocuğu kalsın diye (aksi halde parent data uygulanmaz, kart 0,0'a düşer).
      child: IgnorePointer(child: _CardImage(asset: flight.asset)),
    );
  }
}

/// Gölgeli, yuvarlatılmış kart görseli; asset yoksa nötr dolgu.
class _CardImage extends StatelessWidget {
  const _CardImage({required this.asset});

  final AssetEntity? asset;

  @override
  Widget build(BuildContext context) {
    final Color fallback = Theme.of(context)
        .colorScheme
        .surfaceContainerHighest;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: SizedBox(
          width: sceneCardSize.width,
          height: sceneCardSize.height,
          child: asset != null
              ? AssetEntityImage(
                  asset!,
                  isOriginal: false,
                  thumbnailSize: const ThumbnailSize.square(150),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      ColoredBox(color: fallback),
                )
              : ColoredBox(color: fallback),
        ),
      ),
    );
  }
}

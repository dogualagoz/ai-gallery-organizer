// Analiz ilerleme kartının parçaları: uçuşların kalktığı kaynak küçük resim
// ve ince ilerleme çubuğu.
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/constants/app_curves.dart';
import '../../../core/constants/motion_constants.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/utils/motion_physics.dart';
import '../../gallery/widgets/screenshot_thumbnail.dart';

/// İlerleme kartının başındaki küçük resim (uçuşların görsel kalkış yeri).
/// Resim değişince yenisi büyüyerek gelir; eskisi beklemez, çünkü o anda
/// uçuş kartı olarak karosuna kalkmıştır.
class AnalysisSourceThumb extends StatelessWidget {
  const AnalysisSourceThumb({super.key, required this.asset});

  /// Gösterilecek ekran görüntüsü; null ise yer tutucu.
  final AssetEntity? asset;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = context.reduceMotion;
    return SizedBox(
      width: AppSizes.analysisSourceWidth,
      height: AppSizes.analysisSourceHeight,
      child: AnimatedSwitcher(
        duration: reduceMotion
            ? AppMotion.reducedCrossfade
            : AppDurations.medium,
        switchInCurve: reduceMotion ? AppCurves.linear : AppCurves.snappyMedium,
        layoutBuilder: (current, previous) =>
            current ?? const SizedBox.shrink(),
        transitionBuilder: (child, animation) {
          final Widget faded = FadeTransition(opacity: animation, child: child);
          if (reduceMotion) return faded;
          return ScaleTransition(
            scale: Tween<double>(
              begin: AppFlight.sourceEnterScale,
              end: 1,
            ).animate(animation),
            child: faded,
          );
        },
        child: _SourceImage(key: ValueKey(asset?.id), asset: asset),
      ),
    );
  }
}

class _SourceImage extends StatelessWidget {
  const _SourceImage({super.key, required this.asset});

  final AssetEntity? asset;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: SizedBox.expand(
        child: ScreenshotThumbnail(
          asset: asset,
          sizePx: AppSizes.coverThumbnailPx,
        ),
      ),
    );
  }
}

/// İnce, yuvarlak uçlu ilerleme çubuğu; değer değişimleri yumuşak akar.
class AnalysisProgressBar extends StatelessWidget {
  const AnalysisProgressBar({super.key, required this.value});

  /// 0-1 arası ilerleme; aralık dışı değerler kırpılır.
  final double value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    // Sayı zaten metinde okunuyor; çubuk VoiceOver'da tekrar edilmez.
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: SizedBox(
          height: AppSizes.progressBarHeight,
          child: ColoredBox(
            color: scheme.surfaceContainerHigh,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: value.clamp(0.0, 1.0)),
              duration: AppDurations.medium,
              curve: AppCurves.fadeOut,
              builder: (context, progress, _) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: ColoredBox(color: scheme.primary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

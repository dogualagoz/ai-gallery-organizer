// Analiz durum modülünün sunum parçaları: bekleyen kartı, kompakt ilerleme,
// tur özeti, kota satırı ve sonuç mesajı. Yalnız veriyi çizer; akış ve uçuşlar
// analysis_status_module.dart'ta.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/motion_constants.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/utils/motion_physics.dart';
import '../../../core/utils/text_scale.dart';
import '../../../core/widgets/app_nav_scaffold.dart';
import '../../../core/widgets/surface_card.dart';

/// Bekleyen ekran görüntüleri var: tonlu kart, başlıkta sayı, alt yazıda kota
/// (kotanın göründüğü tek yer) ve "Analiz et".
class AnalysisPendingCard extends StatelessWidget {
  const AnalysisPendingCard({
    super.key,
    required this.pending,
    required this.quotaHint,
    required this.onAnalyze,
  });

  final int pending;
  final String quotaHint;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    return _StatusRow(
      tinted: true,
      icon: AppIcons.analyze,
      title: context.l10n.analyzeUngroupedBar(pending),
      subtitle: quotaHint,
      trailing: _FilledPill(
        label: context.l10n.analysisStartAction,
        onPressed: onAnalyze,
      ),
    );
  }
}

/// Bekleyen var ama hak kalmadı: tek eylemli bilgi satırı.
class AnalysisQuotaRow extends StatelessWidget {
  const AnalysisQuotaRow({
    super.key,
    required this.pending,
    required this.detail,
    required this.onGetMore,
  });

  final int pending;

  /// Kotanın ne zaman yenileneceği ya da neden bittiği.
  final String detail;
  final VoidCallback onGetMore;

  @override
  Widget build(BuildContext context) {
    return _StatusRow(
      icon: AppIcons.quota,
      muted: true,
      title: context.l10n.analysisPendingBanner(pending),
      subtitle: detail,
      trailing: _FilledPill(
        label: context.l10n.analysisGetMoreAction,
        onPressed: onGetMore,
      ),
    );
  }
}

/// Analiz sürüyor: kaynak küçük resim, sayı/toplam, ince çubuk ve duraklat.
class AnalysisProgressCard extends StatelessWidget {
  const AnalysisProgressCard({
    super.key,
    required this.processed,
    required this.total,
    required this.source,
    required this.onPause,
  });

  final int processed;
  final int total;

  /// Sıradaki uçacak (yoksa analiz edilen) ekran görüntüsü; uçuşlar bu
  /// küçük resmin üstünden kalkar.
  final AssetEntity? source;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return _ModuleCard(
      child: Row(
        children: [
          _SourceThumb(asset: source),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.analysisExperienceTitle, style: text.titleMedium),
                Text(
                  l10n.analysisProgress(processed, total),
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _ProgressBar(value: total == 0 ? 0 : processed / total),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          NavBarButton.icon(
            icon: AppIcons.pause,
            label: l10n.analysisPauseAction,
            onPressed: onPause,
          ),
        ],
      ),
    );
  }
}

/// Tur bitti: kaç ekran görüntüsünün kaç kategoriye yerleştiği + "Bitti".
class AnalysisSummaryRow extends StatelessWidget {
  const AnalysisSummaryRow({
    super.key,
    required this.done,
    required this.categories,
    required this.onDone,
  });

  final int done;
  final int categories;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _StatusRow(
      icon: AppIcons.checkCircleFill,
      title: l10n.analysisSceneSummaryTitle,
      subtitle: l10n.analysisSceneSummary(done, categories),
      trailing: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        minimumSize: const Size.square(kMinInteractiveDimensionCupertino),
        onPressed: onDone,
        child: Text(l10n.analysisSceneDone),
      ),
    );
  }
}

/// Limit/hata/günlük tavan gibi tur sonuçları: ikon + metin + opsiyonel eylem
/// + kapat.
class AnalysisMessageRow extends StatelessWidget {
  const AnalysisMessageRow({
    super.key,
    required this.icon,
    required this.text,
    required this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final VoidCallback onDismiss;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final String? label = actionLabel;
    final VoidCallback? action = onAction;
    return _StatusRow(
      icon: icon,
      muted: true,
      title: text,
      // Wrap: büyük yazıda eylem ile kapat sığmazsa alt alta geçer.
      trailing: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (label != null && action != null)
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              minimumSize: const Size.square(kMinInteractiveDimensionCupertino),
              onPressed: action,
              child: Text(label),
            ),
          NavBarButton.icon(
            icon: AppIcons.close,
            label: context.l10n.dismissAction,
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

/// Modül kartı: ortak yüzey + satır iç boşlukları.
class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.child, this.tinted = false});

  final Widget child;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      tinted: tinted,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm + AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.sm + AppSpacing.xs,
      ),
      child: child,
    );
  }
}

/// İkon + başlık/alt yazı + sağda eylem: modül satırlarının ortak düzeni.
class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.title,
    required this.trailing,
    this.subtitle,
    this.tinted = false,
    this.muted = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final bool tinted;

  /// true ise ikon aksan yerine ikincil renkte (bilgi/uyarı satırları).
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final String? detail = subtitle;
    final Widget label = Row(
      children: [
        Icon(
          icon,
          size: AppSizes.statusIcon,
          color: muted ? scheme.onSurfaceVariant : scheme.primary,
        ),
        const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: detail == null ? text.bodyMedium : text.titleMedium,
              ),
              if (detail != null)
                Text(
                  detail,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    // Erişilebilirlik boyutlarında eylem metnin altına iner: yan yana
    // kalırsa metin birkaç harflik sütuna sıkışır ya da satır taşar.
    if (context.accessibilityText) {
      return _ModuleCard(
        tinted: tinted,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            label,
            const SizedBox(height: AppSpacing.sm),
            Align(alignment: AlignmentDirectional.centerEnd, child: trailing),
          ],
        ),
      );
    }
    return _ModuleCard(
      tinted: tinted,
      child: Row(
        children: [
          Expanded(child: label),
          const SizedBox(width: AppSpacing.sm),
          trailing,
        ],
      ),
    );
  }
}

/// Satır içi küçük dolgulu kapsül buton (iOS küçük boy).
class _FilledPill extends StatelessWidget {
  const _FilledPill({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton.filled(
      sizeStyle: CupertinoButtonSize.small,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

/// Yeni kaynak resmin gelişi: sekmesiz, hızlı yay.
final Curve _sourceArrival = SpringCurve(
  AppSprings.snappy,
  AppDurations.medium,
);

/// İlerleme kartının başındaki küçük resim (uçuşların görsel kalkış yeri).
/// Resim değişince yenisi büyüyerek gelir; eskisi beklemez, çünkü o anda
/// uçuş kartı olarak karosuna kalkmıştır.
class _SourceThumb extends StatelessWidget {
  const _SourceThumb({required this.asset});

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
        switchInCurve: reduceMotion ? Curves.linear : _sourceArrival,
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
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AssetEntity? image = asset;
    final Widget placeholder = ColoredBox(
      color: scheme.surfaceContainerHigh,
      child: Icon(AppIcons.photo, color: scheme.onSurfaceVariant),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: SizedBox.expand(
        child: image == null
            ? placeholder
            : AssetEntityImage(
                image,
                isOriginal: false,
                thumbnailSize: const ThumbnailSize.square(
                  AppSizes.coverThumbnailPx,
                ),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => placeholder,
              ),
      ),
    );
  }
}

/// İnce, yuvarlak uçlu ilerleme çubuğu; değer değişimleri yumuşak akar.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

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
              curve: Curves.easeOut,
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

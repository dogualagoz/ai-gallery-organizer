// Destedeki kartın görünümü: ekran görüntüsü + sürükleme yönüyle beliren ton
// ve etiket. Jest ve konum desteye aittir; kart yalnız çizer.
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../detail/widgets/photo_page.dart';
import '../swipe_decision.dart';

/// Bir kaydırma yönünün rengi ve üstündeki içerik rengi; kart ipucu ve
/// alttaki eylem butonları aynı tonu paylaşır.
class SwipeTone {
  const SwipeTone(this.color, this.onColor);

  /// Sil kırmızı, ata aksan, atla nötr gri.
  factory SwipeTone.of(ColorScheme scheme, SwipeDirection direction) {
    return switch (direction) {
      SwipeDirection.left => SwipeTone(scheme.error, scheme.onError),
      SwipeDirection.up => SwipeTone(scheme.primary, scheme.onPrimary),
      SwipeDirection.right => SwipeTone(
        scheme.onSurfaceVariant,
        scheme.surface,
      ),
    };
  }

  final Color color;
  final Color onColor;
}

/// Destedeki kart. [direction] + [progress] (0 → 1) sürüklemenin yönünü ve
/// eşiğe yakınlığını verir: ton ve etiket buna göre belirir.
class SwipeCard extends StatelessWidget {
  const SwipeCard({
    super.key,
    required this.asset,
    required this.assignIcon,
    required this.assignLabel,
    this.direction,
    this.progress = 0,
  });

  final AssetEntity? asset;

  /// Yukarı kaydırmanın hedef kategorisi (ipucunda görünür).
  final IconData assignIcon;
  final String assignLabel;

  final SwipeDirection? direction;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final SwipeDirection? hint = progress > 0 ? direction : null;
    final BorderRadius radius = BorderRadius.circular(AppRadius.lg);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: AppDeck.shadowAlpha),
            blurRadius: AppDeck.shadowBlur,
            offset: const Offset(0, AppDeck.shadowOffsetY),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: scheme.surfaceContainerHigh),
            // Kart her karede yeniden çizilir (ton/etiket); görsel ayrı katmanda
            // kalır ki yeniden rasterlanmasın.
            RepaintBoundary(
              child: ViewerImage(asset: asset, maxPx: AppDeck.imageMaxPx),
            ),
            if (hint != null) ..._hintLayers(scheme, hint),
            // Koyu temada siyah zeminden ayrılsın diye ince kenar.
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: scheme.outlineVariant,
                  width: AppDeck.cardBorder,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _hintLayers(ColorScheme scheme, SwipeDirection hint) {
    final SwipeTone tone = SwipeTone.of(scheme, hint);
    return [
      ColoredBox(
        color: tone.color.withValues(alpha: AppDeck.hintTintAlpha * progress),
      ),
      Align(
        // Etiket gidilen kenarın karşısında (geride kalan tarafta) durur:
        // kart ekrandan taşarken de okunur. Yönler fizikseldir, RTL'de de.
        alignment: switch (hint) {
          SwipeDirection.left => Alignment.topRight,
          SwipeDirection.right => Alignment.topLeft,
          SwipeDirection.up => Alignment.bottomCenter,
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Opacity(
            opacity: progress,
            child: _HintLabel(
              tone: tone,
              direction: hint,
              assignIcon: assignIcon,
              assignLabel: assignLabel,
            ),
          ),
        ),
      ),
    ];
  }
}

/// Kartın üstündeki yön etiketi (ikon + eylem adı).
class _HintLabel extends StatelessWidget {
  const _HintLabel({
    required this.tone,
    required this.direction,
    required this.assignIcon,
    required this.assignLabel,
  });

  final SwipeTone tone;
  final SwipeDirection direction;
  final IconData assignIcon;
  final String assignLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (IconData icon, String label) = switch (direction) {
      SwipeDirection.left => (AppIcons.delete, l10n.sortingHintDelete),
      SwipeDirection.right => (AppIcons.skip, l10n.sortingHintSkip),
      SwipeDirection.up => (assignIcon, assignLabel),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: tone.onColor, size: AppDeck.chipIcon),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(color: tone.onColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

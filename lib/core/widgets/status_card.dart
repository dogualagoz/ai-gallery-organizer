// Durum kartı: ikon + başlık/alt yazı + sağda eylem. Analiz modülü, ipuçları
// ve bilgi bantları ortak kullanır; büyük yazıda eylem metnin altına iner.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';
import '../utils/text_scale.dart';
import 'surface_card.dart';

/// Durum kartlarının ortak yüzeyi ve iç boşlukları.
class StatusCardSurface extends StatelessWidget {
  const StatusCardSurface({
    super.key,
    required this.child,
    this.tinted = false,
    this.padding = defaultPadding,
  });

  /// Kartların varsayılan iç boşluğu (sağda eylem butonunun kendi payı var).
  static const EdgeInsetsGeometry defaultPadding = EdgeInsets.fromLTRB(
    AppSpacing.md,
    AppSpacing.sm + AppSpacing.xs,
    AppSpacing.sm,
    AppSpacing.sm + AppSpacing.xs,
  );

  final Widget child;

  /// true ise aksan tonlu dolgu (öne çıkan eylem kartı).
  final bool tinted;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(tinted: tinted, padding: padding, child: child);
  }
}

/// İkon + başlık/alt yazı + sağda eylem. [title] yoksa yalnız [subtitle]
/// ikincil küçük metin olarak çizilir. [footer] metnin altına (ör. satır içi
/// bağlantı) gelir; varsa satır üstten hizalanır. Erişilebilirlik yazı
/// boyutlarında [trailing] metnin altına iner.
class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.icon,
    required this.trailing,
    this.title,
    this.subtitle,
    this.footer,
    this.tinted = false,
    this.muted = false,
    this.padding = StatusCardSurface.defaultPadding,
  }) : assert(title != null || subtitle != null);

  final IconData icon;
  final String? title;
  final String? subtitle;
  final Widget trailing;
  final Widget? footer;
  final bool tinted;

  /// true ise ikon aksan yerine ikincil renkte (bilgi/uyarı satırları).
  final bool muted;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool top = footer != null;
    final Widget label = Row(
      crossAxisAlignment: top
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: AppSizes.statusIcon,
          color: muted ? scheme.onSurfaceVariant : scheme.primary,
        ),
        const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
        Expanded(child: _texts(context)),
      ],
    );
    // Erişilebilirlik boyutlarında eylem metnin altına iner: yan yana
    // kalırsa metin birkaç harflik sütuna sıkışır ya da satır taşar.
    if (context.accessibilityText) {
      return StatusCardSurface(
        tinted: tinted,
        padding: padding,
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
    return StatusCardSurface(
      tinted: tinted,
      padding: padding,
      child: Row(
        crossAxisAlignment: top
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Expanded(child: label),
          const SizedBox(width: AppSpacing.sm),
          trailing,
        ],
      ),
    );
  }

  Widget _texts(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final String? heading = title;
    final String? detail = subtitle;
    final Widget? below = footer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (heading != null)
          Text(
            heading,
            style: detail == null ? text.bodyMedium : text.titleMedium,
          ),
        if (detail != null)
          Text(
            detail,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ?below,
      ],
    );
  }
}

/// Satır içi küçük dolgulu kapsül buton (iOS küçük boy).
class FilledPillButton extends StatelessWidget {
  const FilledPillButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

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

// Görüntüleyicinin üst çubuğu: cam daire geri butonu ve ortada tarih/saat
// kapsülü (görsel üstünde de okunur). Tarih biçimleri bilgi paneliyle ortak.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/pressable.dart';

/// Ekran görüntüsünün alındığı gün, uygulama diline göre ("1 Kasım 2026").
String viewerDate(BuildContext context, DateTime time) =>
    DateFormat.yMMMMd(Localizations.localeOf(context).toString()).format(time);

/// Alındığı saat, bölgenin 12/24 saat biçimiyle ("14:32" / "2:32 PM").
String viewerTime(BuildContext context, DateTime time) =>
    DateFormat.jm(Localizations.localeOf(context).toString()).format(time);

/// Görüntüleyicinin üst çubuğu; güvenli alanın altına yerleşir.
class ViewerTopBar extends StatelessWidget {
  const ViewerTopBar({
    super.key,
    required this.createdAt,
    required this.onBack,
  });

  final DateTime createdAt;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: AppSizes.navBarMaxTextScale,
          child: Row(
            children: [
              _BackButton(onPressed: onBack),
              Expanded(
                child: Center(child: _DateCapsule(time: createdAt)),
              ),
              // Başlık ekranın tam ortasında kalsın diye geri butonu kadar pay.
              const SizedBox(width: kMinInteractiveDimensionCupertino),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const double size = kMinInteractiveDimensionCupertino;
    return GlassPanel(
      borderRadius: BorderRadius.circular(size / 2),
      child: Pressable(
        onPressed: onPressed,
        semanticLabel: context.l10n.viewerBackLabel,
        child: SizedBox.square(
          dimension: size,
          child: Icon(
            AppIcons.back,
            size: AppSizes.navBarIcon,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Tarih + saat; cam zemin sayesinde ekran görüntüsünün üstünde de okunur.
class _DateCapsule extends StatelessWidget {
  const _DateCapsule({required this.time});

  final DateTime time;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return GlassPanel(
      borderRadius: BorderRadius.circular(
        kMinInteractiveDimensionCupertino / 2,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(viewerDate(context, time), style: text.titleSmall),
            Text(
              viewerTime(context, time),
              style: text.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

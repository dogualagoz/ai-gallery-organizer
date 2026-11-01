// Yıllık plan seçiliyken gösterilen 7 günlük ücretsiz deneme zaman çizelgesi.
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/widgets/surface_card.dart';
import 'tinted_icon_tile.dart';

class TrialTimeline extends StatelessWidget {
  const TrialTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final List<(IconData, String, String)> steps = [
      (
        AppIcons.lockOpen,
        l10n.paywallTimelineDay1Title,
        // Şeffaflık: trial'daki analiz sınırı satın alma öncesi açıkça yazılır.
        l10n.paywallTimelineDay1Body(TrialLimits.aiAnalysis),
      ),
      (
        AppIcons.notifications,
        l10n.paywallTimelineDay5Title,
        l10n.paywallTimelineDay5Body,
      ),
      (
        AppIcons.pro,
        l10n.paywallTimelineDay7Title,
        l10n.paywallTimelineDay7Body,
      ),
    ];

    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          for (int i = 0; i < steps.length; i++)
            _TimelineStep(
              icon: steps[i].$1,
              title: steps[i].$2,
              body: steps[i].$3,
              isLast: i == steps.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.icon,
    required this.title,
    required this.body,
    required this.isLast,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              TintedIconTile(icon: icon, circle: true),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: AppPaywall.timelineLine,
                    margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(
                        alpha: AppPaywall.timelineLineAlpha,
                      ),
                      borderRadius: BorderRadius.circular(
                        AppPaywall.timelineLine / 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: AppSpacing.xs,
                bottom: isLast ? AppSpacing.xs : AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleSmall),
                  Text(
                    body,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

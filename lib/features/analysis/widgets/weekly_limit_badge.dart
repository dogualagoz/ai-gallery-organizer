// Üst app bar'da haftalık analiz kotasını gösteren küçük hap.
// Free/trial kullanıcıda kalan hakkı, Pro'da sonsuz simgesini gösterir;
// dokununca yenilenme bilgisini (veya Pro ipucunu) snackbar ile bildirir.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/services/entitlement_service.dart';

class WeeklyLimitBadge extends ConsumerWidget {
  const WeeklyLimitBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final EntitlementState entitlement = ref.watch(entitlementProvider);

    final bool unlimited = entitlement.isPro && !entitlement.isInTrialWindow;
    final int remaining = entitlement.isInTrialWindow
        ? entitlement.remainingTrialAnalysis + entitlement.analysisCredits
        : entitlement.totalRemainingAnalysis;

    final String label = unlimited
        ? l10n.homeWeeklyLimitUnlimited
        : l10n.homeWeeklyLimitRemaining(remaining);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Material(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: () => _showHint(context, entitlement, unlimited),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + AppSpacing.xs,
              vertical: AppSpacing.xs + 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  unlimited ? Icons.all_inclusive : Icons.auto_awesome,
                  size: 15,
                  color: scheme.onSecondaryContainer,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHint(
    BuildContext context,
    EntitlementState entitlement,
    bool unlimited,
  ) {
    final l10n = context.l10n;
    final String message;
    if (unlimited) {
      message = l10n.homeWeeklyLimitUnlimitedHint;
    } else {
      // Kalan gün yukarı yuvarlanır: pencere içinde en az 1 gösterilir.
      final int daysLeft =
          (entitlement.nextWeeklyReset.difference(DateTime.now()).inHours / 24)
              .ceil()
              .clamp(1, FreeLimits.aiAnalysisWindow.inDays);
      message = l10n.homeWeeklyLimitResetIn(daysLeft);
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

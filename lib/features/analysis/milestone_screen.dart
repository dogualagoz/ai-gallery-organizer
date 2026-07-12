// Haftalık free kota tamamlandığında açılan tam ekran kutlama + yönlendirme sayfası.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/ui_constants.dart';
import '../../core/l10n/category_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/screenshot_category.dart';
import '../../core/router/app_router.dart';
import '../../core/services/entitlement_service.dart';
import '../../core/services/haptic_service.dart';
import 'providers/analysis_queue_provider.dart';
import 'widgets/milestone_celebration.dart';

class MilestoneScreen extends ConsumerStatefulWidget {
  const MilestoneScreen({super.key});

  @override
  ConsumerState<MilestoneScreen> createState() => _MilestoneScreenState();
}

class _MilestoneScreenState extends ConsumerState<MilestoneScreen> {
  @override
  void initState() {
    super.initState();
    Haptics.milestone();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final AnalysisQueueState queue = ref.watch(analysisQueueProvider);
    final EntitlementState entitlement = ref.watch(entitlementProvider);
    // Kalan gün yukarı yuvarlanır: pencere içinde her zaman en az 1 gösterilir.
    final int daysLeft = (entitlement.nextWeeklyReset
                .difference(DateTime.now())
                .inHours /
            24)
        .ceil()
        .clamp(1, FreeLimits.aiAnalysisWindow.inDays);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  tooltip: l10n.dismissAction,
                  icon: const Icon(Icons.close),
                  onPressed: () => context.pop(),
                ),
              ),
              const Spacer(),
              const MilestoneCelebration(),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.milestoneTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.milestoneSubtitle(FreeLimits.aiAnalysis),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (queue.done > 0) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.milestoneRunSummary(queue.done),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              _TopCategories(counts: queue.categoryCounts),
              const Spacer(),
              Text(
                l10n.milestoneResetHint(daysLeft),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _MilestoneCtas(onDismiss: () => context.pop()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bu turda en çok dolan 3 kategori — ikonlu chip satırı.
class _TopCategories extends StatelessWidget {
  const _TopCategories({required this.counts});

  final Map<ScreenshotCategory, int> counts;

  @override
  Widget build(BuildContext context) {
    if (counts.isEmpty) return const SizedBox.shrink();
    final List<MapEntry<ScreenshotCategory, int>> top =
        counts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        for (final entry in top.sublist(0, min(3, top.length)))
          Chip(
            avatar: Icon(entry.key.icon, size: 18),
            label: Text('${entry.key.label(context.l10n)} · ${entry.value}'),
          ),
      ],
    );
  }
}

/// Paket / Pro / sonra butonları.
class _MilestoneCtas extends StatelessWidget {
  const _MilestoneCtas({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: () => context.push(AppRoutes.paywallPacks),
          child: Text(l10n.milestoneCtaPacks),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: () => context.push(AppRoutes.paywall),
          child: Text(l10n.milestoneCtaPro),
        ),
        TextButton(
          onPressed: onDismiss,
          child: Text(l10n.milestoneCtaLater),
        ),
      ],
    );
  }
}

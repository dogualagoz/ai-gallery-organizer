// Haftalık free kota dolunca açılan kutlama sheet'i: bu turun özeti, kota
// yenilenme ipucu ve paket / Pro / sonra seçenekleri.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/ui_constants.dart';
import '../../core/l10n/category_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/screenshot_category.dart';
import '../../core/services/entitlement_service.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/sheet_close_button.dart';
import '../paywall/open_paywall.dart';
import 'providers/analysis_queue_provider.dart';
import 'widgets/milestone_celebration.dart';

/// Haftalık free kota dolunca açılan kutlama ve yönlendirme sheet'i.
class MilestoneScreen extends ConsumerWidget {
  const MilestoneScreen({super.key, this.scrollController});

  /// Sheet rotasının kaydırıcısı: büyük yazı boyutunda içerik kayar, en
  /// üstteyken aşağı çekmek sheet'i kapatır.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final int daysLeft = ref.watch(
      entitlementProvider.select((e) => e.daysUntilWeeklyReset),
    );

    return Scaffold(
      body: SheetWithCloseButton(
        child: SafeArea(
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      const MilestoneCelebration(),
                      const SizedBox(height: AppSpacing.xl),
                      const _RunSummary(),
                      const Spacer(),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        l10n.milestoneResetHint(daysLeft),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const _MilestoneCtas(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Başlık, kota açıklaması, bu turda düzenlenen sayı ve en çok dolan
/// kategoriler.
class _RunSummary extends ConsumerWidget {
  const _RunSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final TextTheme text = Theme.of(context).textTheme;
    final AnalysisQueueState queue = ref.watch(analysisQueueProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.milestoneTitle,
            textAlign: TextAlign.center,
            style: text.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.milestoneSubtitle(FreeLimits.aiAnalysis),
          textAlign: TextAlign.center,
          style: text.bodyLarge,
        ),
        if (queue.done > 0) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.milestoneRunSummary(queue.done),
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _TopCategories(counts: queue.categoryCounts),
      ],
    );
  }
}

/// Bu turda en çok dolan kategoriler: ikonlu bilgi kapsülleri.
class _TopCategories extends StatelessWidget {
  const _TopCategories({required this.counts});

  final Map<ScreenshotCategory, int> counts;

  @override
  Widget build(BuildContext context) {
    if (counts.isEmpty) return const SizedBox.shrink();
    final List<MapEntry<ScreenshotCategory, int>> top = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      children: [
        for (final entry in top.take(AppCelebration.topCategories))
          AppChip(
            icon: entry.key.icon,
            label:
                '${entry.key.label(context.l10n)} '
                '$kInlineSeparator ${entry.value}',
            background: Theme.of(context).colorScheme.surface,
          ),
      ],
    );
  }
}

/// Paket / Pro / sonra seçenekleri.
class _MilestoneCtas extends StatelessWidget {
  const _MilestoneCtas();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: () => openPaywall(context, packs: true),
          child: Text(l10n.milestoneCtaPacks),
        ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton.tonal(
          onPressed: () => openPaywall(context),
          child: Text(l10n.milestoneCtaPro),
        ),
        CupertinoButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(l10n.milestoneCtaLater),
        ),
      ],
    );
  }
}

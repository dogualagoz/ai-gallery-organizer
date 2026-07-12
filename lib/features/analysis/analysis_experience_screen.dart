// Tam ekran analiz deneyimi: canlı sahne + ilerleme başlığı + tur sonu görünümleri.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/ui_constants.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/router/app_router.dart';
import '../../core/services/entitlement_service.dart';
import '../../core/services/haptic_service.dart';
import 'providers/analysis_queue_provider.dart';
import 'widgets/experience/analysis_stage.dart';

class AnalysisExperienceScreen extends ConsumerStatefulWidget {
  const AnalysisExperienceScreen({super.key});

  @override
  ConsumerState<AnalysisExperienceScreen> createState() =>
      _AnalysisExperienceScreenState();
}

class _AnalysisExperienceScreenState
    extends ConsumerState<AnalysisExperienceScreen> {
  bool _popScheduled = false;

  /// Tur sonu geçişlerinde haptic geri bildirim verir; haftalık kota bu
  /// turda tükendiyse milestone sayfasına yol açmak için kendini kapatır.
  void _onStatusChanged(AnalysisQueueState? previous, AnalysisQueueState next) {
    if (previous?.status == next.status) return;
    switch (next.status) {
      case AnalysisQueueStatus.completed:
        Haptics.success();
      case AnalysisQueueStatus.failed:
        Haptics.warning();
      case AnalysisQueueStatus.limitReached:
        // Milestone sayfasını HomeScreen listener'ı frame sonunda açar; bu
        // ekran hemen (senkron) kapanarak iki katmanlı görünümü önler.
        // Kutlama haptic'i milestone sayfasından gelir.
        if (next.freeQuotaExhausted &&
            next.done > 0 &&
            mounted &&
            context.canPop()) {
          context.pop();
        }
      case AnalysisQueueStatus.idle:
      case AnalysisQueueStatus.running:
      case AnalysisQueueStatus.dailyCapReached:
        break;
    }
  }

  void _close() {
    final AnalysisQueueNotifier notifier = ref.read(
      analysisQueueProvider.notifier,
    );
    notifier.dismiss();
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(analysisQueueProvider, _onStatusChanged);
    final AnalysisQueueState queue = ref.watch(analysisQueueProvider);

    // Gösterilecek tur yoksa (ör. kuyruk hiç başlamadan açıldı) sessizce kapan.
    if (queue.status == AnalysisQueueStatus.idle && !_popScheduled) {
      _popScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.canPop()) context.pop();
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _ExperienceHeader(queue: queue, onClose: _close),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.sm),
                    child: AnalysisStage(),
                  ),
                  if (!queue.isRunning &&
                      queue.status != AnalysisQueueStatus.idle)
                    _TerminalOverlay(queue: queue, onClose: _close),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Başlık: ekran adı, işlenen/toplam sayaç, ilerleme halkası ve iptal/kapat.
class _ExperienceHeader extends ConsumerWidget {
  const _ExperienceHeader({required this.queue, required this.onClose});

  final AnalysisQueueState queue;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final int processed = queue.done + queue.failed;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xs,
        0,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              value: queue.total == 0 ? null : processed / queue.total,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.analysisExperienceTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  l10n.analysisProgress(processed, queue.total),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (queue.isRunning)
            IconButton(
              tooltip: l10n.analysisCancelAction,
              icon: const Icon(Icons.close),
              onPressed: () {
                Haptics.warning();
                ref.read(analysisQueueProvider.notifier).cancel();
              },
            )
          else
            IconButton(
              tooltip: l10n.dismissAction,
              icon: const Icon(Icons.close),
              onPressed: onClose,
            ),
        ],
      ),
    );
  }
}

/// Tur bittiğinde sahnenin üstüne gelen sonuç paneli.
class _TerminalOverlay extends ConsumerWidget {
  const _TerminalOverlay({required this.queue, required this.onClose});

  final AnalysisQueueState queue;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surface.withValues(alpha: 0.88),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _terminalContent(context, ref),
        ),
      ),
    );
  }

  Widget _terminalContent(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    switch (queue.status) {
      case AnalysisQueueStatus.completed:
        return _TerminalPanel(
          icon: Icons.check_circle_outline,
          message: queue.failed > 0
              ? l10n.analysisCompletedWithFailures(queue.done, queue.failed)
              : l10n.analysisCompleted(queue.done),
          primaryLabel: l10n.dismissAction,
          onPrimary: onClose,
        );
      case AnalysisQueueStatus.failed:
        return _TerminalPanel(
          icon: Icons.error_outline,
          message: l10n.analysisFailedBanner,
          primaryLabel: l10n.analysisRetryAction,
          onPrimary: () => ref.read(analysisQueueProvider.notifier).start(),
          secondaryLabel: l10n.dismissAction,
          onSecondary: onClose,
        );
      case AnalysisQueueStatus.dailyCapReached:
        return _TerminalPanel(
          icon: Icons.schedule_outlined,
          message: l10n.analysisDailyCapBanner,
          primaryLabel: l10n.dismissAction,
          onPrimary: onClose,
        );
      case AnalysisQueueStatus.limitReached:
        final bool inTrial = ref.watch(
          entitlementProvider.select((state) => state.isInTrialWindow),
        );
        return _TerminalPanel(
          icon: Icons.workspace_premium_outlined,
          message: inTrial
              ? l10n.analysisTrialLimitBanner
              : queue.done > 0
              ? l10n.analysisLimitCompleted(queue.done)
              : l10n.analysisLimitBanner,
          primaryLabel: l10n.paywallTitle,
          onPrimary: () => context.push(AppRoutes.paywallPacks),
          secondaryLabel: l10n.dismissAction,
          onSecondary: onClose,
        );
      case AnalysisQueueStatus.idle:
      case AnalysisQueueStatus.running:
        return const SizedBox.shrink();
    }
  }
}

/// İkon + mesaj + bir/iki aksiyon düğmesinden oluşan ortak sonuç paneli.
class _TerminalPanel extends StatelessWidget {
  const _TerminalPanel({
    required this.icon,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 56, color: scheme.primary),
        const SizedBox(height: AppSpacing.md),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
        if (secondaryLabel != null)
          TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
      ],
    );
  }
}

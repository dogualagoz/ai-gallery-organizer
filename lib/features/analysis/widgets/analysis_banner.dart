// Galeri üstündeki analiz banner'ı: bekleyen sayısı, ilerleme, sonuç ve limit durumları.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/router/app_router.dart';
import '../providers/analysis_queue_provider.dart';

class AnalysisBanner extends ConsumerWidget {
  const AnalysisBanner({super.key, required this.pendingCount});

  /// Galerideki analiz edilmemiş screenshot sayısı.
  final int pendingCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AnalysisQueueState queue = ref.watch(analysisQueueProvider);

    final Widget? content = switch (queue.status) {
      AnalysisQueueStatus.idle when pendingCount > 0 => _IdleContent(
        pendingCount: pendingCount,
      ),
      AnalysisQueueStatus.idle => null,
      AnalysisQueueStatus.running => _RunningContent(queue: queue),
      AnalysisQueueStatus.completed => _CompletedContent(queue: queue),
      AnalysisQueueStatus.failed => const _FailedContent(),
      AnalysisQueueStatus.limitReached => _LimitContent(done: queue.done),
      AnalysisQueueStatus.dailyCapReached => const _DailyCapContent(),
    };
    if (content == null) return const SizedBox.shrink();

    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: content,
    );
  }
}

/// Bekleyen screenshot'lar için "analiz et" çağrısı.
class _IdleContent extends ConsumerWidget {
  const _IdleContent({required this.pendingCount});

  final int pendingCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.auto_awesome_outlined, size: 20, color: scheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            context.l10n.analysisPendingBanner(pendingCount),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        FilledButton.tonal(
          style: FilledButton.styleFrom(minimumSize: Size.zero),
          onPressed: () => ref.read(analysisQueueProvider.notifier).start(),
          child: Text(context.l10n.analysisStartAction),
        ),
      ],
    );
  }
}

/// Koşan kuyruk: ilerleme çubuğu + sayaç + iptal.
class _RunningContent extends ConsumerWidget {
  const _RunningContent({required this.queue});

  final AnalysisQueueState queue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int processed = queue.done + queue.failed;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.analysisProgress(processed, queue.total),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              LinearProgressIndicator(
                value: queue.total == 0 ? null : processed / queue.total,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          tooltip: context.l10n.analysisCancelAction,
          icon: const Icon(Icons.close),
          onPressed: () => ref.read(analysisQueueProvider.notifier).cancel(),
        ),
      ],
    );
  }
}

/// Tur özeti (başarı + varsa hata sayısı) ve kapatma.
class _CompletedContent extends ConsumerWidget {
  const _CompletedContent({required this.queue});

  final AnalysisQueueState queue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final String text = queue.failed > 0
        ? l10n.analysisCompletedWithFailures(queue.done, queue.failed)
        : l10n.analysisCompleted(queue.done);
    return _ResultRow(
      icon: Icons.check_circle_outline,
      text: text,
      onDismiss: () => ref.read(analysisQueueProvider.notifier).dismiss(),
    );
  }
}

/// Hiçbir istek başarılı olmadığında hata + tekrar dene.
class _FailedContent extends ConsumerWidget {
  const _FailedContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Icon(
          Icons.error_outline,
          size: 20,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            context.l10n.analysisFailedBanner,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        TextButton(
          onPressed: () => ref.read(analysisQueueProvider.notifier).start(),
          child: Text(context.l10n.analysisRetryAction),
        ),
        IconButton(
          tooltip: context.l10n.dismissAction,
          icon: const Icon(Icons.close),
          onPressed: () => ref.read(analysisQueueProvider.notifier).dismiss(),
        ),
      ],
    );
  }
}

/// Free limit dolduğunda paywall çağrısı. Bu turda başarı varsa "{count}
/// gruplandırıldı" özetiyle gösterilir, yoksa genel limit mesajıyla.
class _LimitContent extends ConsumerWidget {
  const _LimitContent({required this.done});

  final int done;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String message = done > 0
        ? context.l10n.analysisLimitCompleted(done)
        : context.l10n.analysisLimitBanner;
    return Row(
      children: [
        Icon(
          Icons.workspace_premium_outlined,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ),
        FilledButton.tonal(
          style: FilledButton.styleFrom(minimumSize: Size.zero),
          onPressed: () => context.push(AppRoutes.paywall),
          child: Text(context.l10n.paywallTitle),
        ),
        IconButton(
          tooltip: context.l10n.dismissAction,
          icon: const Icon(Icons.close),
          onPressed: () => ref.read(analysisQueueProvider.notifier).dismiss(),
        ),
      ],
    );
  }
}

/// Ücretsiz katmanın günlük istek tavanı dolduğunda gösterilir.
class _DailyCapContent extends ConsumerWidget {
  const _DailyCapContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ResultRow(
      icon: Icons.schedule_outlined,
      text: context.l10n.analysisDailyCapBanner,
      onDismiss: () => ref.read(analysisQueueProvider.notifier).dismiss(),
    );
  }
}

/// İkon + metin + kapat düğmesinden oluşan ortak sonuç satırı.
class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.icon,
    required this.text,
    required this.onDismiss,
  });

  final IconData icon;
  final String text;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
        IconButton(
          tooltip: context.l10n.dismissAction,
          icon: const Icon(Icons.close),
          onPressed: onDismiss,
        ),
      ],
    );
  }
}

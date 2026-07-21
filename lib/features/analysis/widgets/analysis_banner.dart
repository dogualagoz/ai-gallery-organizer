// Galeri üstündeki analiz banner'ı: bekleyen sayısı, ilerleme, sonuç ve limit durumları.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/entitlement_service.dart';
import '../../../core/services/haptic_service.dart';
import '../providers/analysis_queue_provider.dart';
import 'analyze_hero_button.dart';

class AnalysisBanner extends ConsumerWidget {
  const AnalysisBanner({super.key, required this.pendingCount});

  /// Galerideki analiz edilmemiş screenshot sayısı.
  final int pendingCount;

  /// Tur sonu geçişlerinde haptic geri bildirim.
  void _onStatusChanged(AnalysisQueueState? previous, AnalysisQueueState next) {
    if (previous?.status == next.status) return;
    switch (next.status) {
      case AnalysisQueueStatus.completed:
        Haptics.success();
      case AnalysisQueueStatus.failed:
        Haptics.warning();
      case AnalysisQueueStatus.idle:
      case AnalysisQueueStatus.running:
      case AnalysisQueueStatus.limitReached:
      case AnalysisQueueStatus.dailyCapReached:
        // limitReached'in kutlaması milestone sayfasından gelir.
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(analysisQueueProvider, _onStatusChanged);
    final AnalysisQueueState queue = ref.watch(analysisQueueProvider);

    // Boşta bekleyen varsa banner yerine hero buton gösterilir; analiz
    // başlayınca buton aynı yerde ilerleme kartına dönüşür (AnimatedSwitcher).
    final Widget child;
    if (queue.status == AnalysisQueueStatus.idle) {
      child = pendingCount > 0
          ? AnalyzeHeroButton(pendingCount: pendingCount)
          : const SizedBox.shrink();
    } else {
      final Widget content = switch (queue.status) {
        AnalysisQueueStatus.idle => const SizedBox.shrink(),
        AnalysisQueueStatus.running => _RunningContent(queue: queue),
        AnalysisQueueStatus.completed => _CompletedContent(queue: queue),
        AnalysisQueueStatus.failed => const _FailedContent(),
        AnalysisQueueStatus.limitReached => _LimitContent(done: queue.done),
        AnalysisQueueStatus.dailyCapReached => const _DailyCapContent(),
      };

      final ColorScheme scheme = Theme.of(context).colorScheme;
      // running'de hero butonla aynı gradyan kullanılır ki AnimatedSwitcher
      // geçişi "canlı buton → soluk gri kutu" yerine kendi tonunda bir
      // dönüşüm gibi okunsun (önceki sürümde secondaryContainer arka planla
      // gradyan arasındaki keskin kontrast "gri flaş" gibi algılanıyordu).
      final bool isRunning = queue.status == AnalysisQueueStatus.running;
      child = Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: isRunning
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [scheme.primary, scheme.tertiary],
                )
              : null,
          color: isRunning ? null : scheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: content,
      );
    }

    return AnimatedSwitcher(
      duration: AppDurations.medium,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: ValueKey<AnalysisQueueStatus>(queue.status),
        child: child,
      ),
    );
  }
}

/// Koşan kuyruk: hero butonun yerinde beliren ilerleme kartı — halka,
/// başlık, sayaç ve iptal.
class _RunningContent extends ConsumerWidget {
  const _RunningContent({required this.queue});

  final AnalysisQueueState queue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final int processed = queue.done + queue.failed;
    return Row(
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            value: queue.total == 0 ? null : processed / queue.total,
            color: scheme.onPrimary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.analysisExperienceTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onPrimary,
                ),
              ),
              Text(
                context.l10n.analysisProgress(processed, queue.total),
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onPrimary.withValues(alpha: 0.85)),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          tooltip: context.l10n.analysisCancelAction,
          icon: Icon(Icons.close, color: scheme.onPrimary),
          onPressed: () {
            Haptics.warning();
            ref.read(analysisQueueProvider.notifier).cancel();
          },
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
          onPressed: () {
            // Hero butonla aynı akış: kota varsa sahneyi aç, sonra başlat.
            if (ref.read(entitlementProvider).canAnalyze) {
              context.push(AppRoutes.analysisScene);
            }
            ref.read(analysisQueueProvider.notifier).start();
          },
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

/// Analiz hakkı dolduğunda paywall çağrısı. Trial penceresindeki Pro'ya
/// trial sınırı mesajı; free kullanıcıya bu turda başarı varsa "{count}
/// gruplandırıldı" özeti, yoksa genel haftalık limit mesajı gösterilir.
class _LimitContent extends ConsumerWidget {
  const _LimitContent({required this.done});

  final int done;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool inTrial = ref.watch(
      entitlementProvider.select((state) => state.isInTrialWindow),
    );
    final String message = inTrial
        ? context.l10n.analysisTrialLimitBanner
        : done > 0
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
          onPressed: () => context.push(AppRoutes.paywallPacks),
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

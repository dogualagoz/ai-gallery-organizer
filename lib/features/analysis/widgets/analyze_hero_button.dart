// Ana sayfadaki hero analiz butonu: gradient, nabız gibi atan parıltı ve
// haftalık kota bilgisiyle uygulamanın ana aksiyonunu öne çıkarır.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/entitlement_service.dart';
import '../../../core/services/haptic_service.dart';
import '../providers/analysis_queue_provider.dart';

class AnalyzeHeroButton extends ConsumerStatefulWidget {
  const AnalyzeHeroButton({super.key, required this.pendingCount});

  /// Analiz bekleyen screenshot sayısı.
  final int pendingCount;

  @override
  ConsumerState<AnalyzeHeroButton> createState() => _AnalyzeHeroButtonState();
}

class _AnalyzeHeroButtonState extends ConsumerState<AnalyzeHeroButton>
    with SingleTickerProviderStateMixin {
  /// Parıltı nabzı — sürekli, yavaş bir gidip gelme.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: AppDurations.scene,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _startAnalysis() {
    Haptics.analysisStart();
    // start() ilk await'ine kadar senkron çalışır: ekran açıldığında kuyruk
    // durumu çoktan running (ya da limitReached) olur.
    ref.read(analysisQueueProvider.notifier).start();
    context.push(AppRoutes.analysis);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final double glow = 0.15 + 0.20 * _pulse.value;
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: glow),
                blurRadius: 24 + 8 * _pulse.value,
                spreadRadius: 1 + 2 * _pulse.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Material(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [scheme.primary, scheme.tertiary],
            ),
          ),
          child: InkWell(
            onTap: _startAnalysis,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _HeroContent(pendingCount: widget.pendingCount),
            ),
          ),
        ),
      ),
    );
  }
}

/// İkon + başlık + kota satırı; renkler gradient üstünde okunacak şekilde.
class _HeroContent extends ConsumerWidget {
  const _HeroContent({required this.pendingCount});

  final int pendingCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final EntitlementState entitlement = ref.watch(entitlementProvider);
    final String quotaHint = entitlement.isInTrialWindow
        ? l10n.analyzeHeroTrialHint(entitlement.remainingTrialAnalysis)
        : entitlement.isPro
        ? l10n.analyzeHeroUnlimited
        : l10n.analyzeHeroQuotaHint(
            entitlement.totalRemainingAnalysis,
            FreeLimits.aiAnalysis,
          );

    return Row(
      children: [
        Icon(Icons.auto_awesome, color: scheme.onPrimary, size: 32),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.analyzeHeroTitle(pendingCount),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                quotaHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onPrimary.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_forward_rounded, color: scheme.onPrimary),
      ],
    );
  }
}

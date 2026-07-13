// Ana sayfadaki hero analiz butonu: gradient, nabız gibi atan parıltı ve
// haftalık kota bilgisiyle uygulamanın ana aksiyonunu öne çıkarır.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
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
    // Ekran değişmez: banner aynı yerde ilerleme kartına dönüşür ve
    // gölgeler kategori kartlarına uçar (CategoryFlyLayer).
    ref.read(analysisQueueProvider.notifier).start();
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

  /// Bu turda gerçekten analiz edilecek sayı: bütçe (kalan hak + kredi)
  /// bekleyenden azsa başlık onu söyler — "197 analiz et" deyip 100'de
  /// durmak güven kırar. Bütçe 0 ise bekleyen sayısı gösterilir (tık →
  /// limit akışı zaten devreye girer).
  int _displayCount(EntitlementState entitlement) {
    final int budget = entitlement.isInTrialWindow
        ? entitlement.remainingTrialAnalysis + entitlement.analysisCredits
        : entitlement.isPro
        ? pendingCount
        : entitlement.totalRemainingAnalysis;
    return budget > 0 ? min(pendingCount, budget) : pendingCount;
  }

  String _quotaHint(AppLocalizations l10n, EntitlementState entitlement) {
    if (entitlement.isInTrialWindow) {
      return l10n.analyzeHeroTrialHint(entitlement.remainingTrialAnalysis);
    }
    if (entitlement.isPro) return l10n.analyzeHeroUnlimited;
    // Krediler "X/100" kalıbına karıştırılmaz — ayrı gösterilir.
    return entitlement.analysisCredits > 0
        ? l10n.analyzeHeroQuotaWithCredits(
            entitlement.remainingFreeAnalysis,
            FreeLimits.aiAnalysis,
            entitlement.analysisCredits,
          )
        : l10n.analyzeHeroQuotaHint(
            entitlement.remainingFreeAnalysis,
            FreeLimits.aiAnalysis,
          );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final EntitlementState entitlement = ref.watch(entitlementProvider);
    final String quotaHint = _quotaHint(l10n, entitlement);

    return Row(
      children: [
        Icon(Icons.auto_awesome, color: scheme.onPrimary, size: 32),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.analyzeHeroTitle(_displayCount(entitlement)),
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

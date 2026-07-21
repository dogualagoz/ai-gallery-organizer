// Inline analiz kartının animasyonsuz durumları: istatistik + buton (idle),
// tur sonu özeti ve limit/hata/kota mesaj satırı. Animasyon (uçuş/particle)
// analyze_card.dart'ta; buradaki widget'lar yalnız veriyi çizer.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/services/entitlement_service.dart';

/// Galeride gruplanmamış (analiz edilmemiş) yeni ekran görüntüleri varken idle
/// kartın üstünde çıkan kırmızı bildirim çubuğu. Basınca analizi başlatır
/// ([onTap]); sağdaki (x) ile kullanıcı gizleyebilir ([onDismiss]). Free plan
/// içindir (Pro'da auto-sort zaten gruplar).
class AnalyzeUngroupedBar extends StatelessWidget {
  const AnalyzeUngroupedBar({
    super.key,
    required this.count,
    required this.onTap,
    required this.onDismiss,
  });

  final int count;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  size: 20,
                  color: scheme.onErrorContainer,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    context.l10n.analyzeUngroupedBar(count),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: scheme.onErrorContainer,
                ),
                // Kapat: analiz yapmak istemeyen kullanıcı çubuğu gizler.
                IconButton(
                  tooltip: context.l10n.dismissAction,
                  icon: Icon(Icons.close, size: 18, color: scheme.onErrorContainer),
                  visualDensity: VisualDensity.compact,
                  onPressed: onDismiss,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Idle durum: başlık + üç istatistik (bekleyen / analiz edildi / kalan hak)
/// + büyük gradient "Analiz et" butonu.
class AnalyzeIdle extends ConsumerWidget {
  const AnalyzeIdle({
    super.key,
    required this.pending,
    required this.analyzed,
    required this.onAnalyze,
  });

  final int pending;
  final int analyzed;
  final VoidCallback onAnalyze;

  /// Kalan hak metni. Sıra önemli: trial penceresi (Pro sayılsa da sınırlı)
  /// önce, sonra kalıcı Pro sınırsız, aksi halde haftalık free + kredi toplamı.
  String _remaining(AppLocalizations l10n, EntitlementState e) {
    if (e.isInTrialWindow) return '${e.remainingTrialAnalysis}';
    if (e.isPro) return l10n.analyzeCardUnlimited;
    return '${e.totalRemainingAnalysis}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final EntitlementState entitlement = ref.watch(entitlementProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, color: scheme.primary, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.analyzeCardTitle,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            _StatTile(value: '$pending', label: l10n.analyzeCardPending),
            _StatDivider(),
            _StatTile(value: '$analyzed', label: l10n.analyzeCardAnalyzed),
            _StatDivider(),
            _StatTile(
              value: _remaining(l10n, entitlement),
              label: l10n.analyzeCardRemaining,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _AnalyzeButton(onTap: onAnalyze),
      ],
    );
  }
}

/// Tek istatistik: büyük değer + küçük etiket.
class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700, color: scheme.primary),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// İstatistikler arası ince dikey ayraç.
class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: Theme.of(context).colorScheme.outlineVariant
          .withValues(alpha: 0.5),
    );
  }
}

/// Gradient "Analiz et" butonu.
class _AnalyzeButton extends StatelessWidget {
  const _AnalyzeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Material(
      borderRadius: BorderRadius.circular(AppRadius.md),
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  context.l10n.analysisStartAction,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.arrow_forward_rounded, color: scheme.onPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tur sonu özeti (kart içi): ikon + "Hepsi yerleşti" + "N ekran görüntüsü M
/// kategoriye yerleşti" + Bitti. Debug'da ek olarak Tekrar oynat.
class AnalyzeInlineSummary extends StatelessWidget {
  const AnalyzeInlineSummary({
    super.key,
    required this.done,
    required this.categories,
    required this.onDone,
    this.onReplay,
  });

  final int done;
  final int categories;
  final VoidCallback onDone;
  final VoidCallback? onReplay;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(Icons.auto_awesome, size: 32, color: scheme.primary),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.analysisSceneSummaryTitle,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.analysisSceneSummary(done, categories),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onDone,
            child: Text(l10n.analysisSceneDone),
          ),
        ),
        if (kDebugMode && onReplay != null)
          TextButton(
            onPressed: onReplay,
            child: const Text('Tekrar oynat (debug)'),
          ),
      ],
    );
  }
}

/// Limit/hata/kota gibi terminal durumlar için ikon + metin + opsiyonel
/// aksiyon + kapat satırı.
class AnalyzeMessageRow extends StatelessWidget {
  const AnalyzeMessageRow({
    super.key,
    required this.icon,
    required this.text,
    required this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final VoidCallback onDismiss;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: scheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
        if (actionLabel != null && onAction != null)
          FilledButton.tonal(
            style: FilledButton.styleFrom(minimumSize: Size.zero),
            onPressed: onAction,
            child: Text(actionLabel!),
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

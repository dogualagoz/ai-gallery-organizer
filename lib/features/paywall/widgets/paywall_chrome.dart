// Paywall'ın çerçeve parçaları: üstteki Pro karosu ve başlık, alta sabit
// satın alma çubuğu, en alttaki geri yükleme ve yasal bağlantılar.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/utils/link_opener.dart';
import '../providers/purchase_provider.dart';

/// Üst kısım: uygulama ikonu gibi dolgulu Pro karosu, başlık ve alt başlık.
class PaywallHero extends StatelessWidget {
  const PaywallHero({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        children: [
          ExcludeSemantics(
            child: Container(
              width: AppPaywall.heroTile,
              height: AppPaywall.heroTile,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(
                AppIcons.pro,
                size: AppPaywall.heroGlyph,
                color: scheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            header: true,
            child: Text(
              l10n.paywallWelcomeTitle,
              textAlign: TextAlign.center,
              style: text.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.paywallSubtitle,
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Alta sabitlenen satın alma çubuğu: seçili aboneliğin CTA'sı + şeffaf
/// fiyat notu.
class PaywallCtaBar extends StatelessWidget {
  const PaywallCtaBar({
    super.key,
    required this.busy,
    required this.yearlySelected,
    required this.selectedPrice,
    required this.onPressed,
  });

  final bool busy;
  final bool yearlySelected;
  final String? selectedPrice;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String? price = selectedPrice;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        // Genişlik 0 = tek fiziksel piksel (iOS hairline ayırıcı).
        border: Border(top: BorderSide(color: scheme.outlineVariant, width: 0)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: onPressed,
                child: busy
                    ? const CupertinoActivityIndicator()
                    : Text(
                        yearlySelected
                            ? l10n.paywallCtaTrial
                            : l10n.paywallContinueAction,
                      ),
              ),
              if (yearlySelected && price != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    l10n.paywallThenPerYear(price),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alt kısım: geri yükleme, otomatik yenileme notu ve yasal bağlantılar.
class PaywallFooter extends ConsumerWidget {
  const PaywallFooter({super.key, required this.busy});

  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        CupertinoButton(
          onPressed: busy
              ? null
              : () => ref.read(purchaseFlowProvider.notifier).restore(),
          child: Text(l10n.paywallRestoreAction),
        ),
        Text(
          l10n.paywallAutoRenewNote,
          textAlign: TextAlign.center,
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _FooterLink(
              label: l10n.paywallTermsLink,
              url: LegalUrls.termsOfUse,
            ),
            Text(
              kInlineSeparator,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            _FooterLink(
              label: l10n.paywallPrivacyLink,
              url: LegalUrls.privacyPolicy,
            ),
          ],
        ),
      ],
    );
  }
}

/// Footnote boyunda, 44pt dokunma alanlı yasal bağlantı.
class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      minimumSize: const Size.square(kMinInteractiveDimensionCupertino),
      onPressed: () => openExternalUrl(context, url),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

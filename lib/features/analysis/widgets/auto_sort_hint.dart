// Free kullanıcıya otomatik sıralamanın Pro'da olduğunu anlatan kapatılabilir
// ipucu (TipKit benzeri). Bir kez kapatılınca kalıcı olarak gizlenir.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/router/open_paywall.dart';
import '../../../core/services/entitlement_service.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/widgets/app_nav_scaffold.dart';
import '../../../core/widgets/inline_text_button.dart';
import '../../../core/widgets/status_card.dart';

/// Free kullanıcıya otomatik sıralama ipucu; Pro'da ya da kapatılınca gizli.
class AutoSortHint extends ConsumerWidget {
  const AutoSortHint({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isPro = ref.watch(
      entitlementProvider.select((state) => state.isPro),
    );
    final bool dismissed = ref.watch(autoSortHintDismissedProvider);
    if (isPro || dismissed) return const SizedBox.shrink();

    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: StatusCard(
        icon: AppIcons.bolt,
        title: l10n.autoSortHintTitle,
        subtitle: l10n.autoSortHintBody,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.smPlus,
          AppSpacing.xs,
          AppSpacing.smPlus,
        ),
        footer: InlineTextButton(
          label: l10n.autoSortHintAction,
          padding: EdgeInsets.zero,
          style: text.bodyMedium?.copyWith(color: scheme.primary),
          onPressed: () => openPaywall(context),
        ),
        trailing: NavBarButton.icon(
          icon: AppIcons.close,
          label: l10n.dismissAction,
          onPressed: () =>
              ref.read(autoSortHintDismissedProvider.notifier).dismiss(),
        ),
      ),
    );
  }
}

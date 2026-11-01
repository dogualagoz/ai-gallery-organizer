// Free kullanıcıya otomatik sıralamanın Pro'da olduğunu anlatan kapatılabilir
// ipucu (TipKit benzeri). Bir kez kapatılınca kalıcı olarak gizlenir.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/entitlement_service.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/widgets/app_nav_scaffold.dart';
import '../../../core/widgets/surface_card.dart';

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
      child: SurfaceCard(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm + AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.sm + AppSpacing.xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              AppIcons.bolt,
              size: AppSizes.statusIcon,
              color: scheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.autoSortHintTitle, style: text.titleMedium),
                  Text(
                    l10n.autoSortHintBody,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(
                      0,
                      kMinInteractiveDimensionCupertino,
                    ),
                    onPressed: () => context.push(AppRoutes.paywall),
                    child: Text(
                      l10n.autoSortHintAction,
                      style: text.bodyMedium?.copyWith(color: scheme.primary),
                    ),
                  ),
                ],
              ),
            ),
            NavBarButton.icon(
              icon: AppIcons.close,
              label: l10n.dismissAction,
              onPressed: () =>
                  ref.read(autoSortHintDismissedProvider.notifier).dismiss(),
            ),
          ],
        ),
      ),
    );
  }
}

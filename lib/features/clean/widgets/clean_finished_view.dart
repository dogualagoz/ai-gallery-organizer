// Temizle destesinin altındaki bitiş katmanları: deste bitti (bekleyen silme,
// atlananlar ya da tamamen temiz) ve haftalık kaydırma hakkı doldu.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/router/open_paywall.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../providers/clean_session_provider.dart';

/// Deste bitti: bekleyen silme varsa tamamlatır, atlanan varsa yeniden
/// gösterir, yoksa Kütüphane'ye yönlendirir.
class CleanFinishedView extends ConsumerWidget {
  const CleanFinishedView({
    super.key,
    required this.pending,
    required this.skipped,
    required this.deleting,
    required this.onDelete,
  });

  /// Onay bekleyen silme sayısı.
  final int pending;

  /// Bu oturumda atlanıp galeride hâlâ duran ekran görüntüsü sayısı.
  final int skipped;

  /// Silme sürüyor: eylemler kilitlenir.
  final bool deleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final CleanSessionNotifier session = ref.read(
      cleanSessionProvider.notifier,
    );
    if (pending > 0) {
      return EmptyStateView(
        icon: AppIcons.delete,
        title: l10n.sortingPendingDeleteCount(pending),
        message: l10n.sortingFinishConfirmBody,
        actionLabel: l10n.sortingFinishAction(pending),
        onAction: deleting ? null : onDelete,
        secondaryActionLabel: l10n.sortingFinishKeep,
        onSecondaryAction: deleting ? null : session.keepPendingDeletes,
      );
    }
    void backToLibrary() => context.go(AppRoutes.library);
    if (skipped > 0) {
      return EmptyStateView(
        icon: AppIcons.done,
        title: l10n.cleanDoneTitle,
        message: l10n.cleanSkippedBody(skipped),
        actionLabel: l10n.cleanShowSkipped,
        onAction: session.resetSkipped,
        secondaryActionLabel: l10n.cleanBackToLibrary,
        onSecondaryAction: backToLibrary,
      );
    }
    return EmptyStateView(
      icon: AppIcons.done,
      title: l10n.sortingEmptyTitle,
      message: l10n.sortingEmptyBody,
      actionLabel: l10n.cleanBackToLibrary,
      onAction: backToLibrary,
    );
  }
}

/// Ücretsiz haftalık kaydırma hakkı bitti.
class CleanLimitView extends StatelessWidget {
  const CleanLimitView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return EmptyStateView(
      icon: AppIcons.lock,
      title: l10n.sortingLimitTitle,
      message: l10n.sortingLimitBody,
      actionLabel: l10n.paywallTitle,
      onAction: () => openPaywall(context),
    );
  }
}

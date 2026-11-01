// Ayarlar sheet'i: iOS inset-grouped bölümler — Pro durumu, görünüm, dil,
// analiz, satın alımlar, destek, hakkında (+ yalnız debug'da Debug).
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n_extension.dart';
import '../../core/services/entitlement_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/widgets/app_nav_scaffold.dart';
import '../../core/widgets/status_toast.dart';
import '../paywall/providers/purchase_provider.dart';
import 'widgets/debug_section.dart';
import 'widgets/settings_sections.dart';

/// Kütüphane'nin sağ üstünden alttan açılan Ayarlar sayfası.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.scrollController});

  /// Sheet rotasının kaydırıcısı: liste en üstteyken aşağı çekmek sheet'i
  /// kapatır.
  final ScrollController? scrollController;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  /// Restore bu ekrandan başlatıldı mı? Paywall'dan yapılan satın almalar da
  /// aynı stream'i tetiklediği için geri bildirim yalnız kendi isteğimize verilir.
  bool _restoreRequested = false;

  void _restore() {
    _restoreRequested = true;
    ref.read(purchaseFlowProvider.notifier).restore();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final EntitlementState entitlement = ref.watch(entitlementProvider);
    final bool restorePending =
        ref.watch(purchaseFlowProvider).status == PurchaseFlowStatus.pending;

    ref.listen(purchaseFlowProvider, _onPurchaseFlowChanged);

    return AppNavScaffold(
      title: l10n.settingsTitle,
      controller: widget.scrollController,
      automaticallyImplyLeading: false,
      trailing: NavBarButton.text(
        label: l10n.doneAction,
        onPressed: () => context.pop(),
      ),
      slivers: [
        SliverList.list(
          children: [
            ProStatusSection(entitlement: entitlement),
            const ThemeSection(),
            const LanguageSection(),
            AnalysisSection(entitlement: entitlement),
            PurchasesSection(
              entitlement: entitlement,
              restorePending: restorePending,
              onRestore: _restore,
            ),
            const SupportSection(),
            const AboutSection(),
            if (kDebugMode) const DebugSection(),
          ],
        ),
      ],
    );
  }

  /// Restore sonucu ayarlardan tetiklenince geri bildirim burada verilir.
  void _onPurchaseFlowChanged(
    PurchaseFlowState? previous,
    PurchaseFlowState next,
  ) {
    if (!_restoreRequested || previous?.status == next.status) return;
    switch (next.status) {
      case PurchaseFlowStatus.success:
        _restoreRequested = false;
        Haptics.purchaseSuccess();
        showStatusToast(
          context,
          context.l10n.settingsRestoreSuccess,
          tone: StatusToastTone.success,
        );
      case PurchaseFlowStatus.error:
        _restoreRequested = false;
        showStatusToast(
          context,
          context.l10n.paywallPurchaseFailed,
          tone: StatusToastTone.error,
        );
        ref.read(purchaseFlowProvider.notifier).dismissError();
      case PurchaseFlowStatus.idle:
        // Restore zaman aşımına düştü (satın alım bulunamadı) — bayrağı bırak.
        _restoreRequested = false;
      case PurchaseFlowStatus.pending:
        break;
    }
  }
}

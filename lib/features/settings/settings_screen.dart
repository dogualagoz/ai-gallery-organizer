// Ayarlar ekranı: Pro durumu, görünüm, satın alım geri yükleme, yasal linkler, sürüm.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/ui_constants.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/router/app_router.dart';
import '../../core/services/entitlement_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/preferences_service.dart';
import '../../core/utils/link_opener.dart';
import '../paywall/providers/purchase_provider.dart';

/// Uygulama sürüm bilgisi (tek seferlik platform sorgusu).
final packageInfoProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  /// Restore bu ekrandan başlatıldı mı? Paywall'dan yapılan satın almalar da
  /// aynı stream'i tetiklediği için geri bildirim yalnız kendi isteğimize verilir.
  bool _restoreRequested = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bool isPro = ref.watch(entitlementProvider).isPro;
    final bool restorePending =
        ref.watch(purchaseFlowProvider).status == PurchaseFlowStatus.pending;

    ref.listen(purchaseFlowProvider, _onPurchaseFlowChanged);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          // Yüzen navbar içeriği örtmesin diye alt boşluk eklenir.
          MediaQuery.paddingOf(context).bottom + AppSpacing.md,
        ),
        children: [
          _ProStatusCard(isPro: isPro),
          const SizedBox(height: AppSpacing.lg),
          const _ThemeSection(),
          const SizedBox(height: AppSpacing.lg),
          _AutoSortSection(isPro: isPro),
          const SizedBox(height: AppSpacing.lg),
          _PurchasesSection(
            pending: restorePending,
            onRestore: () {
              _restoreRequested = true;
              ref.read(purchaseFlowProvider.notifier).restore();
            },
          ),
          if (kDebugMode) ...[
            const SizedBox(height: AppSpacing.lg),
            const _DebugSection(),
          ],
          const SizedBox(height: AppSpacing.lg),
          const _AboutSection(),
        ],
      ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.settingsRestoreSuccess)),
        );
      case PurchaseFlowStatus.error:
        _restoreRequested = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.paywallPurchaseFailed)),
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

/// Pro üyelikte durum kartı, değilse paywall'a götüren teklif kartı.
class _ProStatusCard extends ConsumerWidget {
  const _ProStatusCard({required this.isPro});

  final bool isPro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final EntitlementState entitlement = ref.watch(entitlementProvider);

    return Material(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [scheme.primary, scheme.secondary],
          ),
        ),
        child: InkWell(
          onTap: isPro ? null : () => context.push(AppRoutes.paywall),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  isPro
                      ? Icons.workspace_premium
                      : Icons.workspace_premium_outlined,
                  color: scheme.onPrimary,
                  size: 32,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPro ? l10n.settingsProActive : l10n.settingsGoPro,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPro
                            ? l10n.settingsProActiveBody
                            : l10n.settingsGoProBody,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onPrimary.withValues(alpha: 0.85),
                        ),
                      ),
                      if (entitlement.isInTrialWindow) ...[
                        const SizedBox(height: 2),
                        Text(
                          l10n.settingsTrialRemaining(
                            entitlement.remainingTrialAnalysis,
                          ),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: scheme.onPrimary.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isPro)
                  Icon(Icons.chevron_right, color: scheme.onPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Görünüm bölümü: açık/koyu/sistem tema seçimi.
class _ThemeSection extends ConsumerWidget {
  const _ThemeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ThemeMode themeMode = ref.watch(themeModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.settingsTheme, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<ThemeMode>(
          segments: [
            ButtonSegment(
              value: ThemeMode.light,
              label: Text(l10n.settingsThemeLight),
              icon: const Icon(Icons.light_mode_outlined),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text(l10n.settingsThemeDark),
              icon: const Icon(Icons.dark_mode_outlined),
            ),
            ButtonSegment(
              value: ThemeMode.system,
              label: Text(l10n.settingsThemeSystem),
              icon: const Icon(Icons.contrast_outlined),
            ),
          ],
          selected: {themeMode},
          onSelectionChanged: (selection) {
            Haptics.tap();
            ref.read(themeModeProvider.notifier).setMode(selection.first);
          },
        ),
      ],
    );
  }
}

/// Auto-sort bölümü: Pro'da aç/kapa anahtarı, free'de kilitli satır → paywall.
class _AutoSortSection extends ConsumerWidget {
  const _AutoSortSection({required this.isPro});

  final bool isPro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.settingsSectionAutoSort,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        _SettingsGroup(
          children: [
            if (isPro)
              _AutoSortSwitchTile(
                title: l10n.settingsAutoSortTitle,
                subtitle: l10n.settingsAutoSortSubtitle,
              )
            else
              _SettingsTile(
                icon: Icons.lock_outline,
                label: l10n.settingsAutoSortTitle,
                onTap: () => context.push(AppRoutes.paywall),
              ),
          ],
        ),
      ],
    );
  }
}

/// Pro kullanıcı için auto-sort aç/kapa anahtarı.
class _AutoSortSwitchTile extends ConsumerWidget {
  const _AutoSortSwitchTile({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool enabled = ref.watch(autoSortEnabledProvider);
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return SwitchListTile(
      secondary: Icon(Icons.auto_awesome, color: scheme.primary),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: Text(
        subtitle,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
      value: enabled,
      onChanged: (value) =>
          ref.read(autoSortEnabledProvider.notifier).setEnabled(value),
    );
  }
}

/// Satın alımlar bölümü: kalan analiz hakkı (free) + geri yükleme satırı.
class _PurchasesSection extends ConsumerWidget {
  const _PurchasesSection({required this.pending, required this.onRestore});

  final bool pending;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final EntitlementState entitlement = ref.watch(entitlementProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.settingsPurchasesSection,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        _SettingsGroup(
          children: [
            if (!entitlement.isPro)
              _SettingsTile(
                icon: Icons.bolt_outlined,
                label: l10n.settingsRemainingAnalyses,
                trailing: Text(
                  '${entitlement.totalRemainingAnalysis}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            _SettingsTile(
              icon: Icons.restore,
              label: l10n.paywallRestoreAction,
              trailing: pending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onTap: pending ? null : onRestore,
            ),
          ],
        ),
      ],
    );
  }
}

/// Yalnız debug derlemede görünür: paywall/limit akışlarını test etmek için
/// yetki durumunu sıfırlar. Release build'e hiç girmez (kDebugMode guard'lı).
class _DebugSection extends ConsumerWidget {
  const _DebugSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Debug', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _SettingsGroup(
          children: [
            _SettingsTile(
              icon: Icons.logout,
              label: 'Exit Pro (debug)',
              onTap: () =>
                  ref.read(entitlementProvider.notifier).setPro(false),
            ),
            _SettingsTile(
              icon: Icons.restart_alt,
              label: 'Reset analysis usage & credits (debug)',
              onTap: () =>
                  ref.read(entitlementProvider.notifier).resetUsageForDebug(),
            ),
          ],
        ),
      ],
    );
  }
}

/// Hakkında bölümü: yasal linkler ve sürüm.
class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.settingsAboutSection,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        _SettingsGroup(
          children: [
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              label: l10n.paywallPrivacyLink,
              onTap: () => openExternalUrl(context, LegalUrls.privacyPolicy),
            ),
            _SettingsTile(
              icon: Icons.description_outlined,
              label: l10n.paywallTermsLink,
              onTap: () => openExternalUrl(context, LegalUrls.termsOfUse),
            ),
            const _VersionTile(),
          ],
        ),
      ],
    );
  }
}

/// Ayar satırlarını tek yüzeyde toplayan grup kabı.
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(height: 1, indent: 52, color: scheme.outlineVariant),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Grup içi tek ayar satırı.
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(icon, color: scheme.primary),
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      trailing:
          trailing ??
          (onTap == null
              ? null
              : Icon(Icons.chevron_right, color: scheme.onSurfaceVariant)),
      onTap: onTap,
    );
  }
}

/// Sürüm bilgisini gösteren pasif satır.
class _VersionTile extends ConsumerWidget {
  const _VersionTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<PackageInfo> info = ref.watch(packageInfoProvider);

    return _SettingsTile(
      icon: Icons.info_outline,
      label: context.l10n.settingsVersion(info.value?.version ?? '—'),
    );
  }
}

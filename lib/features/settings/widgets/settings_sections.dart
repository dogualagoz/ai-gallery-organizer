// Ayarlar sheet'inin bölümleri: her biri tek GroupedSection; uzun açıklamalar
// satıra değil bölüm dipnotuna yazılır (iOS Ayarlar düzeni).
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/services/entitlement_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/utils/link_opener.dart';
import '../../../core/widgets/grouped_section.dart';
import '../../paywall/open_paywall.dart';
import '../../paywall/providers/purchase_provider.dart';
import '../providers/package_info_provider.dart';
import 'settings_rows.dart';

/// En üstteki Pro durumu: free'de teklif satırı, Pro'da üyelik bilgisi.
class ProStatusSection extends StatelessWidget {
  const ProStatusSection({super.key, required this.entitlement});

  final EntitlementState entitlement;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bool isPro = entitlement.isPro;
    final String subtitle = !isPro
        ? l10n.settingsGoProBody
        : entitlement.isInTrialWindow
        ? l10n.settingsTrialRemaining(entitlement.remainingTrialAnalysis)
        : l10n.settingsProActiveBody;
    return GroupedSection(
      children: [
        ProStatusTile(
          title: isPro ? l10n.settingsProActive : l10n.settingsGoPro,
          subtitle: subtitle,
          onTap: isPro ? null : () => openPaywall(context),
        ),
      ],
    );
  }
}

/// Görünüm: açık / koyu / sistem teması.
class ThemeSection extends ConsumerWidget {
  const ThemeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return GroupedSection(
      header: l10n.settingsTheme,
      children: [
        SegmentedRow<ThemeMode>(
          value: ref.watch(themeModeProvider),
          options: {
            ThemeMode.light: l10n.settingsThemeLight,
            ThemeMode.dark: l10n.settingsThemeDark,
            ThemeMode.system: l10n.settingsThemeSystem,
          },
          onChanged: ref.read(themeModeProvider.notifier).setMode,
        ),
      ],
    );
  }
}

/// Dil seçenekleri; sistem dili null locale ile temsil edilir (segment
/// anahtarı null olamadığı için ayrı enum).
enum _LanguageOption {
  system(null),
  english(Locale('en')),
  turkish(Locale('tr'));

  const _LanguageOption(this.locale);

  final Locale? locale;

  static _LanguageOption of(Locale? locale) {
    for (final _LanguageOption option in values) {
      if (option.locale?.languageCode == locale?.languageCode) return option;
    }
    return system;
  }
}

/// Dil: sistem / İngilizce / Türkçe.
class LanguageSection extends ConsumerWidget {
  const LanguageSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return GroupedSection(
      header: l10n.settingsLanguage,
      children: [
        SegmentedRow<_LanguageOption>(
          value: _LanguageOption.of(ref.watch(localeProvider)),
          options: {
            _LanguageOption.system: l10n.settingsLanguageSystem,
            _LanguageOption.english: l10n.settingsLanguageEnglish,
            _LanguageOption.turkish: l10n.settingsLanguageTurkish,
          },
          onChanged: (option) =>
              ref.read(localeProvider.notifier).setLocale(option.locale),
        ),
      ],
    );
  }
}

/// Analiz: otomatik düzenleme (Pro) ve kalan hak ayrıntısı. Kotanın ne
/// zaman yenileneceği dipnotta.
class AnalysisSection extends StatelessWidget {
  const AnalysisSection({super.key, required this.entitlement});

  final EntitlementState entitlement;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return GroupedSection(
      header: l10n.settingsSectionAnalysis,
      footer: _footer(l10n),
      children: [
        if (entitlement.isPro)
          const _AutoSortRow()
        else
          GroupedRow(
            icon: AppIcons.analyze,
            title: l10n.settingsSectionAutoSort,
            trailing: Icon(
              AppIcons.lock,
              size: AppSizes.lockGlyph,
              color: scheme.onSurfaceVariant,
            ),
            onTap: () => openPaywall(context),
          ),
        ..._quotaRows(l10n),
      ],
    );
  }

  List<Widget> _quotaRows(AppLocalizations l10n) {
    final EntitlementState current = entitlement;
    return [
      if (!current.isPro)
        GroupedRow(
          icon: AppIcons.quota,
          title: l10n.settingsWeeklyQuota,
          value: '${current.remainingFreeAnalysis} / ${FreeLimits.aiAnalysis}',
        )
      else if (current.isInTrialWindow)
        GroupedRow(
          icon: AppIcons.schedule,
          title: l10n.settingsTrialQuota,
          value:
              '${current.remainingTrialAnalysis} / ${TrialLimits.aiAnalysis}',
        )
      else
        GroupedRow(
          icon: AppIcons.unlimited,
          title: l10n.settingsAnalysisRow,
          value: l10n.settingsUnlimited,
        ),
      if (current.analysisCredits > 0)
        GroupedRow(
          icon: AppIcons.bolt,
          title: l10n.settingsCredits,
          value: '${current.analysisCredits}',
        ),
    ];
  }

  String _footer(AppLocalizations l10n) {
    final String autoSort = l10n.settingsAutoSortFooter;
    if (!entitlement.isPro) {
      return '$autoSort ${l10n.homeWeeklyLimitResetIn(entitlement.daysUntilWeeklyReset)}';
    }
    if (entitlement.isInTrialWindow) {
      return '$autoSort ${l10n.settingsTrialFooter}';
    }
    return autoSort;
  }
}

/// Pro'da otomatik düzenleme anahtarı.
class _AutoSortRow extends ConsumerWidget {
  const _AutoSortRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GroupedRow(
      icon: AppIcons.analyze,
      title: context.l10n.settingsSectionAutoSort,
      trailing: CupertinoSwitch(
        value: ref.watch(autoSortEnabledProvider),
        onChanged: ref.read(autoSortEnabledProvider.notifier).setEnabled,
      ),
    );
  }
}

/// Satın alımlar: geri yükle, kod kullan ve (abonelikte) aboneliği yönet.
class PurchasesSection extends ConsumerWidget {
  const PurchasesSection({
    super.key,
    required this.entitlement,
    required this.restorePending,
    required this.onRestore,
  });

  final EntitlementState entitlement;
  final bool restorePending;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Ömür boyu plan abonelik değildir; yönetilecek bir şey yok.
    final bool subscribed =
        entitlement.isPro && entitlement.proProductId != ProductIds.lifetime;
    return GroupedSection(
      header: l10n.settingsPurchasesSection,
      children: [
        GroupedRow(
          icon: AppIcons.restore,
          title: l10n.paywallRestoreAction,
          trailing: restorePending ? const CupertinoActivityIndicator() : null,
          showChevron: false,
          onTap: restorePending ? null : onRestore,
        ),
        GroupedRow(
          icon: AppIcons.redeem,
          title: l10n.redeemSettingsLabel,
          showChevron: false,
          onTap: () {
            Haptics.tap();
            // Apple'ın native kod ekranı; başarı purchase stream üzerinden
            // Pro'yu açar, ayrı bir geri bildirim gerekmez.
            ref.read(purchaseFlowProvider.notifier).presentCodeRedemption();
          },
        ),
        if (subscribed)
          GroupedRow(
            icon: AppIcons.subscription,
            title: l10n.settingsManageSubscription,
            onTap: () =>
                openExternalUrl(context, SupportUrls.manageSubscriptions),
          ),
      ],
    );
  }
}

/// Sürüm metni: "1.3.0 (11)"; platform cevabı gelene kadar boş.
String _versionText(AsyncValue<PackageInfo> info) {
  final PackageInfo? value = info.value;
  return value == null ? '' : '${value.version} (${value.buildNumber})';
}

/// Destek: geri bildirim e-postası ve App Store değerlendirmesi.
class SupportSection extends ConsumerWidget {
  const SupportSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final String version = _versionText(ref.watch(packageInfoProvider));
    return GroupedSection(
      header: l10n.settingsSupportSection,
      children: [
        GroupedRow(
          icon: AppIcons.feedback,
          title: l10n.settingsFeedback,
          onTap: () => _sendFeedback(context, version),
        ),
        GroupedRow(
          icon: AppIcons.rate,
          title: l10n.settingsRate,
          onTap: () => openExternalUrl(context, SupportUrls.writeReview),
        ),
      ],
    );
  }

  /// Konusu sürümü içeren e-posta taslağı açar; Mail yoksa destek sayfası.
  void _sendFeedback(BuildContext context, String version) {
    final String subject = context.l10n.settingsFeedbackSubject(
      kAppName,
      version,
    );
    final Uri mail = Uri(
      scheme: 'mailto',
      path: SupportUrls.feedbackEmail,
      // queryParameters boşluğu "+" yapar; Mail bunu olduğu gibi gösterir.
      query: 'subject=${Uri.encodeComponent(subject)}',
    );
    openExternalUrl(
      context,
      mail.toString(),
      fallbackUrl: SupportUrls.supportPage,
    );
  }
}

/// Hakkında: yasal linkler, sürüm ve AI'a giden veri hakkında dipnot.
class AboutSection extends ConsumerWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return GroupedSection(
      header: l10n.settingsAboutSection,
      footer: l10n.settingsAiDataFooter,
      children: [
        GroupedRow(
          icon: AppIcons.privacy,
          title: l10n.paywallPrivacyLink,
          onTap: () => openExternalUrl(context, LegalUrls.privacyPolicy),
        ),
        GroupedRow(
          icon: AppIcons.terms,
          title: l10n.paywallTermsLink,
          onTap: () => openExternalUrl(context, LegalUrls.termsOfUse),
        ),
        GroupedRow(
          icon: AppIcons.info,
          title: l10n.settingsVersionTitle,
          value: _versionText(ref.watch(packageInfoProvider)),
        ),
      ],
    );
  }
}

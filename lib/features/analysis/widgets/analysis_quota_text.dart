// Analiz durum modülündeki kota metinleri: kalan hak ve hak bitince açıklama.
// Saf fonksiyonlar; yetki durumundan doğru cümleyi seçer.
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/services/entitlement_service.dart';

/// Kalan hak metni. Sıra önemli: deneme penceresi (Pro sayılsa da sınırlı)
/// önce, sonra sınırsız Pro, aksi halde haftalık ücretsiz (+ kredi).
String analysisQuotaHint(AppLocalizations l10n, EntitlementState e) {
  if (e.isInTrialWindow) {
    return l10n.analyzeHeroTrialHint(
      e.remainingTrialAnalysis + e.analysisCredits,
    );
  }
  if (e.isPro) return l10n.analyzeHeroUnlimited;
  if (e.analysisCredits > 0) {
    return l10n.analyzeHeroQuotaWithCredits(
      e.remainingFreeAnalysis,
      FreeLimits.aiAnalysis,
      e.analysisCredits,
    );
  }
  return l10n.analyzeHeroQuotaHint(
    e.remainingFreeAnalysis,
    FreeLimits.aiAnalysis,
  );
}

/// Hak bittiğinde: denemede neden bittiği, ücretsizde ne zaman yenileneceği.
String analysisQuotaExhaustedDetail(AppLocalizations l10n, EntitlementState e) {
  if (e.isInTrialWindow) return l10n.analysisTrialQuotaUsed;
  return l10n.homeWeeklyLimitResetIn(e.daysUntilWeeklyReset);
}

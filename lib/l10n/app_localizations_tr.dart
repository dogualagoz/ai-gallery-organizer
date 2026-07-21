// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Snaply';

  @override
  String get tabHome => 'Ana Sayfa';

  @override
  String get tabSort => 'Sırala';

  @override
  String get tabSettings => 'Ayarlar';

  @override
  String get galleryTitle => 'Ekran Görüntüleri';

  @override
  String get boardsTitle => 'Panolar';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsTheme => 'Görünüm';

  @override
  String get settingsThemeLight => 'Açık';

  @override
  String get settingsThemeDark => 'Koyu';

  @override
  String get settingsThemeSystem => 'Sistem';

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get settingsLanguageSystem => 'Sistem';

  @override
  String get settingsLanguageEnglish => 'İngilizce';

  @override
  String get settingsLanguageTurkish => 'Türkçe';

  @override
  String get autoSortPausedChip =>
      'Otomatik düzenleme duraklatıldı — Pro\'ya geç';

  @override
  String get settingsSectionAutoSort => 'Otomatik düzenleme';

  @override
  String get settingsAutoSortTitle =>
      'Yeni ekran görüntülerini otomatik sırala';

  @override
  String get settingsAutoSortSubtitle =>
      'Yeni ekran görüntüsü geldiğinde arka planda çalışır';

  @override
  String get searchTitle => 'Ara';

  @override
  String get sortingTitle => 'Sırala';

  @override
  String get paywallTitle => 'Pro\'ya Geç';

  @override
  String get detailTitle => 'Detay';

  @override
  String get comingSoon => 'Çok yakında';

  @override
  String get onboardingTitle1 => 'Ekran görüntülerin nihayet düzenli';

  @override
  String get onboardingBody1 =>
      'Snaply galerindeki tüm ekran görüntülerini bulur ve otomatik olarak düzenli panolara yerleştirir.';

  @override
  String get onboardingTitle2 => 'Tasarımı gereği gizli';

  @override
  String get onboardingBody2 =>
      'Ekran görüntülerin cihazında saklanır. Her biri yalnızca etiketlenmek için AI\'a kısaca gönderilir; hiçbir sunucuda tutulmaz.';

  @override
  String get onboardingTitle3 => 'Fotoğraf erişimine izin ver';

  @override
  String get onboardingBody3 =>
      'Snaply\'nin ekran görüntülerini bulup düzenleyebilmesi için fotoğraf kütüphanesine erişmesi gerekiyor. Kontrol sende.';

  @override
  String get onboardingContinue => 'Devam';

  @override
  String get permissionDeniedTitle => 'Fotoğraf erişimi gerekli';

  @override
  String get permissionDeniedBody =>
      'İzin olmadan Snaply ekran görüntülerini göremez. Erişimi Ayarlar\'dan açabilirsin.';

  @override
  String get openSettings => 'Ayarları Aç';

  @override
  String get notNow => 'Şimdi değil';

  @override
  String get gallerySyncTooltip => 'Kütüphaneyi eşitle';

  @override
  String get galleryEmptyTitle => 'Henüz ekran görüntüsü yok';

  @override
  String get galleryEmptyBody =>
      'Bir ekran görüntüsü al ya da mevcut olanları getirmek için kütüphaneni eşitle.';

  @override
  String get gallerySyncAction => 'Şimdi eşitle';

  @override
  String get gallerySyncFailed => 'Kütüphane eşitlenemedi. Lütfen tekrar dene.';

  @override
  String galleryCount(int count) {
    return '$count ekran görüntüsü';
  }

  @override
  String get detailNotAnalyzed => 'Henüz analiz edilmedi';

  @override
  String get detailTagsTitle => 'Etiketler';

  @override
  String get detailOcrTitle => 'Görseldeki metin';

  @override
  String get detailAnalyzeNow => 'Şimdi analiz et';

  @override
  String get detailShare => 'Paylaş';

  @override
  String get detailDelete => 'Sil';

  @override
  String get detailShareFailed => 'Paylaşım açılamadı. Lütfen tekrar dene.';

  @override
  String get detailDeleteFailed =>
      'Ekran görüntüsü silinemedi. Lütfen tekrar dene.';

  @override
  String analysisPendingBanner(int count) {
    return '$count ekran görüntüsü analiz bekliyor';
  }

  @override
  String get analysisStartAction => 'Analiz et';

  @override
  String analysisProgress(int done, int total) {
    return '$done/$total analiz edildi';
  }

  @override
  String get analysisCancelAction => 'İptal';

  @override
  String analysisCompleted(int count) {
    return '$count ekran görüntüsü analiz edildi';
  }

  @override
  String analysisCompletedWithFailures(int done, int failed) {
    return '$done analiz edildi, $failed başarısız';
  }

  @override
  String get analysisFailedBanner =>
      'Analiz başarısız oldu. Bağlantını kontrol edip tekrar dene.';

  @override
  String get analysisRetryAction => 'Tekrar dene';

  @override
  String get analysisLimitBanner =>
      'Bu haftanın ücretsiz analiz hakkı doldu. Pro\'ya geç ya da analiz paketi al.';

  @override
  String get analysisTrialLimitBanner =>
      'Deneme dönemi analiz sınırına ulaştın. Analiz paketi alabilirsin; deneme tamamlanınca sınırsıza geçer.';

  @override
  String analysisLimitCompleted(int count) {
    return '$count ekran görüntüsü gruplandırıldı. Devam etmek için Pro\'ya geç ya da analiz paketi al.';
  }

  @override
  String get analysisDailyCapBanner =>
      'Günlük analiz limiti doldu. Yarın kaldığı yerden devam eder.';

  @override
  String paywallPackSavings(int percent) {
    return '%$percent daha avantajlı';
  }

  @override
  String get proBadgeLabel => 'PRO';

  @override
  String settingsTrialRemaining(int count) {
    return 'Deneme — $count analiz hakkı kaldı';
  }

  @override
  String onboardingTitleQuota(int count) {
    return 'Her hafta $count ücretsiz analiz';
  }

  @override
  String onboardingBodyQuota(int count) {
    return 'Snaply her hafta $count ekran görüntüsünü ücretsiz gruplandırır — kotan her hafta kendiliğinden yenilenir. Daha fazlası gerekirse paketler ve Pro hazır.';
  }

  @override
  String analyzeHeroTitle(int count) {
    return '$count ekran görüntüsünü analiz et';
  }

  @override
  String analyzeHeroQuotaHint(int remaining, int limit) {
    return 'Bu hafta $remaining/$limit ücretsiz analiz hakkın var';
  }

  @override
  String analyzeHeroQuotaWithCredits(int remaining, int limit, int credits) {
    return 'Bu hafta $remaining/$limit ücretsiz + $credits kredi';
  }

  @override
  String get analyzeHeroUnlimited => 'Pro ile sınırsız analiz';

  @override
  String analyzeHeroTrialHint(int count) {
    return 'Denemede $count analiz hakkın kaldı';
  }

  @override
  String get analyzeCardTitle => 'Ekran görüntülerini düzenle';

  @override
  String get analyzeCardPending => 'Bekleyen';

  @override
  String get analyzeCardAnalyzed => 'Analiz edildi';

  @override
  String get analyzeCardRemaining => 'Kalan hak';

  @override
  String get analyzeCardUnlimited => 'Sınırsız';

  @override
  String get analysisExperienceTitle => 'Ekran görüntülerin gruplandırılıyor';

  @override
  String get analysisSceneSummaryTitle => 'Hepsi yerleşti';

  @override
  String analysisSceneSummary(int count, int categories) {
    return '$count ekran görüntüsü $categories kategoriye yerleşti';
  }

  @override
  String get analysisSceneDone => 'Bitti';

  @override
  String get milestoneTitle => 'Harika ilerleme!';

  @override
  String milestoneSubtitle(int limit) {
    return 'Bu haftaki $limit ücretsiz analizin tamamını kullandın.';
  }

  @override
  String milestoneRunSummary(int count) {
    return 'Bu turda $count ekran görüntüsü gruplandırıldı.';
  }

  @override
  String milestoneResetHint(int days) {
    return 'Ücretsiz kotan $days gün sonra yenilenir.';
  }

  @override
  String get milestoneCtaPacks => 'Analiz paketlerini incele';

  @override
  String get milestoneCtaPro => 'Pro\'ya geç — sınırsız analiz';

  @override
  String get milestoneCtaLater => 'Haftaya devam et';

  @override
  String get dismissAction => 'Kapat';

  @override
  String get categoryLockScreen => 'Kilit ekranı';

  @override
  String get categorySocial => 'Sosyal medya';

  @override
  String get categoryNotesPasswords => 'Not ve şifreler';

  @override
  String get categoryMessages => 'Sohbetler';

  @override
  String get categoryShopping => 'Ürünler';

  @override
  String get categoryQrCodes => 'QR kodlar';

  @override
  String get categoryRecipes => 'Tarifler';

  @override
  String get categoryPlaces => 'Mekanlar';

  @override
  String get categoryInspiration => 'İlham';

  @override
  String get categoryMemes => 'Capsler';

  @override
  String get categoryOutfits => 'Kombinler';

  @override
  String get categoryHealth => 'Sağlık';

  @override
  String get categoryTickets => 'Biletler';

  @override
  String get categoryTravel => 'Seyahat';

  @override
  String get categoryFood => 'Yemek';

  @override
  String get categoryFinance => 'Finans';

  @override
  String get categoryDocuments => 'Belgeler';

  @override
  String get categoryEducation => 'Eğitim';

  @override
  String get categoryEntertainment => 'Eğlence';

  @override
  String get categoryReceipts => 'Fatura ve makbuzlar';

  @override
  String get categoryOther => 'Diğer';

  @override
  String get cancelAction => 'İptal';

  @override
  String get boardsSystemSection => 'Kategoriler';

  @override
  String get boardsEmptyHint =>
      'Analiz edilen ekran görüntüleri kategorilerine ayrıldıkça burada görünür';

  @override
  String get boardsCustomSection => 'Panolarım';

  @override
  String get homeRecentsSection => 'Son Görüntüler';

  @override
  String get boardsNewBoardAction => 'Yeni pano';

  @override
  String get boardsNewBoardDialogTitle => 'Yeni pano';

  @override
  String get boardsNewBoardHint => 'Pano adı';

  @override
  String get boardsCreateAction => 'Oluştur';

  @override
  String get boardsRenameAction => 'Yeniden adlandır';

  @override
  String get boardsRenameDialogTitle => 'Panoyu yeniden adlandır';

  @override
  String get boardsDeleteAction => 'Panoyu sil';

  @override
  String get boardsDeleteConfirmTitle => 'Pano silinsin mi?';

  @override
  String get boardsDeleteConfirmBody =>
      'İçindeki ekran görüntüleri silinmez, yalnızca pano bağlantıları kaldırılır.';

  @override
  String get boardsLimitTitle => 'Özel panolar Pro\'ya özel';

  @override
  String get boardDetailEmpty => 'Burada henüz ekran görüntüsü yok';

  @override
  String get searchHint => 'Etiket, metin veya kategori ara';

  @override
  String get searchPrompt => 'Aramak için yazmaya başla';

  @override
  String get searchEmpty => 'Sonuç bulunamadı';

  @override
  String get searchLockedTitle => 'Arama bir Pro özelliği';

  @override
  String get searchLockedBody =>
      'Etiket ve görsel metinlerinde arama yapmak için Pro\'ya geç.';

  @override
  String get sortingEmptyTitle => 'Sıralanacak bir şey kalmadı';

  @override
  String get sortingEmptyBody => 'Tüm ekran görüntülerin düzenli görünüyor.';

  @override
  String get sortingLimitTitle => 'Ücretsiz sıralama hakkın doldu';

  @override
  String get sortingLimitBody => 'Sınırsız sıralama için Pro\'ya geç.';

  @override
  String get sortingAssignSheetTitle => 'Hangi panoya eklensin?';

  @override
  String get sortingHintDelete => 'Sil';

  @override
  String get sortingHintAssign => 'Panoya ekle';

  @override
  String get sortingHintSkip => 'Atla';

  @override
  String sortingRemainingCount(int count) {
    return '$count kaldı';
  }

  @override
  String get sortingDeleteFailed => 'Ekran görüntüsü silinemedi.';

  @override
  String get bulkSelectAction => 'Seç';

  @override
  String bulkSelectionCount(int count) {
    return '$count seçildi';
  }

  @override
  String get bulkDeleteAction => 'Seçilenleri sil';

  @override
  String get bulkDeleteFailed => 'Seçilenler silinemedi. Lütfen tekrar dene.';

  @override
  String get paywallWelcomeTitle => 'Bir daha ekran görüntüsü kaybolmasın';

  @override
  String get paywallSubtitle =>
      'Snaply Pro tüm ekran görüntülerini otomatik olarak gruplandırır';

  @override
  String get paywallFeatureAnalysis => 'Otomatik AI analizi';

  @override
  String get paywallFeatureAnalysisBody =>
      'Her ekran görüntüsü çekildiği anda kategorisine ayrılır';

  @override
  String get paywallFeatureBoards => 'Özel panolar';

  @override
  String get paywallFeatureBoardsBody =>
      'Akıllı panoların yanına kendi panolarını ekle';

  @override
  String get paywallFeatureSwipe => 'Swipe ile sıralama';

  @override
  String get paywallFeatureSwipeBody =>
      'Kalanları hızlı kaydırmalarla keyifle ayıkla';

  @override
  String get paywallFeatureSearch => 'Etiket ve metin araması';

  @override
  String get paywallFeatureSearchBody =>
      'Metin, etiket veya kategoriyle her şeyi bul';

  @override
  String get paywallFeatureBulkDelete => 'Toplu silme';

  @override
  String get paywallFeatureBulkDeleteBody =>
      'Yüzlerce ekran görüntüsünü tek seferde temizle';

  @override
  String get paywallUnitMonth => '/ay';

  @override
  String get paywallUnitYear => '/yıl';

  @override
  String get paywallUnitOnce => 'tek seferlik';

  @override
  String get paywallPlanMonthly => 'Aylık';

  @override
  String get paywallPlanYearly => 'Yıllık';

  @override
  String get paywallPlanLifetime => 'Ömür boyu';

  @override
  String paywallSavingsBadge(int percent) {
    return '%$percent tasarruf';
  }

  @override
  String paywallPerMonthEquivalent(String price) {
    return '≈ $price/ay';
  }

  @override
  String get paywallYearlyTrial => '7 gün ücretsiz dene';

  @override
  String get paywallCtaTrial => '7 gün ücretsiz dene';

  @override
  String paywallThenPerYear(String price) {
    return 'Sonra $price/yıl. İstediğin zaman iptal et.';
  }

  @override
  String get paywallTimelineDay1Title => '1. gün — Bugün';

  @override
  String paywallTimelineDay1Body(int count) {
    return 'Pro özellikleri hemen açılır; deneme boyunca $count AI analizi dahildir.';
  }

  @override
  String get paywallTimelineDay5Title => '5. gün — Hatırlatma';

  @override
  String get paywallTimelineDay5Body =>
      'Deneme süren bitmeden e-posta ile hatırlatırız.';

  @override
  String get paywallTimelineDay7Title => '7. gün — Deneme biter';

  @override
  String get paywallTimelineDay7Body =>
      'Aboneliğin başlar. Öncesinde istediğin zaman iptal edebilirsin.';

  @override
  String get paywallPacksTitle => 'Sadece daha fazla analiz mi lazım?';

  @override
  String get paywallPacksSubtitle =>
      'Aboneliğe gerek yok — tek seferlik kredi paketleri.';

  @override
  String paywallPackCredits(int count) {
    return '$count analiz';
  }

  @override
  String paywallPackDescription(int count) {
    return 'Son $count ekran görüntünü analiz edip gruplar.';
  }

  @override
  String paywallPackPurchased(int count) {
    return '$count analiz hesabına eklendi!';
  }

  @override
  String get paywallContinueAction => 'Devam Et';

  @override
  String get paywallRestoreAction => 'Satın alımları geri yükle';

  @override
  String get paywallPurchaseFailed =>
      'Satın alma tamamlanamadı. Lütfen tekrar dene.';

  @override
  String get paywallProductsUnavailable =>
      'Planlar şu anda yüklenemedi. Lütfen daha sonra tekrar dene.';

  @override
  String get paywallTermsLink => 'Kullanım Şartları';

  @override
  String get paywallPrivacyLink => 'Gizlilik Politikası';

  @override
  String get paywallAutoRenewNote =>
      'Abonelikler seçilen dönem sonunda otomatik yenilenir; istediğin zaman App Store ayarlarından iptal edebilirsin.';

  @override
  String get settingsProActive => 'Snaply Pro üyesisin';

  @override
  String get settingsProActiveBody => 'Tüm özellikler açık. Teşekkürler!';

  @override
  String get settingsGoPro => 'Snaply Pro\'ya geç';

  @override
  String get settingsGoProBody =>
      'Sınırsız analiz, pano ve arama seni bekliyor.';

  @override
  String get settingsPurchasesSection => 'Satın alımlar';

  @override
  String get settingsRemainingAnalyses => 'Kalan analiz hakkı';

  @override
  String get settingsRestoreSuccess => 'Satın alımlar geri yüklendi.';

  @override
  String get settingsAboutSection => 'Hakkında';

  @override
  String settingsVersion(String version) {
    return 'Sürüm $version';
  }

  @override
  String get settingsLinkFailed => 'Bağlantı açılamadı. Lütfen tekrar dene.';

  @override
  String get homeWeeklyLimitUnlimited => 'Sınırsız';

  @override
  String homeWeeklyLimitRemaining(int count) {
    return '$count kaldı';
  }

  @override
  String homeWeeklyLimitResetIn(int days) {
    return 'Haftalık kota $days gün sonra yenilenir.';
  }

  @override
  String get homeWeeklyLimitUnlimitedHint =>
      'Pro ile sınırsız analiz hakkın var.';

  @override
  String get analysisCancelSheetTitle => 'Analiz durdurulsun mu?';

  @override
  String get analysisCancelStop => 'Yarıda kes';

  @override
  String get analysisCancelStopHint => 'Şimdiye kadar analiz edilenler kalsın.';

  @override
  String get analysisCancelReset => 'Sıfırla';

  @override
  String get analysisCancelResetHint => 'Bu turu iptal et, baştan başla.';

  @override
  String get categoryReanalyzeAction => 'Yeniden analiz et';

  @override
  String get categoryReanalyzeConfirmTitle =>
      'Bu kategori yeniden analiz edilsin mi?';

  @override
  String get categoryReanalyzeConfirmBody =>
      'Bu gruptaki ekran görüntüleri AI\'a yeniden gönderilir. Bu, haftalık analiz hakkından harcar.';

  @override
  String get categoryReanalyzeEmpty =>
      'Burada yeniden analiz edilecek bir şey yok.';

  @override
  String get homeRecentsMore => 'Daha fazla göster';

  @override
  String get recentsScreenTitle => 'Son ekran görüntüleri';

  @override
  String get sortingUndo => 'Geri al';

  @override
  String sortingPendingDeleteCount(int count) {
    return '$count silinecek';
  }

  @override
  String sortingFinishAction(int count) {
    return '$count sil';
  }

  @override
  String sortingFinishConfirmTitle(int count) {
    return '$count ekran görüntüsü silinsin mi?';
  }

  @override
  String get sortingFinishConfirmBody =>
      'Bunlar fotoğraf kütüphanenden kalıcı olarak silinir.';

  @override
  String get sortingFinishKeep => 'Kalsın';
}

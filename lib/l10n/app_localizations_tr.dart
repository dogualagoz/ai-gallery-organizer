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
  String get tabGallery => 'Galeri';

  @override
  String get tabBoards => 'Panolar';

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
  String get onboardingStart => 'İzin ver ve başla';

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
  String get galleryPermissionTitle => 'Snaply kütüphaneni göremiyor';

  @override
  String get galleryPermissionBody =>
      'Fotoğraf erişimi kapalı. Ekran görüntülerini düzenlemek için Ayarlar\'dan aç.';

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
  String get analysisLimitBanner => 'Ücretsiz analiz hakkın doldu.';

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
  String get boardsCustomSection => 'Panolarım';

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
  String get boardsLimitTitle => 'Ücretsiz pano limitine ulaştın';

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
  String get paywallWelcomeTitle => 'Snaply Pro';

  @override
  String get paywallSubtitle =>
      'Sınırsız analiz, sınırsız pano ve daha fazlası';

  @override
  String get paywallFeatureAnalysis => 'Otomatik AI analizi';

  @override
  String get paywallFeatureBoards => 'Özel pano sayısı';

  @override
  String get paywallFeatureSwipe => 'Swipe ile sıralama';

  @override
  String get paywallFeatureSearch => 'Etiket ve metin araması';

  @override
  String get paywallFeatureBulkDelete => 'Toplu silme';

  @override
  String get paywallFreeLabel => 'Ücretsiz';

  @override
  String get paywallProLabel => 'Pro';

  @override
  String paywallLimitedValue(int count) {
    return '$count adet';
  }

  @override
  String get paywallUnlimitedValue => 'Sınırsız';

  @override
  String get paywallLockedValue => 'Kilitli';

  @override
  String get paywallUnlockedValue => 'Açık';

  @override
  String get paywallPlanMonthly => 'Aylık';

  @override
  String get paywallPlanYearly => 'Yıllık';

  @override
  String get paywallPlanLifetime => 'Ömür boyu';

  @override
  String get paywallYearlyBadge => 'En avantajlı';

  @override
  String get paywallYearlyTrial => '14 gün ücretsiz dene';

  @override
  String paywallPerMonth(String price) {
    return '$price / ay';
  }

  @override
  String paywallPerYear(String price) {
    return '$price / yıl';
  }

  @override
  String paywallOneTime(String price) {
    return '$price tek seferlik';
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
  String get settingsRestoreSuccess => 'Satın alımlar geri yüklendi.';

  @override
  String get settingsAboutSection => 'Hakkında';

  @override
  String settingsVersion(String version) {
    return 'Sürüm $version';
  }

  @override
  String get settingsLinkFailed => 'Bağlantı açılamadı. Lütfen tekrar dene.';
}

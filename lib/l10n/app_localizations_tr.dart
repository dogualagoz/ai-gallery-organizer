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
      'Ekran görüntülerin cihazında kalır. Her biri yalnızca etiketlenmek için kısaca analiz edilir, başka hiçbir yerde saklanmaz.';

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
  String get categoryShopping => 'Alışveriş';

  @override
  String get categoryNotesPasswords => 'Not ve şifreler';

  @override
  String get categoryMessages => 'Mesajlar';

  @override
  String get categoryReceipts => 'Fatura ve makbuzlar';

  @override
  String get categoryOther => 'Diğer';
}

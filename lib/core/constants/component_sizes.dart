// Ortak bileşen ölçüleri: sekme çubuğu, butonlar, ızgara karosu, cam yüzey,
// toast ve boş durum.
import 'spacing_constants.dart';

/// Kütüphane'deki "Son eklenenler" bölümünde gösterilen karo sayısı (3 sütun ×
/// 2 satır); tamamı başlıktaki "Tümü" ile tam ekran Recents'te açılır.
const int kLibraryRecentsLimit = 6;

/// Ekran görüntüsü ızgaralarının sütun sayısı ve karo oranı (dikey screenshot).
const int kScreenshotGridColumns = 3;
const double kScreenshotTileAspect = 9 / 16;

/// Sabit bileşen ölçüleri.
abstract final class AppSizes {
  /// iOS 26 yüzen tab bar yüksekliği (ikon + küçük etiket). Native bara yakın
  /// dursun diye Material varsayılanından kısa tutulur.
  static const double navBarHeight = 56;
  static const double navBarIcon = 24;

  /// Sekme ikonu ile etiketi arasındaki boşluk.
  static const double navBarLabelGap = 2;

  /// Sekme etiketlerinin büyüyebileceği en fazla metin ölçeği. iOS tab bar'ı
  /// Dynamic Type ile büyümez; sabit yükseklikli pil taşmasın diye sınırlanır.
  static const double navBarMaxTextScale = 1.2;

  /// iOS erişilebilirlik metin boyutlarının başladığı ölçek (AX1: gövde
  /// 17pt → 28pt). Bu eşikten sonra yan yana etiket/değer çiftleri alt alta
  /// dizilir.
  static const double accessibilityTextScale = 28 / 17;

  /// Erişilebilirlik boyutlarında satır başlığının sarabileceği satır sayısı.
  static const int accessibilityMaxLines = 4;

  /// Sekme ikonundaki sayı rozetinin asgari çapı ve yatay iç boşluğu (iOS
  /// tab badge); ikonun sağ üst köşesine bu kadar taşar.
  static const double tabBadgeMinSize = 18;
  static const double tabBadgePaddingH = 5;
  static const double tabBadgeOffset = 10;

  /// Rozetin yazdığı en büyük sayı; fazlası "99+" olur (rozet büyümez).
  static const int tabBadgeMaxCount = 99;

  /// Navbar pilinin yanında yüzen ayrık dairesel Arama butonunun çapı.
  static const double navBarActionSize = 56;

  /// Yüzen sekme çubuğunun kabuktaki iç boşlukları: üstte sabit, altta home
  /// indicator yoksa kenardan bırakılan pay.
  static const double navBarTopGap = AppSpacing.sm;
  static const double navBarEdgeGap = AppSpacing.md;

  /// Sekme çubuğunun altındaki boşluk: home indicator varsa onun yüksekliği.
  static double navBarBottomGap(double bottomInset) =>
      bottomInset > 0 ? bottomInset : navBarEdgeGap;

  /// Birincil (dolgulu) buton yüksekliği — iOS büyük buton ölçüsü.
  static const double buttonHeight = 50;

  /// Kart içindeki ikincil buton yüksekliği (44pt dokunma alanı).
  static const double buttonHeightCompact = 44;

  /// Sheet'in sağ üstündeki kapatma dairesi ve içindeki xmark.
  static const double sheetClose = 30;
  static const double sheetCloseGlyph = 14;

  /// Pano/kategori karosunun en-boy oranı (kapak + iki satır metin).
  static const double boardTileAspect = 1.05;

  /// Karo etiketinin yanındaki küçük kategori ikonu.
  static const double boardTileIcon = 15;

  /// Kapak küçük resimlerinin istendiği çözünürlük (px, kare).
  static const int coverThumbnailPx = 200;

  /// Analiz modülündeki ince ilerleme çubuğu kalınlığı.
  static const double progressBarHeight = 4;

  /// Analiz modülünün başındaki kaynak küçük resim (uçuşların çıkış noktası).
  static const double analysisSourceWidth = 34;
  static const double analysisSourceHeight = 52;

  /// Analiz modülündeki satır ikonlarının boyutu.
  static const double statusIcon = 22;

  /// Pro'ya bağlı eylemlerin yanındaki küçük kilit glifi.
  static const double lockGlyph = 13;

  /// Sürüklenebilir panellerin üstündeki tutamak (iOS grabber ölçüsü).
  static const double grabberWidth = 36;
  static const double grabberHeight = 5;

  /// Etiket kapsülünün iç boşlukları.
  static const double chipPaddingH = 12;
  static const double chipPaddingV = 6;

  /// Çip kapsülünün üstünde/altında saydam dokunma payı (32pt kapsül → 44pt).
  static const double chipHitInset = 6;

  /// Çipteki ikon.
  static const double chipIcon = 15;

  /// Ayarlar'daki Pro satırının dolgulu ikon karosu ve içindeki glif.
  static const double settingsProTile = 40;
  static const double settingsProGlyph = 24;

  /// Kütüphane başlığının yanındaki PRO kapsülündeki rozet glifi.
  static const double proBadgeGlyph = 12;

  /// Onboarding sayfa göstergesi: pasif nokta ve etkin kapsül genişliği.
  static const double pageDot = 8;
  static const double pageDotActive = 24;
}

/// Ekran görüntüsü ızgarası ve karosu.
abstract final class AppGridTile {
  /// Karolar arası boşluk: Fotoğraflar gibi sıkı. Kart içi önizlemelerde
  /// (Kütüphane) yerine [AppSpacing.xs] kullanılır.
  static const double gap = 2;

  /// İstenen küçük resim çözünürlüğü (px, kare) — bellek dostu.
  static const int thumbnailPx = 300;

  /// Analiz bekliyor noktası ve çevresindeki ayırıcı halka.
  static const double pendingDot = 8;
  static const double pendingDotBorder = 1.5;

  /// Seçim modundaki işaret dairesi, içindeki tik ve halka kalınlığı.
  static const double badgeSize = 22;
  static const double badgeCheck = 13;
  static const double badgeBorder = 1.5;

  /// Fotoğraf üstünde okunabilsin diye işaretin altındaki yumuşak gölge.
  static const double badgeShadowBlur = 4;
  static const double badgeShadowAlpha = 0.3;

  /// Seçilmemiş işaret dairesinin hafif koyu dolgusu.
  static const double emptyBadgeAlpha = 0.15;

  /// Seçili karonun üstüne düşen açık örtü (Fotoğraflar'daki gibi).
  static const double selectionWash = 0.3;
}

/// Düzenleme modunda sürüklenmek üzere kaldırılan karonun görünümü.
abstract final class AppLift {
  /// Kaldırılan karonun büyüme oranı (parmağın altına yükselme hissi).
  static const double scale = 1.05;

  /// Kaldırma gölgesi: bulanıklık, aşağı kayma ve opaklık.
  static const double shadowBlur = 18;
  static const double shadowOffsetY = 8;
  static const double shadowAlpha = 0.22;
}

/// Yüzen buzlu-cam (glassmorphism) yüzey ayarları — navbar pili + ayrık Arama
/// butonu. Apple News+ tab bar'ı referans: parlak, neredeyse opak buzlu beyaz
/// kapsül; şeffaflık değil, blur + yumuşak gölge cam hissini verir.
abstract final class AppGlass {
  /// Arka planı bulanıklaştıran gauss sigma'sı (frosted yoğunluğu).
  static const double blurSigma = 24;

  /// `scheme.surface` üzerine uygulanan cam dolgu opaklığı — açık tema. Yüksek =
  /// parlak, neredeyse opak (referanstaki gibi), arkadan yalnızca ipucu sızar.
  static const double fillAlpha = 0.72;

  /// Cam dolgu opaklığı — koyu tema (biraz daha şeffaf durabilir).
  static const double fillAlphaDark = 0.6;

  /// Cam kenarındaki ince parlak çizginin opaklığı (açık / koyu).
  static const double borderAlpha = 0.06;
  static const double borderAlphaDark = 0.14;

  /// "Havada durma" gölgesinin opaklığı (açık / koyu).
  static const double shadowAlpha = 0.14;
  static const double shadowAlphaDark = 0.44;

  /// Büyük başlıklı gezinme barının içerik altına girince aldığı opaklık.
  static const double navBarFillAlpha = 0.8;

  /// Gölgenin yayılımı ve aşağı kayması (px) — büyük yüzey = kalın malzeme.
  static const double shadowBlur = 22;
  static const double shadowOffsetY = 8;

  /// Camın arkasındaki renkleri canlandıran doygunluk çarpanı (iOS ~%180).
  static const double saturation = 1.8;

  /// Üst kenarda ışığı yakalayan parlak çizginin opaklığı; aşağı doğru
  /// [rimAlphaBottom]'a söner (Apple malzemelerindeki "light catching" kenar).
  static const double rimAlphaTop = 0.5;
  static const double rimAlphaTopDark = 0.22;
  static const double rimAlphaBottom = 0.04;
  static const double rimWidth = 0.75;

  /// Seçili sekmeyi saran düz kapsülün primary ton opaklığı — inceltilmiş, iOS
  /// tab bar'ında seçim vurgusu belli belirsizdir.
  static const double indicatorTint = 0.12;
}

/// Üstten kayan durum bildirimi (StatusToast) ayarları.
abstract final class AppToast {
  /// Ekranda kalma süresi; aksiyonlu bildirim okunup basılabilsin diye uzun.
  static const Duration duration = Duration(seconds: 3);
  static const Duration durationWithAction = Duration(seconds: 5);

  /// Kapsülün en geniş hali (büyük ekranda satır gibi yayılmasın).
  static const double maxWidth = 420;

  /// Kapsülün asgari yüksekliği (44pt dokunma hedefi).
  static const double minHeight = 48;
  static const double iconSize = 20;
}

/// Boş durum görünümü ölçüleri.
abstract final class AppEmptyState {
  /// Başlığın üstündeki ikon (ContentUnavailableView'daki büyük sembol).
  static const double iconSize = 48;

  /// Metin satırlarının en geniş hali (okunabilir satır uzunluğu).
  static const double maxTextWidth = 320;
}

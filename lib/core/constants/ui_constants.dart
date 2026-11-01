// UI sabitleri: boşluk, köşe yarıçapı ve animasyon süreleri.
// Magic number kullanmamak için tüm widget'lar bu değerleri kullanır.

/// Kütüphane'deki "Son eklenenler" bölümünde gösterilen karo sayısı (3 sütun ×
/// 2 satır); tamamı başlıktaki "Tümü" ile tam ekran Recents'te açılır.
const int kLibraryRecentsLimit = 6;

/// Ekran görüntüsü ızgaralarının sütun sayısı ve karo oranı (dikey screenshot).
const int kScreenshotGridColumns = 3;
const double kScreenshotTileAspect = 9 / 16;

/// Standart boşluk ölçeği (4pt grid).
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Standart köşe yarıçapları.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
  static const double xl = 28;

  /// Tam yuvarlak hap formu (navbar, rozetler).
  static const double pill = 40;
}

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

  /// Board kartlarındaki kapak şeridi yüksekliği referansı.
  static const double boardCoverMin = 72;

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

/// Temizle destesinin görünümü.
abstract final class AppDeck {
  /// Kartın en-boy oranı (dikey ekran görüntüsü).
  static const double cardAspect = 9 / 16;

  /// Kart görselinin uzun kenar sınırı (px): kart ekranın yarısı kadar,
  /// görüntüleyicinin tam çözünürlüğü gerekmez.
  static const int imageMaxPx = 1920;

  /// Kartın kenar çizgisi (koyu temada siyah zeminden ayrılsın).
  static const double cardBorder = 0.5;

  /// Kart gölgesi: bulanıklık, aşağı kayma ve opaklık.
  static const double shadowBlur = 24;
  static const double shadowOffsetY = 10;
  static const double shadowAlpha = 0.16;

  /// Sürükleme ilerlemesi tamken kartın üstüne düşen yön tonu opaklığı.
  static const double hintTintAlpha = 0.22;

  /// Alttaki eylem dairelerinin çapı, ikon boyutu ve dolgu tonu opaklığı.
  static const double actionSize = 60;
  static const double actionIcon = 26;
  static const double actionTintAlpha = 0.12;

  /// Kart ile eylem satırı arasındaki sabit yuva: bekleyen silme kapsülü
  /// burada belirir; yuva hep yer kapladığı için butonlar parmağın altından
  /// kaymaz.
  static const double pendingSlot = 52;
  static const double pendingBarHeight = 36;

  /// Hedef kategori kapsülündeki ikonların boyutu.
  static const double chipIcon = 15;
  static const double chipChevron = 12;

  /// Hedef kapsülünün en geniş hali (ekran genişliğinin oranı).
  static const double chipMaxWidthFraction = 0.55;
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

/// Standart opaklık değerleri.
abstract final class AppOpacities {
  /// Pro kullanıcının app bar'ındaki incelikli gradient tonunun opaklığı.
  static const double proAppBarTint = 0.12;

  /// Aksan rengiyle hafifçe tonlanmış kart zemini (öneri/eylem kartları).
  static const double accentTint = 0.08;
}

/// Standart animasyon süreleri.
abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 600);

  /// Onboarding gibi sahne animasyonları için uzun süre.
  static const Duration scene = Duration(milliseconds: 1200);
}

// UI sabitleri: boşluk, köşe yarıçapı ve animasyon süreleri.
// Magic number kullanmamak için tüm widget'lar bu değerleri kullanır.

/// Anasayfada "son görüntüler" ızgarasında gösterilen en fazla karo (3 sütun ×
/// 7 satır); fazlası "Daha fazla" ile tam ekran Recents'te açılır.
const int kHomeRecentsLimit = 21;

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

  /// Navbar pilinin yanında yüzen ayrık dairesel Arama butonunun çapı.
  static const double navBarActionSize = 56;

  /// Birincil (dolgulu) buton yüksekliği — iOS büyük buton ölçüsü.
  static const double buttonHeight = 50;

  /// Board kartlarındaki kapak şeridi yüksekliği referansı.
  static const double boardCoverMin = 72;

  /// iOS geri-kaydırma jestinin başlayabileceği sol kenar bölgesi (px).
  static const double edgeSwipeZone = 24;

  /// Geri-kaydırmayı tamamlamak için gereken minimum yatay mesafe (px).
  static const double edgeSwipeTriggerDistance = 80;
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
}

/// Standart animasyon süreleri.
abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 600);

  /// Onboarding gibi sahne animasyonları için uzun süre.
  static const Duration scene = Duration(milliseconds: 1200);
}

// Onboarding sayfalarının ve illüstrasyonlarının ölçü, zamanlama ve
// görünüm sabitleri. Zamanlama oranları döngünün (0-1) kesirleridir.
import 'dart:ui' show Offset, Size;

import '../component_sizes.dart';
import '../motion_constants.dart';

/// Onboarding sayfasının giriş kademesi.
abstract final class AppOnboarding {
  /// Gövde ve dipnotun başlığa göre kademeli başlama oranları.
  static const double bodyDelay = 0.25;
  static const double noteDelay = 0.4;
}

/// Onboarding "erişim" sayfasındaki kategori ızgarası illüstrasyonu.
abstract final class AccessArt {
  /// Tek yönlü giriş süresi (ileri-geri döngüde oynar).
  static const Duration loop = AppDurations.scene;

  /// Izgara: sütun sayısı, karo ve ikon boyutu.
  static const int columns = 3;
  static const double tileSize = 80;
  static const double tileIcon = 30;

  /// Karonun belirirken başladığı ölçek.
  static const double enterScale = 0.6;

  /// Kademeli giriş: her karonun başlangıç gecikmesi, ilk karonun bitişi ve
  /// bitişin karo başına kayması (zaman çizelgesinin oranı).
  static const double staggerStart = 0.08;
  static const double firstEnd = 0.6;
  static const double staggerEnd = 0.04;
}

/// Onboarding kota sayfasındaki haftalık halka illüstrasyonu.
abstract final class QuotaArt {
  /// Tam döngü süresi: kartlar, dolum, bekleme ve tazelenme.
  static final Duration loop = AppDurations.scene * 3;

  /// Halkaya süzülen mini kart sayısı.
  static const int cardCount = 5;

  /// Kota halkası: çap, çizgi kalınlığı ve çizginin kenardan içeri payı.
  static const double ringSize = 168;
  static const double ringStroke = 10;
  static const double ringInset = ringStroke / 2 + 1;

  /// Halkaya süzülen mini kartın boyutu ve hafta çipindeki ikon.
  static const Size miniCardSize = Size(44, 76);
  static const double weekIcon = 22;

  /// Döngü koreografisi (0-1 döngü oranı): halka dolumu ve hafta dönüşü.
  static const double fillBegin = 0.05;
  static const double fillEnd = 0.50;
  static const double resetBegin = 0.62;
  static const double resetEnd = 0.82;

  /// Hareket azaltıldığında gösterilen kare: halka dolu, kartlar emilmiş
  /// (tazelenme fazından hemen önce).
  static const double stillFrame = 0.61;

  /// Kart uçuşları: ilk kartın aralığı ve kartlar arası kademe.
  static const double cardBegin = 0.06;
  static const double cardEnd = 0.36;
  static const double cardStagger = 0.07;

  /// Kart uçuşunun son çeyreğinde halkaya emilir gibi söner, yarıya küçülür;
  /// başlangıçtaki eğiklik (radyan) varışta düzelir.
  static const double cardFadeFrom = 0.75;
  static const double cardShrink = 0.5;
  static const double cardTiltEven = 0.25;
  static const double cardTiltOdd = -0.2;

  /// Hafta çipinin dikey konumu (Alignment y; halkanın altında).
  static const double weekChipY = 0.92;

  /// Mini kartın içi: gölge, görsel bloğu ve metin çizgileri.
  static const double miniShadowAlpha = 0.08;
  static const double miniShadowBlur = 8;
  static const Offset miniShadowOffset = Offset(0, 3);
  static const double miniImageHeight = 22;
  static const double miniImageAlpha = 0.25;
  static const double miniLineHeight = 3;
  static const double miniLineAlpha = 0.3;

  /// Çizgi genişliği: taban + karta/satıra göre sözde rastgele ek.
  static const double miniLineBase = 20;
  static const int miniLineVariance = 14;
}

/// Onboarding gizlilik sayfasındaki kalkan illüstrasyonu.
abstract final class PrivacyArt {
  /// Halkaların bir genişleme turu.
  static final Duration loop = AppDurations.scene * 2;

  /// Kalkan dairesi, içindeki glif ve zemin tonu.
  static const double hubSize = 140;
  static const double shieldSize = 64;
  static const double hubTint = 0.1;

  /// Halkanın döngü boyunca büyüdüğü pay, başlangıç opaklığı ve kalınlığı.
  static const double ringGrowth = 120;
  static const double ringAlpha = 0.35;
  static const double ringWidth = 2;

  /// İkinci halkanın faz kayması (yarım tur).
  static const double ringPhase = 0.5;

  /// Hareket azaltıldığında gösterilen kare: halkalar yarı açılmış.
  static const double stillFrame = 0.3;
}

/// Onboarding sıralama sayfasındaki dağınık → düzenli kart illüstrasyonu.
abstract final class SortArt {
  /// Dağınık → düzenli geçişin tek yönlü süresi.
  static final Duration loop = AppDurations.scene * 2;

  /// Kart oranı ekran görüntüsüyle aynı; ızgara 3 sütun x 2 satır.
  static const double cardAspect = kScreenshotAspect;

  /// Kart genişliğinin sahne genişliğine oranı (3 sütun + aralıklar).
  static const double cardWidthFraction = 0.24;

  /// Kartların harekete başlama kademesi (döngü oranı, kart başına).
  static const double cardStagger = 0.05;

  /// Mini kartın içi: gölge, görsel bloğu (kart yüksekliğine oran) ve metin
  /// çizgileri (genişlik kart genişliğine oran: taban + rastgele ek).
  static const double cardShadowAlpha = 0.08;
  static const double cardShadowBlur = 12;
  static const Offset cardShadowOffset = Offset(0, 4);
  static const double cardImageRatio = 0.35;
  static const double cardImageAlpha = 0.25;
  static const double cardLineHeight = 4;
  static const double cardLineAlpha = 0.3;
  static const double cardLineMinRatio = 0.4;
  static const double cardLineExtraRatio = 0.4;
}

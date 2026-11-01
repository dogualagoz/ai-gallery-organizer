// Hareket token'ları: Apple'ın damping/response yay modeli + jest sabitleri.
import 'dart:ui' show Size;

import 'package:flutter/physics.dart';

/// Uygulamanın yay (spring) seti. Apple'ın iki parametreli modeli birebir:
/// `duration` = response (hedefe varma hızı; sabit süre DEĞİL), `bounce` =
/// 1 − damping oranı. Varsayılan sekmesizdir; sekme yalnız momentumlu
/// jestlerden (fırlatma, sürükleme bırakma) sonra kullanılır.
abstract final class AppSprings {
  /// Basış anı: neredeyse anlık (CSS `:active` 100ms) — tepki parmak değdiği
  /// karede görünsün, kısa dokunuşlarda bile basılı hal fark edilsin.
  static final SpringDescription press =
      SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 100),
      );

  /// Küçük, hızlı geri bildirimler (basış bırakma, toggle). Damping 1.0.
  static final SpringDescription snappy =
      SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 250),
      );

  /// Varsayılan yeniden konumlama (gösterge, layout, PiP benzeri). Damping 1.0.
  static final SpringDescription standard =
      SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 400),
      );

  /// Momentumlu jest sonrası yerleşme (fırlatılan kart, bırakılan sürükleme).
  /// Damping 0.8 — hafif taşma yalnız kullanıcı hız verdiği için doğal durur.
  static final SpringDescription momentum =
      SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 400),
        bounce: 0.2,
      );

  /// Çekmece/sheet/toast gibi yüzeyler (Apple drawer: damping 0.8, 0.3s).
  static final SpringDescription sheet =
      SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 300),
        bounce: 0.2,
      );

  /// Tek seferlik kutlama rozeti (haftalık kota doldu). Hafif taşma burada
  /// bilinçli: jest yok ama an, kullanıcının emeğinin karşılığı (Delight).
  static final SpringDescription celebrate =
      SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 500),
        bounce: 0.3,
      );

  /// Analiz edilen küçük resmin kategori karosuna süzülmesi. Damping 1.0;
  /// kavisi yaydan değil, ilk yukarı atış hızından gelir.
  static final SpringDescription flight =
      SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 600),
      );
}

/// Analiz uçuşlarının akış ve görünüm sabitleri.
abstract final class AppFlight {
  /// Aynı anda havada olabilecek en fazla kart; fazlası sırada bekler.
  static const int maxConcurrent = 6;

  /// Sıradaki kartın kalkış aralığı (tek tek besleme → akış hissi).
  static const Duration spawnCadence = Duration(milliseconds: 140);

  /// Kalkan resmin yerine gelen yeni kaynak küçük resmin başlangıç ölçeği.
  static const double sourceEnterScale = 0.6;

  /// Uçan kartın ölçüsü — screenshot oranına yakın dikey kart.
  static const Size cardSize = Size(40, 64);

  /// Kalkıştaki yukarı atış hızı (px/s): yolu doğal bir kavise büker.
  static const double launchSpeed = 520;

  /// Kalkıştaki yatay hız sapmasının üst sınırı (px/s): kartlar üst üste
  /// binmesin diye her biri biraz farklı açıyla çıkar.
  static const double lateralJitter = 90;

  /// Karoya varırken küçülme oranı ve yolun sondaki solma payı.
  static const double landingScale = 0.6;
  static const double fadeFraction = 0.3;

  /// Yolun bu oranı tamamlanınca kart inmiş sayılır (yay kuyruğu beklenmez).
  static const double landedAt = 0.97;

  /// Güvenlik sınırı: hedef ölçülemese de kart bu süreden uzun uçmaz.
  static const Duration maxDuration = Duration(seconds: 2);
}

/// Jest ve geri bildirim sabitleri.
abstract final class AppMotion {
  /// Basılı tutulan öğenin ölçeği — dokunuşun ilk karesinde uygulanır.
  static const double pressScale = 0.97;

  /// Reduce Motion açıkken ölçek yerine kullanılan basılı opaklık.
  static const double pressedOpacity = 0.6;

  /// Kaydırılabilir içerikte basılı görünümün gecikmesi (UIScrollView
  /// `delaysContentTouches`): kaydırmaya başlayan parmak karoyu kırpıştırmaz.
  static const Duration scrollPressDelay = Duration(milliseconds: 100);

  /// Gecikme dolmadan biten hızlı dokunuşta basılı halin görünür kalma süresi.
  static const Duration pressFlash = Duration(milliseconds: 100);

  /// Bir yöne kilitlenmeden önce gereken hareket (yanlış tetiklemeyi önler).
  static const double hysteresis = 10;

  /// Kaydırma benzeri doğal yavaşlama (momentum projeksiyonu).
  static const double decelerationNormal = 0.998;

  /// Daha çabuk duran yavaşlama — kart/sayfa gibi kısa mesafeli fırlatmalar.
  static const double decelerationFast = 0.99;

  /// Sınır ötesi lastik direnci sabiti (iOS scroll view değeri).
  static const double rubberbandConstant = 0.55;

  /// Reduce Motion açıkken kayma/yay yerine kullanılan çapraz geçiş süresi.
  static const Duration reducedCrossfade = Duration(milliseconds: 200);

  /// Native launch screen'den ilk ekrana geçişteki kısa çapraz geçiş.
  static const Duration launchReveal = Duration(milliseconds: 250);

  /// Düzenleme modunda karoyu sürüklemek için gereken basılı tutma süresi
  /// (normal uzun basıştan kısa: mod zaten "taşıma" niyetini belirtiyor).
  static const Duration liftDelay = Duration(milliseconds: 250);

  /// Bırakılan sıranın veriye yansımasının en fazla beklendiği süre; aşılırsa
  /// ızgara veri sırasına döner (kayıt başarısız olsa da kilit kalmaz).
  static const Duration reorderCommitTimeout = Duration(seconds: 1);

  /// Düzenleme modu titreşiminin tepe açısı (radyan, ~1.4°) ve tam periyodu.
  static const double jiggleAngle = 0.025;
  static const Duration jigglePeriod = Duration(milliseconds: 280);

  /// Komşu karoların titreşim fazını birbirinden ayıran çarpan (tur oranı);
  /// irrasyonele yakın değer, ardışık karoların eşleşmesini önler.
  static const double jigglePhaseSpread = 0.37;

  /// Yer değiştiren alt çubukların (sekme çubuğu ↔ seçim araç çubuğu) gizliyken
  /// küçüldüğü oran: biri sönerken diğeri aynı yerde belirir.
  static const double chromeHiddenScale = 0.94;
}

/// Fotoğraf görüntüleyicinin geçiş, yakınlaştırma ve jest sabitleri.
abstract final class AppViewer {
  /// Açılış/kapanış süresi: zemin bu sürede solar, Hero uçuşu yolunu yay
  /// eğrisiyle aynı sürede tamamlar.
  static const Duration transition = Duration(milliseconds: 450);

  /// En fazla yakınlaştırma ve çift dokunuşun hedef ölçeği.
  static const double maxZoom = 4;
  static const double doubleTapZoom = 2.5;

  /// Bu ölçeğin üstü "yakınlaştırılmış" sayılır: sayfa kaydırma ve aşağı
  /// çekip kapatma kilitlenir, sürükleme görseli gezdirir.
  static const double zoomedThreshold = 1.01;

  /// Aşağı çekişte kapanma için gereken öngörülen mesafe (px): konum +
  /// bırakış hızının projeksiyonu bu eşiği geçerse görüntüleyici kapanır.
  static const double dismissDistance = 120;

  /// Ekran yüksekliğinin bu oranı kadar çekilince zemin tamamen saydamlaşır
  /// ve görsel en küçük ölçeğine iner.
  static const double dismissFadeSpan = 0.35;
  static const double dismissMinScale = 0.7;

  /// Bilgi panelinin ekran yüksekliğine oranı.
  static const double infoPanelFraction = 0.55;

  /// Panel sürüklemesi bırakılınca öngörülen açıklık bu oranı geçerse açılır.
  static const double infoOpenThreshold = 0.5;

  /// Tam çözünürlüklü görselin uzun kenar sınırı (px): bellek tavanı.
  static const int fullImageMaxPx = 2880;

  /// Boyutu bilinmeyen varlık için tam görsel ölçüsü (dikey ekran oranı).
  static const Size fallbackFullSize = Size(1080, 1920);

  /// Bulunamayan görüntü ekranının kendiliğinden kapanma gecikmesi.
  static const Duration missingAutoClose = Duration(seconds: 2);
}

/// Temizle destesindeki kart jestinin sabitleri.
abstract final class AppSwipe {
  /// Karar eşiği (px): konum + bırakış hızının projeksiyonu baskın yönde bunu
  /// geçerse kart gider. Sürüklerken aynı eşik ipucu ve haptiği belirler.
  static const double threshold = 120;

  /// Kısa mesafeli fırlatmanın projeksiyon yavaşlaması.
  static const double deceleration = AppMotion.decelerationFast;

  /// Parmak gidiş yönünün tersine bu hızdan (px/s) hızlı dönüyorsa kullanıcı
  /// vazgeçiyor sayılır: eşik geçilmiş olsa da kart yerine döner.
  static const double cancelVelocity = 100;

  /// Eşikte gidip gelen parmağın haptiği tekrar tekrar tetiklemesini önleyen
  /// pay (px): bölgeden çıkmak için eşiğin bu kadar gerisine dönmek gerekir.
  static const double armHysteresis = AppMotion.hysteresis;

  /// Kartın bir kart genişliği kadar yatay yolda yattığı açı (radyan);
  /// eşikte yaklaşık 4°.
  static const double rotationPerWidth = 0.2;

  /// Kartın en fazla yatış açısı (radyan, ≈11.5°): ekrandan çıkarken de
  /// bundan fazla dönmez.
  static const double maxRotation = 0.2;

  /// Gidişteki asgari hız (px/s): butonla ya da yavaş bırakışla giden kart da
  /// kararlı biçimde ekrandan çıkar. Hızlı fırlatmanın hızı aynen korunur.
  static const double minThrowSpeed = 1800;

  /// Giden kartın hedeflendiği uzaklık (ekran boyutunun katı): yay hedefe
  /// yaklaşırken yavaşladığı için hedef ekranın epey dışında seçilir.
  static const double exitDistanceFactor = 1.5;

  /// Giden kartın ağaçta kaldığı süre; bu sürede ekrandan çıkmış olur.
  static const Duration exitDuration = Duration(milliseconds: 500);

  /// Arkadaki kartın dinlenme ölçeği; üstteki kart gittikçe 1'e büyür.
  static const double nextCardScale = 0.94;
}

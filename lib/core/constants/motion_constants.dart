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

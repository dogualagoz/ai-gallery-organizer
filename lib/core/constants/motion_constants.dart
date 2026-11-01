// Hareket token'ları: Apple'ın damping/response yay modeli + jest sabitleri.
import 'package:flutter/physics.dart';

/// Uygulamanın yay (spring) seti. Apple'ın iki parametreli modeli birebir:
/// `duration` = response (hedefe varma hızı; sabit süre DEĞİL), `bounce` =
/// 1 − damping oranı. Varsayılan sekmesizdir; sekme yalnız momentumlu
/// jestlerden (fırlatma, sürükleme bırakma) sonra kullanılır.
abstract final class AppSprings {
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
}

/// Jest ve geri bildirim sabitleri.
abstract final class AppMotion {
  /// Basılı tutulan öğenin ölçeği — dokunuşun ilk karesinde uygulanır.
  static const double pressScale = 0.97;

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
}

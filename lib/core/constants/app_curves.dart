// Ortak animasyon eğrileri: süreli geçişler için yay eğrileri ve yaysız
// kısa geçişlerin eğrileri tek kaynaktan.
import 'package:flutter/animation.dart';

import '../utils/motion_physics.dart';
import 'motion_constants.dart';

/// Uygulamanın eğri seti. Süreli API'ler (`animateTo`, `AnimatedSwitcher`,
/// Hero) yay hissini [SpringCurve] ile alır; yaysız eğriler yalnız ilerleme,
/// solma ve illüstrasyon fazları gibi fiziksel olmayan geçişlerde kullanılır.
abstract final class AppCurves {
  /// Sayfa geçişi, bölüme kaydırma, sahne girişi: sekmesiz standart yay.
  static final Curve standardSlow = SpringCurve(
    AppSprings.standard,
    AppDurations.slow,
  );

  /// Görüntüleyici açılış/kapanışı (Hero uçuşu): geçiş süresine yayılmış
  /// sekmesiz yay.
  static final Curve standardTransition = SpringCurve(
    AppSprings.standard,
    AppViewer.transition,
  );

  /// Küçük, hızlı varışlar (yeni kaynak küçük resim): sekmesiz hızlı yay.
  static final Curve snappyMedium = SpringCurve(
    AppSprings.snappy,
    AppDurations.medium,
  );

  /// Kısa solma, ilerleme çubuğu ve kısa kaydırmalar.
  static const Curve fadeOut = Curves.easeOut;

  /// Yükseklik değişimi gibi belirgin yavaşlayarak oturan geçişler.
  static const Curve settle = Curves.easeOutCubic;

  /// Döngüsel illüstrasyonlarda iki ucu yumuşak faz geçişleri.
  static const Curve scenePhase = Curves.easeInOutCubic;

  /// Reduce Motion çapraz geçişleri ve zamana doğrusal ilerlemeler.
  static const Curve linear = Curves.linear;
}

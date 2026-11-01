// Onboarding illüstrasyonlarının ortak döngü kuralı: Hareketi Azalt açıkken
// sahne tek bir anlamlı karede durur, kapalıyken oynar.
import 'package:flutter/widgets.dart';

import '../../../core/utils/motion_physics.dart';

/// [controller]'ı Reduce Motion tercihine göre oynatır ya da [stillValue]
/// karesinde sabitler. Tercih değişince (didChangeDependencies) yeniden uyar.
mixin IllustrationLoop<T extends StatefulWidget> on State<T> {
  AnimationController get controller;

  /// Hareket azaltıldığında gösterilen kare (0-1).
  double get stillValue;

  /// Hareket serbestken animasyonu başlatır (döngü ya da tek seferlik giriş).
  void play();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      // value ataması çalışan animasyonu da durdurur.
      controller.value = stillValue;
    } else if (!controller.isAnimating) {
      play();
    }
  }
}

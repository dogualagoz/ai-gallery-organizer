// Dynamic Type yardımcısı: erişilebilirlik boyutlarında yatay düzenler
// dikeye döner (iOS'un büyük yazı davranışı).
import 'package:flutter/widgets.dart';

import '../constants/ui_constants.dart';

/// Yazı ölçeği sorguları ([MediaQuery.textScalerOf] üzerinden).
extension AccessibilityTextContext on BuildContext {
  /// Metin ölçeği iOS erişilebilirlik boyutlarındaysa (AX1 ve üstü) true:
  /// yan yana duran etiket/değer çiftleri alt alta dizilir, satırlar sarar.
  bool get accessibilityText =>
      MediaQuery.textScalerOf(this).scale(1) >= AppSizes.accessibilityTextScale;
}

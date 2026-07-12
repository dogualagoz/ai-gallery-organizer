// Semantik haptic sözlüğü: tüm titreşim geri bildirimi tek yerden yönetilir.
import 'package:flutter/services.dart';

/// Uygulama genelindeki haptic kelime dağarcığı. Doğrudan
/// [HapticFeedback] çağırmak yerine buradaki semantik metodlar kullanılır —
/// böylece "hangi an hangi şiddette" kararı tek yerde kalır.
abstract final class Haptics {
  /// Kaç tamamlanmada bir [tick] üretileceği (analiz ilerlemesi).
  static const int progressTickEvery = 10;

  /// [success] deseninin iki vuruşu arasındaki gecikme.
  static const Duration _successGap = Duration(milliseconds: 120);

  /// Hafif seçim/dokunma: buton, sekme, plan kartı, tema seçimi.
  static void tap() => HapticFeedback.selectionClick();

  /// Küçük ilerleme vuruşu: analiz ilerleme tikleri, panoya atama.
  static void tick() => HapticFeedback.lightImpact();

  /// Tekil onay: silme tamamlandı, ayar değişti.
  static void confirm() => HapticFeedback.mediumImpact();

  /// Analiz turu başlatıldı.
  static void analysisStart() => HapticFeedback.mediumImpact();

  /// Kutlamalık başarı ("ta-dah"): analiz turu bitti, restore başarılı.
  static Future<void> success() async {
    HapticFeedback.mediumImpact();
    await Future<void>.delayed(_successGap);
    HapticFeedback.lightImpact();
  }

  /// Satın alma başarısı — [success] ile aynı desen, semantik ayrım için.
  static Future<void> purchaseSuccess() => success();

  /// Önemli eşik: haftalık kota doldu, milestone sayfası açıldı.
  static void milestone() => HapticFeedback.heavyImpact();

  /// Hata/iptal/limit uyarısı.
  static void warning() => HapticFeedback.heavyImpact();
}

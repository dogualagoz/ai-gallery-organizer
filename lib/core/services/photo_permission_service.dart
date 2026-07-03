// Fotoğraf kütüphanesi izin akışının tek noktadan yönetimi.
// Onboarding ve galeri aynı davranışı paylaşır.
import 'package:photo_manager/photo_manager.dart';

/// İzin isteminin sadeleştirilmiş sonucu.
enum PhotoPermissionResult {
  /// Tam veya sınırlı (limited) erişim — uygulama çalışabilir.
  granted,

  /// Kullanıcı reddetti; Ayarlar'a yönlendirme gerekir.
  denied,
}

abstract final class PhotoPermissionService {
  /// Sistem izin diyaloğunu tetikler (daha önce sorulduysa mevcut durumu döner).
  static Future<PhotoPermissionResult> request() async {
    final PermissionState state = await PhotoManager.requestPermissionExtend();
    // limited (seçili fotoğraflar) da yeterli: photo_manager yalnız
    // erişilebilen asset'leri listeler, akış aynı şekilde çalışır.
    return state.hasAccess
        ? PhotoPermissionResult.granted
        : PhotoPermissionResult.denied;
  }

  /// iOS Ayarlar > Snaply sayfasını açar (izin reddedildiyse tek çıkış yolu).
  static Future<void> openSystemSettings() => PhotoManager.openSetting();
}

// Fotoğraf kütüphanesi izin akışının tek noktadan yönetimi.
// Onboarding, galeri ve Kütüphane aynı davranışı paylaşır.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

/// İzin isteminin sadeleştirilmiş sonucu.
enum PhotoPermissionResult {
  /// Tam veya sınırlı (limited) erişim — uygulama çalışabilir.
  granted,

  /// Kullanıcı reddetti; Ayarlar'a yönlendirme gerekir.
  denied,
}

/// Kütüphaneye erişim düzeyi: sınırlı erişim ayrıca anlatılır ("Daha fazla
/// seç"), erişim yokken galeri boş değil izin eksik olarak gösterilir.
enum PhotoAccess { full, limited, denied }

/// Erişim yokken kütüphane okunmaya çalışıldı. Boş liste dönmek yerine
/// fırlatılır ki ekran "hiç ekran görüntüsü yok" ile karıştırmasın.
class PhotoAccessDeniedException implements Exception {
  const PhotoAccessDeniedException();

  @override
  String toString() => 'PhotoAccessDeniedException';
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

  /// Erişim düzeyini çözer; henüz sorulmadıysa sistem diyaloğunu açar.
  static Future<PhotoAccess> resolveAccess() async =>
      _toAccess(await PhotoManager.requestPermissionExtend());

  /// Diyalog açmadan mevcut düzeyi okur (Ayarlar'dan dönüşte yeniden kontrol).
  static Future<PhotoAccess> currentAccess() async => _toAccess(
    await PhotoManager.getPermissionState(
      requestOption: const PermissionRequestOption(),
    ),
  );

  static PhotoAccess _toAccess(PermissionState state) => switch (state) {
    PermissionState.authorized => PhotoAccess.full,
    PermissionState.limited => PhotoAccess.limited,
    _ => PhotoAccess.denied,
  };

  /// Sınırlı erişimde sistemin fotoğraf seçicisini açar ("Daha fazla seç").
  static Future<void> presentLimitedPicker() => PhotoManager.presentLimited();

  /// iOS Ayarlar > Snaply sayfasını açar (izin reddedildiyse tek çıkış yolu).
  static Future<void> openSystemSettings() => PhotoManager.openSetting();
}

/// Kütüphane erişim düzeyi. Galeri buna bağlıdır: düzey değişince (ör.
/// Ayarlar'da izin verildi) kendiliğinden yeniden eşitlenir.
final photoAccessProvider =
    AsyncNotifierProvider<PhotoAccessNotifier, PhotoAccess>(
      PhotoAccessNotifier.new,
    );

class PhotoAccessNotifier extends AsyncNotifier<PhotoAccess> {
  @override
  Future<PhotoAccess> build() => PhotoPermissionService.resolveAccess();

  /// Uygulama öne dönünce çağrılır. Düzey değiştiyse yayınlar; aynıysa
  /// dinleyenleri (ve galerinin yeniden eşitlenmesini) tetiklemez.
  Future<void> recheck() async {
    try {
      final PhotoAccess next = await PhotoPermissionService.currentAccess();
      if (state.value != next) state = AsyncData(next);
    } catch (error, stackTrace) {
      // Okunamazsa son bilinen düzeyle devam edilir; bir sonraki dönüşte
      // yeniden denenir.
      debugPrint('Fotoğraf izni yeniden okunamadı: $error\n$stackTrace');
    }
  }
}

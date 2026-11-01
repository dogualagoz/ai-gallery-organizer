// Uygulama sürüm bilgisini tek seferlik platform sorgusuyla sağlar.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Sürüm ve build numarası (Ayarlar'daki sürüm satırı, geri bildirim konusu).
/// Okunamazsa hata loglanır; satır boş kalır.
final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  try {
    return await PackageInfo.fromPlatform();
  } catch (error, stackTrace) {
    debugPrint('Sürüm bilgisi okunamadı: $error\n$stackTrace');
    rethrow;
  }
});

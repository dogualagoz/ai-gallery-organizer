// Uygulama sürüm bilgisini tek seferlik platform sorgusuyla sağlar.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/utils/app_logger.dart';

/// Sürüm ve build numarası (Ayarlar'daki sürüm satırı, geri bildirim konusu).
/// Okunamazsa hata loglanır; satır boş kalır.
final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  try {
    return await PackageInfo.fromPlatform();
  } catch (error, stackTrace) {
    logError('Sürüm bilgisi okunamadı', error, stackTrace);
    rethrow;
  }
});

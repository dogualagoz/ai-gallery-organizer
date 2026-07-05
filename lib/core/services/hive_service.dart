// Hive başlatma ve box erişimi (veri katmanının giriş noktası).
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';
import '../models/board.dart';
import '../models/hive/hive_registrar.g.dart';
import '../models/screenshot_entry.dart';

/// Uygulama açılışında bir kez çağrılır: adapter kaydı + şifreli box açma.
///
/// OCR metinleri (şifre/kimlik screenshot'ları dahil) box'larda saklandığı
/// için tüm box'lar AES ile şifrelenir; anahtar iOS Keychain'de tutulur.
abstract final class HiveService {
  static late Box<ScreenshotEntry> screenshots;
  static late Box<Board> boards;

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapters();
    final HiveAesCipher cipher = HiveAesCipher(await _loadOrCreateKey());
    screenshots = await _openEncrypted<ScreenshotEntry>(
      HiveBoxes.screenshots,
      cipher,
    );
    boards = await _openEncrypted<Board>(HiveBoxes.boards, cipher);
  }

  /// Şifreleme anahtarını Keychain'den okur; ilk açılışta üretip kaydeder.
  static Future<Uint8List> _loadOrCreateKey() async {
    const FlutterSecureStorage storage = FlutterSecureStorage();
    final String? stored = await storage.read(
      key: HiveBoxes.encryptionKeyName,
    );
    if (stored != null) return base64Decode(stored);
    final List<int> key = Hive.generateSecureKey();
    await storage.write(
      key: HiveBoxes.encryptionKeyName,
      value: base64Encode(key),
    );
    return Uint8List.fromList(key);
  }

  /// Box'ı şifreli açar; açılamazsa (örn. şifresiz eski format) siler ve
  /// yeniden oluşturur. Uygulama yayınlanmadan şifrelemeye geçildiği için
  /// migration gerekmez — bu yol yalnız geliştirme cihazlarını etkiler ve
  /// veriler galeriden yeniden senkronla geri gelir.
  static Future<Box<T>> _openEncrypted<T>(
    String name,
    HiveAesCipher cipher,
  ) async {
    try {
      return await Hive.openBox<T>(name, encryptionCipher: cipher);
    } catch (error) {
      debugPrint('Hive box "$name" açılamadı, sıfırlanıyor: $error');
      await Hive.deleteBoxFromDisk(name);
      return Hive.openBox<T>(name, encryptionCipher: cipher);
    }
  }
}

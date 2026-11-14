// Hive başlatma ve box erişimi (veri katmanının giriş noktası).
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';
import '../models/board.dart';
import '../models/hive/hive_registrar.g.dart';
import '../models/screenshot_entry.dart';
import '../utils/app_logger.dart';

/// Uygulama açılışında bir kez çağrılır: adapter kaydı + şifreli box açma.
///
/// OCR metinleri (şifre/kimlik screenshot'ları dahil) box'larda saklandığı
/// için tüm box'lar AES ile şifrelenir; anahtar iOS Keychain'de tutulur.
abstract final class HiveService {
  static late Box<ScreenshotEntry> screenshots;
  static late Box<Board> boards;
  static late Box<String> categoryNames;

  /// Genel amaçlı ayar box'ı (ör. sistem kategori sıralaması). Değer türleri
  /// karışık olabildiği için tipsiz (dynamic) tutulur.
  static late Box<dynamic> settings;

  static bool _prepared = false;

  /// Adapter kaydı + şifreli box'ları açar. Açılamazsa (release'de) hatayı
  /// fırlatır; veri silinmez — çağıran kurtarma ekranı gösterir.
  static Future<void> init() async {
    await _prepare();
    final HiveAesCipher cipher = HiveAesCipher(await loadOrCreateKey());
    screenshots = await openEncrypted<ScreenshotEntry>(
      HiveBoxes.screenshots,
      cipher,
    );
    boards = await openEncrypted<Board>(HiveBoxes.boards, cipher);
    categoryNames = await openEncrypted<String>(
      HiveBoxes.categoryNames,
      cipher,
    );
    settings = await openEncrypted<dynamic>(HiveBoxes.settings, cipher);
  }

  /// Tüm yerel box'ları diskten siler (kullanıcı onaylı kurtarma yolu); ardından
  /// [init] yeniden çağrılmalıdır. Galeri verisi senkronla yeniden kurulur.
  static Future<void> resetAll() async {
    await _prepare();
    for (final String name in _boxNames) {
      await Hive.deleteBoxFromDisk(name);
    }
    // Bozuk/okunamayan anahtar yüzünden sıfırlama döngüye girmesin: taze
    // anahtar bir sonraki init'te üretilir (artık box dosyası kalmadı).
    await const FlutterSecureStorage().delete(key: HiveBoxes.encryptionKeyName);
  }

  static const List<String> _boxNames = [
    HiveBoxes.screenshots,
    HiveBoxes.boards,
    HiveBoxes.categoryNames,
    HiveBoxes.settings,
  ];

  /// Hive dizini + adapter kaydı; yeniden denemelerde tekrar edilmez.
  static Future<void> _prepare() async {
    if (_prepared) return;
    await Hive.initFlutter();
    Hive.registerAdapters();
    _prepared = true;
  }

  /// Şifreleme anahtarını Keychain'den okur; ilk açılışta üretip kaydeder.
  ///
  /// Anahtar YOKKEN şifreli box dosyaları diskte duruyorsa yeni anahtar
  /// üretilmez ([StateError] fırlar): Hive yanlış anahtarla "corrupted box
  /// recovery" yapıp dosyayı sessizce boşaltır. Keychain'in geçici okunamaması
  /// (ör. kilitli cihaz) kullanıcı verisini silmemeli; kurtarma ekranı
  /// yeniden dene / onaylı sıfırla sunar.
  @visibleForTesting
  static Future<Uint8List> loadOrCreateKey() async {
    const FlutterSecureStorage storage = FlutterSecureStorage();
    final String? stored = await storage.read(key: HiveBoxes.encryptionKeyName);
    if (stored != null) return base64Decode(stored);
    for (final String name in _boxNames) {
      if (await Hive.boxExists(name)) {
        throw StateError(
          'Şifreleme anahtarı bulunamadı ama "$name" box\'ı diskte duruyor.',
        );
      }
    }
    final List<int> key = Hive.generateSecureKey();
    await storage.write(
      key: HiveBoxes.encryptionKeyName,
      value: base64Encode(key),
    );
    return Uint8List.fromList(key);
  }

  /// Box'ı şifreli açar. Açılamazsa yalnız [resetOnFailure] true iken (debug
  /// varsayılanı: şifresiz eski format geliştirme cihazlarında) siler ve
  /// yeniden oluşturur; release'de kullanıcı verisi ASLA sessizce silinmez —
  /// hata loglanıp fırlatılır ve açılışta kurtarma ekranı gösterilir.
  @visibleForTesting
  static Future<Box<T>> openEncrypted<T>(
    String name,
    HiveAesCipher cipher, {
    bool resetOnFailure = kDebugMode,
  }) async {
    try {
      return await Hive.openBox<T>(name, encryptionCipher: cipher);
    } catch (error, stackTrace) {
      logError('Hive box "$name" açılamadı', error, stackTrace);
      if (!resetOnFailure) rethrow;
      await Hive.deleteBoxFromDisk(name);
      return Hive.openBox<T>(name, encryptionCipher: cipher);
    }
  }
}

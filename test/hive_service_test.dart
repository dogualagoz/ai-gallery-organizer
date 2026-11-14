// HiveService: anahtar kaybında veri silinmez; box yalnız izin verilirse sıfırlanır.
import 'dart:convert';
import 'dart:io';

import 'package:ai_gallery_organizer/core/constants/app_constants.dart';
import 'package:ai_gallery_organizer/core/services/hive_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('hive_service_test');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
    dir.deleteSync(recursive: true);
  });

  group('loadOrCreateKey', () {
    test('kayıtlı anahtarı olduğu gibi döner', () async {
      final List<int> key = Hive.generateSecureKey();
      FlutterSecureStorage.setMockInitialValues({
        HiveBoxes.encryptionKeyName: base64Encode(key),
      });
      expect(await HiveService.loadOrCreateKey(), key);
    });

    test('ilk açılışta (box yok) anahtar üretip saklar', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final key = await HiveService.loadOrCreateKey();
      expect(key, hasLength(32));
      expect(await HiveService.loadOrCreateKey(), key);
    });

    test('anahtar yok ama box diskte duruyorsa yeni anahtar ÜRETMEZ', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final Box<String> box = await Hive.openBox<String>(HiveBoxes.screenshots);
      await box.put('k', 'v');
      await box.close();

      expect(HiveService.loadOrCreateKey(), throwsStateError);
      expect(File('${dir.path}/screenshots.hive').existsSync(), isTrue);
    });
  });

  group('openEncrypted', () {
    final HiveAesCipher cipher = HiveAesCipher(Hive.generateSecureKey());

    Future<void> openAsInt() async {
      final Box<int> other = await Hive.openBox<int>(
        'b',
        encryptionCipher: cipher,
      );
      await other.put('k', 1);
    }

    test(
      'açılamazsa resetOnFailure=false hatayı fırlatır, veri durur',
      () async {
        await openAsInt();

        await expectLater(
          HiveService.openEncrypted<String>('b', cipher, resetOnFailure: false),
          throwsA(isA<HiveError>()),
        );
        expect(Hive.box<int>('b').get('k'), 1);
      },
    );

    test('açılamazsa resetOnFailure=true box\'ı sıfırlayıp açar', () async {
      await openAsInt();

      final Box<String> box = await HiveService.openEncrypted<String>(
        'b',
        cipher,
        resetOnFailure: true,
      );
      expect(box.isEmpty, isTrue);
    });
  });
}

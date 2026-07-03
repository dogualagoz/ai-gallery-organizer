// Hive başlatma ve box erişimi (veri katmanının giriş noktası).
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';
import '../models/board.dart';
import '../models/hive/hive_registrar.g.dart';
import '../models/screenshot_entry.dart';

/// Uygulama açılışında bir kez çağrılır: adapter kaydı + box açma.
abstract final class HiveService {
  static late Box<ScreenshotEntry> screenshots;
  static late Box<Board> boards;

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapters();
    screenshots = await Hive.openBox<ScreenshotEntry>(HiveBoxes.screenshots);
    boards = await Hive.openBox<Board>(HiveBoxes.boards);
  }
}

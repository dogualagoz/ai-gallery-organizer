// Hive adapter üretim tanımı — modeller annotation'sız kalır,
// adapter'lar build_runner ile buradan üretilir (hive_ce_generator).
import 'package:hive_ce/hive.dart';

import '../board.dart';
import '../screenshot_category.dart';
import '../screenshot_entry.dart';

part 'hive_adapters.g.dart';

// Üretim tetikleyicisi: annotation'ın bağlanacağı boş bir eleman gerekir.
@GenerateAdapters([
  AdapterSpec<ScreenshotEntry>(),
  AdapterSpec<Board>(),
  AdapterSpec<ScreenshotCategory>(),
])
// ignore: unused_element
void _() {}

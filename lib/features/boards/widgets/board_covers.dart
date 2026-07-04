// Board kartı kapak thumbnail'larını seçen paylaşılan yardımcı.
import 'package:photo_manager/photo_manager.dart';

import '../../../core/models/screenshot_entry.dart';
import '../../gallery/data/screenshot_repository.dart';
import 'board_tile.dart';

/// Board içeriğinden kapakta gösterilecek asset'leri seçer.
List<AssetEntity> boardCovers(
  ScreenshotRepository repo,
  List<ScreenshotEntry> boardEntries,
) {
  return boardEntries
      .map((entry) => repo.assetFor(entry.assetId))
      .whereType<AssetEntity>()
      .take(kBoardCoverCount)
      .toList();
}

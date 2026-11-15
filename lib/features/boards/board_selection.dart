// Pano/kategori detayındaki seçimin saf yardımcıları.
import '../../core/models/screenshot_entry.dart';

/// [entries] içinden [selection]'da olanların kimlikleri, ızgara sırasıyla.
/// Silinen ya da başka yere taşınanlar seçimden kendiliğinden düşer.
List<String> selectedAssetIds(
  List<ScreenshotEntry> entries,
  Set<String> selection,
) => [
  for (final ScreenshotEntry entry in entries)
    if (selection.contains(entry.assetId)) entry.assetId,
];

// AnalysisQueueState.afterSuccess: sayaç, sınırlı recent listesi ve
// kategori sayacı matematiği testleri.
import 'package:ai_gallery_organizer/core/models/screenshot_category.dart';
import 'package:ai_gallery_organizer/features/analysis/providers/analysis_queue_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalysisQueueState.afterSuccess', () {
    test('done artar, öğe recent listesine ve kategori sayacına eklenir', () {
      const initial = AnalysisQueueState(
        status: AnalysisQueueStatus.running,
        total: 5,
      );
      final AnalysisQueueState next = initial.afterSuccess(
        const AnalyzedItem(
          assetId: 'a1',
          category: ScreenshotCategory.social,
        ),
      );

      expect(next.done, 1);
      expect(next.recent.single.assetId, 'a1');
      expect(next.categoryCounts[ScreenshotCategory.social], 1);
      expect(next.total, 5);
      expect(next.status, AnalysisQueueStatus.running);
    });

    test('aynı kategoriden ikinci başarı sayacı artırır', () {
      const item = AnalyzedItem(
        assetId: 'x',
        category: ScreenshotCategory.shopping,
      );
      final AnalysisQueueState state = const AnalysisQueueState()
          .afterSuccess(item)
          .afterSuccess(item);
      expect(state.categoryCounts[ScreenshotCategory.shopping], 2);
      expect(state.done, 2);
    });

    test('recent listesi maxRecentItems ile sınırlı kalır', () {
      AnalysisQueueState state = const AnalysisQueueState();
      final int overshoot = AnalysisQueueState.maxRecentItems + 4;
      for (int i = 0; i < overshoot; i++) {
        state = state.afterSuccess(
          AnalyzedItem(assetId: 'a$i', category: ScreenshotCategory.other),
        );
      }

      expect(state.recent.length, AnalysisQueueState.maxRecentItems);
      // En eskiler düşer, en yeniler kalır.
      expect(state.recent.last.assetId, 'a${overshoot - 1}');
      expect(state.done, overshoot);
    });
  });
}

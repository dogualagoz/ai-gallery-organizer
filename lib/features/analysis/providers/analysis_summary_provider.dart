// Biten analiz turunun özetini kullanıcı kapatana dek tutar ve kategori
// dağılımını ("+N" rozetleri) kaydeder. Widget ömründen bağımsızdır:
// Kütüphane modülü ekrandan kayıp geri gelse de özet kaybolmaz.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analysis_queue_provider.dart';
import 'recent_distribution_provider.dart';

/// true: son turun özeti gösterilmeyi bekliyor. Yeni tur başlayınca ya da
/// kullanıcı "Bitti" deyince false olur.
final analysisSummaryProvider = NotifierProvider<AnalysisSummaryNotifier, bool>(
  AnalysisSummaryNotifier.new,
);

class AnalysisSummaryNotifier extends Notifier<bool> {
  @override
  bool build() {
    ref.listen(analysisQueueProvider, (previous, next) {
      // Tur kimden başlarsa başlasın (dokunma, auto-sort, yeniden analiz)
      // eski özet kalkar.
      if (next.isRunning) {
        state = false;
        return;
      }
      final bool finished =
          (previous?.isRunning ?? false) &&
          next.status != AnalysisQueueStatus.idle &&
          next.done > 0;
      if (!finished) return;
      // Duraklatılan turda o an süren istek biraz sonra yine kaydedilebilir;
      // durum artık "running" olmadığından o öğe rozete eklenmez (kabul
      // edilebilir küçük sapma, veri yine de doğru kategoride).
      ref.read(recentDistributionProvider.notifier).record(next.categoryCounts);
      state = true;
    });
    return false;
  }

  void dismiss() => state = false;
}

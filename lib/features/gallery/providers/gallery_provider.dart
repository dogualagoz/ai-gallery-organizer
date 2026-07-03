// Galeri state'i: Hive'daki kayıt listesi + cihaz kütüphanesi eşitleme aksiyonu.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/screenshot_entry.dart';
import '../data/screenshot_repository.dart';

/// Galeri listesi. İlk açılışta cihazla otomatik eşitler; sonrasında
/// box değişikliklerini dinleyerek güncel kalır (AI analizi yazınca vs.).
final galleryProvider =
    AsyncNotifierProvider<GalleryNotifier, List<ScreenshotEntry>>(
  GalleryNotifier.new,
);

class GalleryNotifier extends AsyncNotifier<List<ScreenshotEntry>> {
  Timer? _reloadDebounce;

  @override
  Future<List<ScreenshotEntry>> build() async {
    final ScreenshotRepository repo = ref.watch(screenshotRepositoryProvider);

    // Toplu yazımlarda (sync/analiz) her put ayrı event üretir;
    // listeyi tek seferde yenilemek için kısa debounce uygulanır.
    final StreamSubscription<void> subscription =
        repo.watchChanges().listen((_) {
      _reloadDebounce?.cancel();
      _reloadDebounce = Timer(const Duration(milliseconds: 100), () {
        state = AsyncData(repo.sortedEntries());
      });
    });
    ref.onDispose(() {
      subscription.cancel();
      _reloadDebounce?.cancel();
    });

    // Açılışta cihazla eşitle: yeni screenshot'lar pending olarak gelir.
    // Hata durumunda mevcut local veriyle devam edilir (offline dostu).
    try {
      await repo.syncLibrary();
    } catch (error, stackTrace) {
      debugPrint('Galeri eşitleme hatası: $error\n$stackTrace');
    }
    return repo.sortedEntries();
  }

  /// Kullanıcının tetiklediği manuel eşitleme (pull-to-refresh / buton).
  Future<void> sync() async {
    final ScreenshotRepository repo = ref.read(screenshotRepositoryProvider);
    await repo.syncLibrary();
    state = AsyncData(repo.sortedEntries());
  }
}

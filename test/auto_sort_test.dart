// Auto-sort tetiği: yalnız bekleyen sayısı artınca, durdurulan turu yeniden başlatmaz.
import 'package:ai_gallery_organizer/core/models/screenshot_entry.dart';
import 'package:ai_gallery_organizer/core/services/preferences_service.dart';
import 'package:ai_gallery_organizer/features/analysis/providers/analysis_queue_provider.dart';
import 'package:ai_gallery_organizer/features/analysis/providers/auto_sort_provider.dart';
import 'package:ai_gallery_organizer/features/gallery/providers/gallery_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeGallery extends GalleryNotifier {
  _FakeGallery(this.initial);

  final List<ScreenshotEntry> initial;

  @override
  Future<List<ScreenshotEntry>> build() async => initial;

  void push(List<ScreenshotEntry> entries) => state = AsyncData(entries);
}

class _RecordingQueue extends AnalysisQueueNotifier {
  int starts = 0;
  bool stopped = false;

  @override
  Future<void> start({Iterable<String>? onlyAssetIds}) async => starts++;

  @override
  bool get stoppedByUser => stopped;

  void setQueueState(AnalysisQueueState next) => state = next;
}

ScreenshotEntry _entry(String id, {bool pending = true}) => ScreenshotEntry(
  assetId: id,
  createdAt: DateTime(2026),
  analyzedAt: pending ? null : DateTime(2026, 2),
);

Future<void> _pump() => Future<void>.delayed(Duration.zero);

void main() {
  late ProviderContainer container;
  late _FakeGallery gallery;
  late _RecordingQueue queue;

  Future<void> setUpAuto({
    bool pro = true,
    List<ScreenshotEntry>? initial,
  }) async {
    SharedPreferences.setMockInitialValues({PrefKeys.isPro: pro});
    final prefs = await SharedPreferences.getInstance();
    gallery = _FakeGallery(initial ?? [_entry('a')]);
    queue = _RecordingQueue();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        galleryProvider.overrideWith(() => gallery),
        analysisQueueProvider.overrideWith(() => queue),
      ],
    );
    addTearDown(container.dispose);
    container.read(autoSortControllerProvider);
    await container.read(galleryProvider.future);
    await _pump();
  }

  test('açılışta bekleyen varsa Pro kullanıcıda tur başlar', () async {
    await setUpAuto();
    expect(queue.starts, 1);
  });

  test('free kullanıcıda tur başlamaz', () async {
    await setUpAuto(pro: false);
    expect(queue.starts, 0);
  });

  test(
    'bekleyen sayısı artmayan galeri olayı turu yeniden başlatmaz',
    () async {
      await setUpAuto();
      gallery.push([_entry('a')]);
      gallery.push([_entry('a', pending: false)]);
      gallery.push([_entry('a', pending: false), _entry('b', pending: false)]);
      await _pump();
      expect(queue.starts, 1);
    },
  );

  test('yeni screenshot gelince tur yeniden başlar', () async {
    await setUpAuto();
    gallery.push([_entry('a'), _entry('b')]);
    await _pump();
    expect(queue.starts, 2);
  });

  test('tur sürerken gelen screenshot, tur doğal bitince işlenir', () async {
    await setUpAuto();
    queue.setQueueState(
      const AnalysisQueueState(status: AnalysisQueueStatus.running),
    );
    gallery.push([_entry('a'), _entry('b')]);
    await _pump();
    expect(queue.starts, 1);

    queue.setQueueState(
      const AnalysisQueueState(status: AnalysisQueueStatus.completed),
    );
    await _pump();
    expect(queue.starts, 2);
  });

  test('kullanıcı durdurduysa sürerken gelenler için tur başlamaz', () async {
    await setUpAuto();
    queue.setQueueState(
      const AnalysisQueueState(status: AnalysisQueueStatus.running),
    );
    gallery.push([_entry('a'), _entry('b')]);
    await _pump();

    queue.stopped = true;
    queue.setQueueState(
      const AnalysisQueueState(status: AnalysisQueueStatus.completed),
    );
    await _pump();
    expect(queue.starts, 1);
  });

  test('auto-sort kapalıyken başlamaz; açılınca bekleyenler alınır', () async {
    await setUpAuto(pro: true, initial: const []);
    await container.read(autoSortEnabledProvider.notifier).setEnabled(false);
    gallery.push([_entry('a')]);
    await _pump();
    expect(queue.starts, 0);

    await container.read(autoSortEnabledProvider.notifier).setEnabled(true);
    await _pump();
    expect(queue.starts, 1);
  });
}

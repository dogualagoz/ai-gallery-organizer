// Analiz sırasında tamamlanan screenshot'ların gölgelerini ilerleme
// kartından ana sayfadaki kategori kartlarına uçuran overlay katmanı.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../../../core/constants/ui_constants.dart';
import '../../../core/models/screenshot_category.dart';
import '../../../core/services/haptic_service.dart';
import '../../gallery/data/screenshot_repository.dart';
import '../providers/analysis_queue_provider.dart';

/// Aynı anda uçabilen gölge sayısı; fazlası kısa bir kuyruğa alınır.
const int _maxConcurrentGhosts = 3;

/// Kuyrukta bekletilecek en fazla gölge — hızlı burst'lerde gerisi atlanır
/// (her sonucun animasyonu şart değil, akış hissi yeterli).
const int _maxQueuedGhosts = 8;

/// Gölge kartın ekran ölçüleri.
const Size _ghostSize = Size(40, 70);

/// Alt ağaçtaki widget'ların uçuş kaynak/hedef konumlarını kaydettiği kapsam.
/// [sourceKey] ilerleme kartına, [keyFor] ile alınan anahtarlar kategori
/// kartlarına iliştirilir; katman konumları bu anahtarlardan çözer.
class CategoryFlyScope extends InheritedWidget {
  const CategoryFlyScope({
    super.key,
    required this.sourceKey,
    required this.keyFor,
    required super.child,
  });

  final GlobalKey sourceKey;
  final GlobalKey Function(ScreenshotCategory category) keyFor;

  static CategoryFlyScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CategoryFlyScope>();

  @override
  bool updateShouldNotify(CategoryFlyScope oldWidget) => false;
}

class CategoryFlyLayer extends ConsumerStatefulWidget {
  const CategoryFlyLayer({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CategoryFlyLayer> createState() => _CategoryFlyLayerState();
}

class _CategoryFlyLayerState extends ConsumerState<CategoryFlyLayer>
    with TickerProviderStateMixin {
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _sourceKey = GlobalKey();
  final Map<ScreenshotCategory, GlobalKey> _categoryKeys = {};
  final List<_Ghost> _ghosts = [];
  final List<AnalyzedItem> _spawnQueue = [];
  final Random _random = Random();

  /// Katman kurulduğunda süren turun eski sonuçları tekrar oynatılmaz.
  late int _lastSeenDone = ref.read(analysisQueueProvider).done;

  GlobalKey _keyFor(ScreenshotCategory category) =>
      _categoryKeys.putIfAbsent(category, GlobalKey.new);

  @override
  void dispose() {
    for (final _Ghost ghost in _ghosts) {
      ghost.controller.dispose();
    }
    super.dispose();
  }

  /// Kuyruk güncellemelerinden yeni tamamlananları çıkarır, gölge uçurur
  /// ve her [Haptics.progressTickEvery] tamamlanmada tik verir.
  void _onQueueChanged(AnalysisQueueState? previous, AnalysisQueueState next) {
    if (next.done < _lastSeenDone) _lastSeenDone = next.done; // yeni tur
    final int newCount = next.done - _lastSeenDone;
    if (newCount <= 0) return;
    _lastSeenDone = next.done;

    final int take = min(newCount, next.recent.length);
    for (final AnalyzedItem item in next.recent.sublist(
      next.recent.length - take,
    )) {
      if (_spawnQueue.length >= _maxQueuedGhosts) break;
      _spawnQueue.add(item);
    }
    _drainSpawnQueue();

    final int prevDone = next.done - newCount;
    if (next.done ~/ Haptics.progressTickEvery >
        prevDone ~/ Haptics.progressTickEvery) {
      Haptics.tick();
    }
  }

  void _drainSpawnQueue() {
    while (_ghosts.length < _maxConcurrentGhosts && _spawnQueue.isNotEmpty) {
      _spawnGhost(_spawnQueue.removeAt(0));
    }
  }

  /// [key] ile işaretli widget'ın katman koordinatındaki merkezi; widget
  /// henüz yerleşmemişse (ör. kategori kartı yeni oluştu) null döner.
  Offset? _centerOf(GlobalKey key) {
    final RenderBox? stack =
        _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? target =
        key.currentContext?.findRenderObject() as RenderBox?;
    if (stack == null || target == null || !target.attached) return null;
    return target.localToGlobal(
      target.size.center(Offset.zero),
      ancestor: stack,
    );
  }

  void _spawnGhost(AnalyzedItem item) {
    final Offset? source = _centerOf(_sourceKey);
    final Offset? target = _centerOf(_keyFor(item.category));
    // Kaynak/hedef görünür değilse (kart ekran dışı ya da henüz yok) atla.
    if (source == null || target == null) return;

    final AnimationController controller = AnimationController(
      vsync: this,
      duration: AppDurations.slow,
    );
    final _Ghost ghost = _Ghost(
      asset: ref.read(screenshotRepositoryProvider).assetFor(item.assetId),
      // Aynı anda uçanlar üst üste binmesin diye küçük yatay saçılma.
      start: source + Offset(_random.nextDouble() * 80 - 40, 0),
      end: target,
      controller: controller,
    );
    controller.forward().whenComplete(() {
      if (!mounted) return;
      setState(() => _ghosts.remove(ghost));
      controller.dispose();
      _drainSpawnQueue();
    });
    setState(() => _ghosts.add(ghost));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(analysisQueueProvider, _onQueueChanged);
    return CategoryFlyScope(
      sourceKey: _sourceKey,
      keyFor: _keyFor,
      child: Stack(
        key: _stackKey,
        children: [
          widget.child,
          for (final _Ghost ghost in _ghosts)
            IgnorePointer(child: _GhostCard(ghost: ghost)),
        ],
      ),
    );
  }
}

/// Uçuş halindeki tek gölgenin verisi.
class _Ghost {
  _Ghost({
    required this.asset,
    required this.start,
    required this.end,
    required this.controller,
  });

  final AssetEntity? asset;
  final Offset start;
  final Offset end;
  final AnimationController controller;
}

/// Yarı saydam, kavisli yolda süzülüp hedefte sönerek küçülen gölge kartı.
class _GhostCard extends StatelessWidget {
  const _GhostCard({required this.ghost});

  final _Ghost ghost;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: ghost.controller,
      builder: (context, child) {
        final double t = Curves.easeInOutCubic.transform(
          ghost.controller.value,
        );
        final Offset pos = Offset.lerp(ghost.start, ghost.end, t)! -
            Offset(0, sin(pi * t) * 36);
        final double opacity = t < 0.7 ? 0.9 : 0.9 * (1 - (t - 0.7) / 0.3);
        return Positioned(
          left: pos.dx - _ghostSize.width / 2,
          top: pos.dy - _ghostSize.height / 2,
          child: Opacity(
            opacity: opacity.clamp(0, 1),
            child: Transform.scale(scale: 0.95 - 0.45 * t, child: child),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: SizedBox(
          width: _ghostSize.width,
          height: _ghostSize.height,
          child: ghost.asset != null
              ? AssetEntityImage(
                  ghost.asset!,
                  isOriginal: false,
                  thumbnailSize: const ThumbnailSize.square(150),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      ColoredBox(color: scheme.surfaceContainerHighest),
                )
              : ColoredBox(color: scheme.surfaceContainerHighest),
        ),
      ),
    );
  }
}

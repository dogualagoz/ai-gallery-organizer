// Analiz deneyimi sahnesi: bekleyen thumbnail havuzu, kategori yığınları ve
// tamamlanan öğelerin havuzdan yığına uçuş animasyonu.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../../../../core/constants/ui_constants.dart';
import '../../../../core/l10n/category_labels.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/models/screenshot_category.dart';
import '../../../../core/models/screenshot_entry.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../gallery/data/screenshot_repository.dart';
import '../../providers/analysis_queue_provider.dart';

/// Havuzda gösterilen en fazla thumbnail sayısı (bellek dostu).
const int _poolSize = 14;

/// Aynı anda uçabilen thumbnail sayısı — concurrency 5 burst'lerinde
/// animasyon yığılmasın diye fazlası sıraya alınır.
const int _maxConcurrentFlyers = 4;

/// Kategori yığın satırı için ayrılan alt yükseklik.
const double _stackRowHeight = 108;

/// Mini kart ölçüleri (havuz kartı ve uçan kart aynı dili kullanır).
const Size _miniShotSize = Size(36, 64);

class AnalysisStage extends ConsumerStatefulWidget {
  const AnalysisStage({super.key});

  @override
  ConsumerState<AnalysisStage> createState() => _AnalysisStageState();
}

class _AnalysisStageState extends ConsumerState<AnalysisStage>
    with TickerProviderStateMixin {
  final GlobalKey _stageKey = GlobalKey();
  final Random _random = Random(11);
  final Map<ScreenshotCategory, GlobalKey> _slotKeys = {};
  final Set<String> _consumedIds = {};
  final List<_Flyer> _flyers = [];
  final List<AnalyzedItem> _spawnQueue = [];

  late final List<ScreenshotEntry> _poolEntries;
  late final List<Offset> _poolFractions;
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: AppDurations.scene * 2,
  )..repeat(reverse: true);

  /// Ekran turun ortasında açıldığında eski tamamlananlar tekrar oynatılmaz.
  late int _lastSeenDone;
  Size _stageSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _lastSeenDone = ref.read(analysisQueueProvider).done;
    _poolEntries = ref
        .read(screenshotRepositoryProvider)
        .sortedEntries()
        .where((entry) => entry.isPending)
        .take(_poolSize)
        .toList();
    _poolFractions = List.generate(
      _poolEntries.length,
      (_) => Offset(
        0.08 + _random.nextDouble() * 0.84,
        0.06 + _random.nextDouble() * 0.80,
      ),
    );
  }

  @override
  void dispose() {
    _bob.dispose();
    for (final _Flyer flyer in _flyers) {
      flyer.controller.dispose();
    }
    super.dispose();
  }

  /// Kuyruk güncellemelerinden yeni tamamlananları çıkarıp uçuşa sokar.
  void _onQueueChanged(AnalysisQueueState? previous, AnalysisQueueState next) {
    final int newCount = next.done - _lastSeenDone;
    if (newCount <= 0) return;
    _lastSeenDone = next.done;

    final int take = min(newCount, next.recent.length);
    _spawnQueue.addAll(next.recent.sublist(next.recent.length - take));
    _drainSpawnQueue();

    final int prevDone = next.done - newCount;
    if (next.done ~/ Haptics.progressTickEvery >
        prevDone ~/ Haptics.progressTickEvery) {
      Haptics.tick();
    }
  }

  void _drainSpawnQueue() {
    while (_flyers.length < _maxConcurrentFlyers && _spawnQueue.isNotEmpty) {
      _spawnFlyer(_spawnQueue.removeAt(0));
    }
  }

  void _spawnFlyer(AnalyzedItem item) {
    if (!mounted || _stageSize == Size.zero) return;
    final AnimationController controller = AnimationController(
      vsync: this,
      duration: AppDurations.slow,
    );
    final _Flyer flyer = _Flyer(
      item: item,
      asset: ref.read(screenshotRepositoryProvider).assetFor(item.assetId),
      start: _startPointFor(item.assetId),
      end: _slotCenterFor(item.category),
      controller: controller,
    );
    controller.forward().whenComplete(() {
      if (!mounted) return;
      setState(() => _flyers.remove(flyer));
      controller.dispose();
      _drainSpawnQueue();
    });
    setState(() => _flyers.add(flyer));
  }

  /// Uçuşun başlangıcı: öğe havuzdaysa kendi konumu (kart söner), değilse
  /// havuz alanında rastgele bir nokta.
  Offset _startPointFor(String assetId) {
    final int index = _poolEntries.indexWhere(
      (entry) => entry.assetId == assetId && !_consumedIds.contains(assetId),
    );
    if (index >= 0) {
      _consumedIds.add(assetId);
      return _poolPixel(_poolFractions[index]);
    }
    return _poolPixel(
      Offset(0.2 + _random.nextDouble() * 0.6, 0.2 + _random.nextDouble() * 0.5),
    );
  }

  Offset _poolPixel(Offset fraction) => Offset(
    fraction.dx * _stageSize.width,
    fraction.dy * (_stageSize.height - _stackRowHeight),
  );

  /// Hedef yığının sahne koordinatındaki merkezi; slot henüz yerleşmediyse
  /// alt-orta noktaya düşülür.
  Offset _slotCenterFor(ScreenshotCategory category) {
    final RenderBox? stage =
        _stageKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? slot =
        _slotKeys[category]?.currentContext?.findRenderObject() as RenderBox?;
    if (stage == null || slot == null || !slot.attached) {
      return Offset(_stageSize.width / 2, _stageSize.height - _stackRowHeight / 2);
    }
    return slot.localToGlobal(
      slot.size.center(Offset.zero),
      ancestor: stage,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(analysisQueueProvider, _onQueueChanged);
    final Map<ScreenshotCategory, int> counts = ref.watch(
      analysisQueueProvider.select((state) => state.categoryCounts),
    );
    for (final ScreenshotCategory category in counts.keys) {
      _slotKeys.putIfAbsent(category, GlobalKey.new);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _stageSize = constraints.biggest;
        return Stack(
          key: _stageKey,
          children: [
            for (int i = 0; i < _poolEntries.length; i++)
              _PoolCard(
                entry: _poolEntries[i],
                position: _poolPixel(_poolFractions[i]),
                consumed: _consumedIds.contains(_poolEntries[i].assetId),
                bob: _bob,
                phase: _poolFractions[i].dx * 2 * pi,
              ),
            for (final _Flyer flyer in _flyers) _FlyerCard(flyer: flyer),
            Align(
              alignment: Alignment.bottomCenter,
              child: _CategoryStackRow(counts: counts, slotKeys: _slotKeys),
            ),
          ],
        );
      },
    );
  }
}

/// Uçuş halindeki tek öğenin verisi.
class _Flyer {
  _Flyer({
    required this.item,
    required this.asset,
    required this.start,
    required this.end,
    required this.controller,
  });

  final AnalyzedItem item;
  final AssetEntity? asset;
  final Offset start;
  final Offset end;
  final AnimationController controller;
}

/// Havuzda hafifçe salınan tek kart; uçuşa geçince yumuşakça söner.
class _PoolCard extends StatelessWidget {
  const _PoolCard({
    required this.entry,
    required this.position,
    required this.consumed,
    required this.bob,
    required this.phase,
  });

  final ScreenshotEntry entry;
  final Offset position;
  final bool consumed;
  final Animation<double> bob;
  final double phase;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: bob,
      builder: (context, child) => Positioned(
        left: position.dx - _miniShotSize.width / 2,
        top: position.dy -
            _miniShotSize.height / 2 +
            sin(bob.value * 2 * pi + phase) * 4,
        child: Transform.rotate(
          angle: sin(bob.value * 2 * pi + phase) * 0.06,
          child: child,
        ),
      ),
      child: AnimatedOpacity(
        opacity: consumed ? 0 : 1,
        duration: AppDurations.fast,
        child: _MiniShot(entry: entry),
      ),
    );
  }
}

/// Havuzdan kategori yığınına kavisli yolda uçan kart.
class _FlyerCard extends ConsumerWidget {
  const _FlyerCard({required this.flyer});

  final _Flyer flyer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedBuilder(
      animation: flyer.controller,
      builder: (context, child) {
        final double t = Curves.easeInOutCubic.transform(flyer.controller.value);
        final Offset pos = Offset.lerp(flyer.start, flyer.end, t)! -
            Offset(0, sin(pi * t) * 48);
        return Positioned(
          left: pos.dx - _miniShotSize.width / 2,
          top: pos.dy - _miniShotSize.height / 2,
          child: Transform.scale(scale: 1 - 0.45 * t, child: child),
        );
      },
      child: _MiniShotAsset(asset: flyer.asset),
    );
  }
}

/// Ekranın altındaki kategori yığınları satırı.
class _CategoryStackRow extends StatelessWidget {
  const _CategoryStackRow({required this.counts, required this.slotKeys});

  final Map<ScreenshotCategory, int> counts;
  final Map<ScreenshotCategory, GlobalKey> slotKeys;

  @override
  Widget build(BuildContext context) {
    final List<ScreenshotCategory> ordered = counts.keys.toList();
    return SizedBox(
      height: _stackRowHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            for (final ScreenshotCategory category in ordered)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: _CategoryStack(
                  key: slotKeys[category],
                  category: category,
                  count: counts[category] ?? 0,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tek kategori yığını: ikon + sayaç; sayı değişince küçük bir zıplama yapar.
class _CategoryStack extends StatelessWidget {
  const _CategoryStack({super.key, required this.category, required this.count});

  final ScreenshotCategory category;
  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      // Sayaç her arttığında yeni tween: 1.2'den 1'e yaylanma (pop etkisi).
      key: ValueKey<int>(count),
      tween: Tween(begin: 1.2, end: 1),
      duration: AppDurations.medium,
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(category.icon, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('$count', style: Theme.of(context).textTheme.labelLarge),
          Text(
            category.label(context.l10n),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Entry üzerinden asset çözen havuz kartı görseli.
class _MiniShot extends ConsumerWidget {
  const _MiniShot({required this.entry});

  final ScreenshotEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _MiniShotAsset(
      asset: ref.read(screenshotRepositoryProvider).assetFor(entry.assetId),
    );
  }
}

/// Mini screenshot kartı — hem havuzda hem uçuşta aynı görsel dil.
class _MiniShotAsset extends StatelessWidget {
  const _MiniShotAsset({required this.asset});

  final AssetEntity? asset;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: SizedBox(
        width: _miniShotSize.width,
        height: _miniShotSize.height,
        child: asset != null
            ? AssetEntityImage(
                asset!,
                isOriginal: false,
                thumbnailSize: const ThumbnailSize.square(150),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    ColoredBox(color: scheme.surfaceContainerHighest),
              )
            : ColoredBox(color: scheme.surfaceContainerHighest),
      ),
    );
  }
}

// Tam ekran sinematik analiz sahnesi: bekleyen screenshot'lar merkezdeki
// kaynak yığından, particle izli yumuşak uçuşlarla kategori şeritlerine
// yerleşir; tur bitince özet gösterip kapanır. Kuyruğun ilerlemesini
// analysisQueueProvider'dan izler (gerçek tur ya da debug simulate).
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/screenshot_category.dart';
import '../../core/router/app_router.dart';
import '../../core/services/haptic_service.dart';
import '../gallery/data/screenshot_repository.dart';
import 'providers/analysis_queue_provider.dart';
import 'widgets/scene_flying_card.dart';
import 'widgets/scene_particles.dart';
import 'widgets/scene_widgets.dart';

/// Aynı anda uçabilen kart sayısı; fazlası sabit kadansla kuyrukta bekler.
const int _maxConcurrentFlights = 6;

/// Tek bir kartın kaynaktan şeride süzülme süresi — premium, sakin bir tempo.
const Duration _flightDuration = Duration(milliseconds: 900);

/// Kuyruğu boşaltan sabit kadans (tek tek besleme → akış hissi).
const Duration _spawnCadence = Duration(milliseconds: 140);

/// İniş patlamasının çizim kutusu.
const double _burstSize = 70;

class AnalysisSceneScreen extends ConsumerStatefulWidget {
  const AnalysisSceneScreen({super.key});

  @override
  ConsumerState<AnalysisSceneScreen> createState() =>
      _AnalysisSceneScreenState();
}

class _AnalysisSceneScreenState extends ConsumerState<AnalysisSceneScreen>
    with TickerProviderStateMixin {
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _sourceKey = GlobalKey();
  final Map<ScreenshotCategory, GlobalKey> _laneKeys = {};

  /// Görünme sırasıyla bu turda öğe alan kategoriler (şeritler).
  final List<ScreenshotCategory> _lanes = [];

  /// Şeride fiilen inmiş kart sayısı (state'teki done'dan bağımsız; animasyon
  /// ilerledikçe artar, sayaç ve mini yığın bununla senkron kalır).
  final Map<ScreenshotCategory, int> _landed = {};

  final List<SceneFlight> _flights = [];
  final List<_Burst> _bursts = [];
  final List<AnalyzedItem> _spawnQueue = [];
  final Random _random = Random();

  Timer? _spawnTimer;
  late int _lastSeenDone = ref.read(analysisQueueProvider).done;
  int _landedTotal = 0;
  bool _summaryShown = false;
  bool _successHapticDone = false;

  @override
  void initState() {
    super.initState();
    _spawnTimer = Timer.periodic(_spawnCadence, (_) => _drainSpawnQueue());
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    for (final SceneFlight flight in _flights) {
      flight.controller.dispose();
    }
    super.dispose();
  }

  GlobalKey _laneKeyFor(ScreenshotCategory category) =>
      _laneKeys.putIfAbsent(category, GlobalKey.new);

  /// Kuyruk güncellemesinden yeni tamamlananları çıkarır ve uçuş kuyruğuna
  /// ekler; terminal statüde akış bitince özeti tetikler.
  void _onQueueChanged(AnalysisQueueState? previous, AnalysisQueueState next) {
    if (next.status != AnalysisQueueStatus.running) _maybeFinish(next);

    if (next.done < _lastSeenDone) _lastSeenDone = next.done; // yeni tur
    final int newCount = next.done - _lastSeenDone;
    if (newCount <= 0) return;
    _lastSeenDone = next.done;

    final int take = min(newCount, next.recent.length);
    _spawnQueue.addAll(next.recent.sublist(next.recent.length - take));
    _drainSpawnQueue();
  }

  /// Bir slot boşsa ve layout hazırsa kuyruktan tek kart uçurur.
  void _drainSpawnQueue() {
    if (!mounted) return;
    if (_flights.length >= _maxConcurrentFlights || _spawnQueue.isEmpty) return;
    if (_stackSize() == null) return; // layout henüz yok, sonraki tik dener
    _spawnFlight(_spawnQueue.removeAt(0));
  }

  void _spawnFlight(AnalyzedItem item) {
    final Size stack = _stackSize()!;
    // Hedef var olsun diye şeridi önce ekle (ilk kart fallback noktaya iner,
    // sonrakiler ölçülen gerçek konuma).
    if (!_lanes.contains(item.category)) _lanes.add(item.category);

    final Offset source = _sourceCenter(stack);
    final Offset target = _targetCenter(item.category, stack);
    // Orta noktada yanal drift + yukarı kavis: düz çizgi yerine zarif bir yay.
    final Offset control =
        Offset.lerp(source, target, 0.5)! +
        Offset(_random.nextDouble() * 60 - 30, -30 - _random.nextDouble() * 40);

    final AnimationController controller = AnimationController(
      vsync: this,
      duration: _flightDuration,
    );
    final SceneFlight flight = SceneFlight(
      asset: ref.read(screenshotRepositoryProvider).assetFor(item.assetId),
      start: source + Offset(_random.nextDouble() * 40 - 20, 0),
      control: control,
      end: target,
      controller: controller,
    );
    controller.forward().whenComplete(() => _onLanded(flight, item));
    setState(() => _flights.add(flight));
  }

  /// Kart şeride indi: uçuşu kaldır, şerit sayacını ve mini yığını artır,
  /// patlama zerrelerini bırak, tik haptic'i ver, sıradakini besle.
  void _onLanded(SceneFlight flight, AnalyzedItem item) {
    // Unmounted ise controller'ları zaten dispose() kapatmıştır — tekrar
    // dispose etme (çift-dispose fırlatır).
    if (!mounted) return;
    flight.controller.dispose();
    final _Burst burst = _Burst(flight.end);
    setState(() {
      _flights.remove(flight);
      _landed[item.category] = (_landed[item.category] ?? 0) + 1;
      _landedTotal += 1;
      _bursts.add(burst);
    });
    if (_landedTotal % Haptics.progressTickEvery == 0) Haptics.tick();
    _drainSpawnQueue();
    _maybeFinish(ref.read(analysisQueueProvider));
  }

  /// Tur terminal statüye geçtiyse ve tüm uçuşlar bittiyse özeti gösterir;
  /// hiç yerleşen yoksa (anında limit/hata) sahneyi sessizce kapatır.
  void _maybeFinish(AnalysisQueueState state) {
    final bool terminal =
        state.status != AnalysisQueueStatus.running &&
        state.status != AnalysisQueueStatus.idle;
    if (!terminal || _summaryShown) return;
    if (_spawnQueue.isNotEmpty || _flights.isNotEmpty) return; // akış sürüyor

    _summaryShown = true;
    if (_landedTotal == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
      return;
    }
    if (!_successHapticDone && state.status == AnalysisQueueStatus.completed) {
      _successHapticDone = true;
      Haptics.success();
    }
    setState(() {});
  }

  Size? _stackSize() {
    final RenderBox? box =
        _stackKey.currentContext?.findRenderObject() as RenderBox?;
    return (box != null && box.hasSize) ? box.size : null;
  }

  /// [key] ile işaretli widget'ın stack koordinatındaki merkezi; henüz
  /// yerleşmemişse null.
  Offset? _centerOf(GlobalKey key) {
    final RenderBox? stack =
        _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? target =
        key.currentContext?.findRenderObject() as RenderBox?;
    if (stack == null ||
        target == null ||
        !target.attached ||
        !target.hasSize) {
      return null;
    }
    return target.localToGlobal(
      target.size.center(Offset.zero),
      ancestor: stack,
    );
  }

  Offset _sourceCenter(Size stack) =>
      _centerOf(_sourceKey) ?? Offset(stack.width / 2, stack.height * 0.26);

  /// Şerit ölçülemezse (yeni eklendi) index'ten türetilen yaklaşık noktaya
  /// düş — böylece kart hiç donmaz.
  Offset _targetCenter(ScreenshotCategory category, Size stack) {
    final Offset? real = _centerOf(_laneKeyFor(category));
    if (real != null) return real;
    final int i = _lanes.indexOf(category);
    final int col = i % 2;
    final int row = i ~/ 2;
    return Offset(
      stack.width * (col == 0 ? 0.30 : 0.72),
      stack.height * 0.52 + row * 60,
    );
  }

  void _close() {
    ref.read(analysisQueueProvider.notifier).cancel();
    context.pop();
  }

  /// Bitti: sahneyi kapatır; haftalık free kota bu turda tükendiyse milestone
  /// kutlamasını açar (eskiden home listener yapardı; sahne mid-animasyonda
  /// üstüne binmesin diye artık buradan).
  void _onDone() {
    final AnalysisQueueState queue = ref.read(analysisQueueProvider);
    final bool milestone =
        queue.status == AnalysisQueueStatus.limitReached &&
        queue.freeQuotaExhausted &&
        queue.done > 0;
    context.pop();
    if (milestone) context.push(AppRoutes.analysisMilestone);
  }

  /// DEBUG: sahneden çıkmadan animasyonu baştan izle.
  void _replay() {
    final AnalysisQueueNotifier notifier = ref.read(
      analysisQueueProvider.notifier,
    );
    notifier.dismiss();
    setState(() {
      _lanes.clear();
      _landed.clear();
      _flights.clear();
      _bursts.clear();
      _spawnQueue.clear();
      _landedTotal = 0;
      _lastSeenDone = 0;
      _summaryShown = false;
      _successHapticDone = false;
    });
    notifier.simulate();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(analysisQueueProvider, _onQueueChanged);
    final AnalysisQueueState queue = ref.watch(analysisQueueProvider);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final int remaining = (queue.total - _landedTotal).clamp(0, queue.total);

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) ref.read(analysisQueueProvider.notifier).cancel();
      },
      child: Scaffold(
        body: Stack(
          key: _stackKey,
          children: [
            const Positioned.fill(child: SceneBackground()),
            Positioned.fill(
              child: SceneAmbientParticles(color: scheme.primary),
            ),
            Positioned.fill(
              child: SafeArea(
                child: Column(
                  children: [
                    SceneHeader(queue: queue, onClose: _close),
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: SourceCluster(
                          sourceKey: _sourceKey,
                          remaining: remaining,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: LanesArea(
                        lanes: _lanes,
                        landed: _landed,
                        laneKeyFor: _laneKeyFor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            for (final _Burst burst in _bursts)
              Positioned(
                left: burst.center.dx - _burstSize / 2,
                top: burst.center.dy - _burstSize / 2,
                width: _burstSize,
                height: _burstSize,
                child: IgnorePointer(
                  child: LandingBurst(
                    key: burst.key,
                    color: scheme.primary,
                    onDone: () {
                      if (mounted) setState(() => _bursts.remove(burst));
                    },
                  ),
                ),
              ),
            for (final SceneFlight flight in _flights)
              IgnorePointer(child: SceneFlyingCard(flight: flight)),
            if (_summaryShown)
              SummaryPanel(
                done: _landedTotal,
                categories: _landed.length,
                onDone: _onDone,
                onReplay: kDebugMode ? _replay : null,
              ),
          ],
        ),
      ),
    );
  }
}

/// Kısa ömürlü iniş patlaması tanımı (merkez + benzersiz kimlik).
class _Burst {
  _Burst(this.center) : key = UniqueKey();

  final Offset center;
  final Key key;
}

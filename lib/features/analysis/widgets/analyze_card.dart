// Anasayfadaki tek analiz bileşeni: idle'da istatistik + "Analiz et" butonu
// gösterir; butona basınca AYNI kartın içinde (ekstra ekran açmadan) kaynak
// yığından kategori şeritlerine particle izli uçuş animasyonu oynar, biter ve
// özet gösterip idle'a döner. Sahne widget'larını (kaynak yığın, şeritler,
// uçan kart, particle) inline, sınırlı bir Stack içinde yeniden kullanır.
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/models/screenshot_category.dart';
import '../../../core/models/screenshot_entry.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/entitlement_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../gallery/data/screenshot_repository.dart';
import '../providers/analysis_queue_provider.dart';
import 'analyze_card_content.dart';
import 'scene_flying_card.dart';
import 'scene_particles.dart';
import 'scene_widgets.dart';

/// Aynı anda uçabilen kart sayısı; fazlası sabit kadansla kuyrukta bekler.
const int _maxConcurrentFlights = 6;

/// Tek kartın kaynaktan şeride süzülme süresi — sakin, premium tempo.
const Duration _flightDuration = Duration(milliseconds: 900);

/// Kuyruğu boşaltan sabit kadans (tek tek besleme → akış hissi).
const Duration _spawnCadence = Duration(milliseconds: 140);

/// İniş patlamasının çizim kutusu.
const double _burstSize = 70;

/// Animasyon alanının sabit yüksekliği — koordinatlar bu Stack'e göre olduğu
/// için sabit tutulur (tur boyunca hedefler kaymaz).
const double _animAreaHeight = 430;

class AnalyzeCard extends ConsumerStatefulWidget {
  const AnalyzeCard({super.key, required this.entries});

  final List<ScreenshotEntry> entries;

  @override
  ConsumerState<AnalyzeCard> createState() => _AnalyzeCardState();
}

class _AnalyzeCardState extends ConsumerState<AnalyzeCard>
    with TickerProviderStateMixin {
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _sourceKey = GlobalKey();
  final Map<ScreenshotCategory, GlobalKey> _laneKeys = {};

  final List<ScreenshotCategory> _lanes = [];
  final Map<ScreenshotCategory, int> _landed = {};
  final List<SceneFlight> _flights = [];
  final List<_Burst> _bursts = [];
  final List<AnalyzedItem> _spawnQueue = [];
  final Random _random = Random();

  Timer? _spawnTimer;
  int _lastSeenDone = 0;
  int _landedTotal = 0;
  bool _summaryShown = false;
  bool _successHapticDone = false;

  @override
  void initState() {
    super.initState();
    _lastSeenDone = ref.read(analysisQueueProvider).done;
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

  // ---- Kullanıcı aksiyonları ---------------------------------------------

  void _startAnalysis() {
    Haptics.analysisStart();
    _resetLocal();
    ref.read(analysisQueueProvider.notifier).start();
  }

  /// Bitti: özeti kapatıp idle'a döner; haftalık free kota bu turda tükendiyse
  /// milestone kutlamasını açar.
  void _onDone() {
    final AnalysisQueueState queue = ref.read(analysisQueueProvider);
    final bool milestone =
        queue.status == AnalysisQueueStatus.limitReached &&
        queue.freeQuotaExhausted &&
        queue.done > 0;
    ref.read(analysisQueueProvider.notifier).dismiss();
    setState(_resetLocal);
    if (milestone) context.push(AppRoutes.analysisMilestone);
  }

  /// DEBUG: animasyonu baştan izle.
  void _replay() {
    ref.read(analysisQueueProvider.notifier).dismiss();
    setState(_resetLocal);
    ref.read(analysisQueueProvider.notifier).simulate();
  }

  void _resetLocal() {
    for (final SceneFlight flight in _flights) {
      flight.controller.dispose();
    }
    _flights.clear();
    _bursts.clear();
    _spawnQueue.clear();
    _lanes.clear();
    _landed.clear();
    _landedTotal = 0;
    _lastSeenDone = 0;
    _summaryShown = false;
    _successHapticDone = false;
  }

  // ---- Kuyruk → uçuş akışı ------------------------------------------------

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

  void _drainSpawnQueue() {
    if (!mounted) return;
    if (_flights.length >= _maxConcurrentFlights || _spawnQueue.isEmpty) return;
    if (_stackSize() == null) return; // layout henüz yok, sonraki tik dener
    _spawnFlight(_spawnQueue.removeAt(0));
  }

  void _spawnFlight(AnalyzedItem item) {
    final Size stack = _stackSize()!;
    if (!_lanes.contains(item.category)) _lanes.add(item.category);

    final Offset source = _sourceCenter(stack);
    final Offset target = _targetCenter(item.category, stack);
    final Offset control =
        Offset.lerp(source, target, 0.5)! +
        Offset(_random.nextDouble() * 60 - 30, -24 - _random.nextDouble() * 30);

    final AnimationController controller = AnimationController(
      vsync: this,
      duration: _flightDuration,
    );
    final SceneFlight flight = SceneFlight(
      asset: ref.read(screenshotRepositoryProvider).assetFor(item.assetId),
      start: source + Offset(_random.nextDouble() * 30 - 15, 0),
      control: control,
      end: target,
      controller: controller,
    );
    controller.forward().whenComplete(() => _onLanded(flight, item));
    setState(() => _flights.add(flight));
  }

  void _onLanded(SceneFlight flight, AnalyzedItem item) {
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

  /// Tur terminal statüye geçtiyse ve tüm uçuşlar bittiyse özeti gösterir.
  /// Hiç yerleşen yoksa (anında limit/hata) özet göstermez; build o durumda
  /// ilgili mesaj satırını çizer.
  void _maybeFinish(AnalysisQueueState state) {
    final bool terminal =
        state.status != AnalysisQueueStatus.running &&
        state.status != AnalysisQueueStatus.idle;
    if (!terminal || _summaryShown) return;
    if (_spawnQueue.isNotEmpty || _flights.isNotEmpty) return;
    if (_landedTotal == 0) return;

    _summaryShown = true;
    if (!_successHapticDone && state.status == AnalysisQueueStatus.completed) {
      _successHapticDone = true;
      Haptics.success();
    }
    setState(() {});
  }

  // ---- Koordinat yardımcıları --------------------------------------------

  Size? _stackSize() {
    final RenderBox? box =
        _stackKey.currentContext?.findRenderObject() as RenderBox?;
    return (box != null && box.hasSize) ? box.size : null;
  }

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
      _centerOf(_sourceKey) ?? Offset(stack.width / 2, stack.height * 0.24);

  Offset _targetCenter(ScreenshotCategory category, Size stack) {
    final Offset? real = _centerOf(_laneKeyFor(category));
    if (real != null) return real;
    final int i = _lanes.indexOf(category);
    final int col = i % 2;
    final int row = i ~/ 2;
    return Offset(
      stack.width * (col == 0 ? 0.30 : 0.72),
      stack.height * 0.5 + row * 56,
    );
  }

  // ---- Yapı ---------------------------------------------------------------

  int get _pending => widget.entries.where((entry) => entry.isPending).length;

  bool get _animating =>
      ref.read(analysisQueueProvider).isRunning ||
      _flights.isNotEmpty ||
      _spawnQueue.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    ref.listen(analysisQueueProvider, _onQueueChanged);
    final AnalysisQueueState queue = ref.watch(analysisQueueProvider);
    final ColorScheme scheme = Theme.of(context).colorScheme;

    final (String phase, Widget? inner) = _content(queue);
    if (inner == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          scheme.primary.withValues(alpha: 0.05),
          scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: AnimatedSize(
        duration: AppDurations.medium,
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: AppDurations.medium,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(key: ValueKey<String>(phase), child: inner),
        ),
      ),
    );
  }

  /// (faz anahtarı, içerik) — içerik null ise kart hiç gösterilmez.
  (String, Widget?) _content(AnalysisQueueState queue) {
    if (_summaryShown) {
      return (
        'summary',
        AnalyzeInlineSummary(
          done: _landedTotal,
          categories: _landed.length,
          onDone: _onDone,
          onReplay: kDebugMode ? _replay : null,
        ),
      );
    }
    if (_animating) return ('anim', _animationArea(queue));

    switch (queue.status) {
      case AnalysisQueueStatus.idle:
      case AnalysisQueueStatus.running:
        if (_pending <= 0) return ('idle', null);
        return (
          'idle',
          AnalyzeIdle(
            pending: _pending,
            analyzed: widget.entries.length - _pending,
            onAnalyze: _startAnalysis,
          ),
        );
      case AnalysisQueueStatus.completed:
        return ('idle', null);
      case AnalysisQueueStatus.limitReached:
        return ('limit', _limitRow());
      case AnalysisQueueStatus.failed:
        return ('failed', _failedRow());
      case AnalysisQueueStatus.dailyCapReached:
        return ('dailycap', _dailyCapRow());
    }
  }

  Widget _animationArea(AnalysisQueueState queue) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final int remaining = (queue.total - _landedTotal).clamp(0, queue.total);
    return SizedBox(
      height: _animAreaHeight,
      child: Stack(
        key: _stackKey,
        children: [
          Positioned.fill(child: SceneAmbientParticles(color: scheme.primary)),
          Positioned.fill(
            child: Column(
              children: [
                _AnimHeader(queue: queue, onCancel: _cancel),
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
            SceneFlyingCard(flight: flight),
        ],
      ),
    );
  }

  void _cancel() {
    Haptics.warning();
    ref.read(analysisQueueProvider.notifier).cancel();
  }

  Widget _limitRow() {
    final bool inTrial = ref.read(entitlementProvider).isInTrialWindow;
    return AnalyzeMessageRow(
      icon: Icons.workspace_premium_outlined,
      text: inTrial
          ? context.l10n.analysisTrialLimitBanner
          : context.l10n.analysisLimitBanner,
      actionLabel: context.l10n.paywallTitle,
      onAction: () => context.push(AppRoutes.paywallPacks),
      onDismiss: () => ref.read(analysisQueueProvider.notifier).dismiss(),
    );
  }

  Widget _failedRow() {
    return AnalyzeMessageRow(
      icon: Icons.error_outline,
      text: context.l10n.analysisFailedBanner,
      actionLabel: context.l10n.analysisRetryAction,
      onAction: _startAnalysis,
      onDismiss: () => ref.read(analysisQueueProvider.notifier).dismiss(),
    );
  }

  Widget _dailyCapRow() {
    return AnalyzeMessageRow(
      icon: Icons.schedule_outlined,
      text: context.l10n.analysisDailyCapBanner,
      onDismiss: () => ref.read(analysisQueueProvider.notifier).dismiss(),
    );
  }
}

/// Animasyon başlığı: başlık + ilerleme + iptal.
class _AnimHeader extends StatelessWidget {
  const _AnimHeader({required this.queue, required this.onCancel});

  final AnalysisQueueState queue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final int processed = queue.done + queue.failed;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.analysisExperienceTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                l10n.analysisProgress(processed, queue.total),
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: l10n.analysisCancelAction,
          icon: Icon(Icons.close, color: scheme.onSurfaceVariant),
          onPressed: onCancel,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

/// Kısa ömürlü iniş patlaması tanımı (merkez + benzersiz kimlik).
class _Burst {
  _Burst(this.center) : key = UniqueKey();

  final Offset center;
  final Key key;
}

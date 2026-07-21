// Anasayfadaki tek analiz bileşeni. Idle'da istatistik + "Analiz et" butonu
// gösterir; butona basınca istatistikler sola kayar, sağdan fotoğraf grubu
// (kaynak yığın) gelir ve bu yığından çıkan fotoğraflar KARTIN DIŞINA taşıp
// anasayfadaki gerçek kategori karolarına particle izli uçuşla iner. Uçuşlar
// tam ekran Overlay'de global koordinatlarla çizilir; hedef karo konumları
// CategoryTargetScope üzerinden çözülür. Tur bitince kart içinde özet gösterir.
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
import 'category_target_scope.dart';
import 'scene_flying_card.dart';
import 'scene_particles.dart';
import 'scene_widgets.dart';

/// Aynı anda uçabilen kart sayısı; fazlası sabit kadansla kuyrukta bekler.
const int _maxConcurrentFlights = 6;

/// Tek kartın kaynaktan karoya süzülme süresi — sakin, premium tempo.
const Duration _flightDuration = Duration(milliseconds: 900);

/// Kuyruğu boşaltan sabit kadans (tek tek besleme → akış hissi).
const Duration _spawnCadence = Duration(milliseconds: 140);

/// İniş patlamasının çizim kutusu.
const double _burstSize = 70;

/// İstatistik → fotoğraf grubu yatay geçişi ve kart genişlemesi süresi.
/// Belirgin, sakin bir açılış için standart geçişten uzun tutulur.
const Duration _revealDuration = Duration(milliseconds: 650);

class AnalyzeCard extends ConsumerStatefulWidget {
  const AnalyzeCard({super.key, required this.entries});

  final List<ScreenshotEntry> entries;

  @override
  ConsumerState<AnalyzeCard> createState() => _AnalyzeCardState();
}

class _AnalyzeCardState extends ConsumerState<AnalyzeCard>
    with TickerProviderStateMixin {
  /// Kaynak yığın (uçuşların çıkış noktası) — global merkezi buradan ölçülür.
  final GlobalKey _clusterKey = GlobalKey();

  final Map<ScreenshotCategory, int> _landed = {};
  final List<SceneFlight> _flights = [];
  final List<_Burst> _bursts = [];
  final List<AnalyzedItem> _spawnQueue = [];
  final Random _random = Random();

  /// Uçan kartlar + patlamalar tam ekran bu katmanda (global koordinat) çizilir.
  OverlayEntry? _overlayEntry;

  Timer? _spawnTimer;
  int _lastSeenDone = 0;
  int _landedTotal = 0;
  bool _summaryShown = false;
  bool _successHapticDone = false;
  // AnimatedSwitcher geçişinde giren/çıkan içeriği ayırmak için son faz anahtarı.
  String _currentPhase = '';

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
    _overlayEntry?.remove();
    super.dispose();
  }

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
    _landed.clear();
    _landedTotal = 0;
    _lastSeenDone = 0;
    _summaryShown = false;
    _successHapticDone = false;
    _overlayEntry?.remove();
    _overlayEntry = null;
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
    if (_sourceCenter() == null) return; // kaynak yığın henüz yerleşmedi
    _spawnFlight(_spawnQueue.removeAt(0));
  }

  void _spawnFlight(AnalyzedItem item) {
    final Offset source = _sourceCenter()!;
    final Offset start = source + Offset(_random.nextDouble() * 30 - 15, 0);
    final Offset target = _targetCenter(item.category, source);
    // Aşağı sarkan kavis (yerçekimi hissi): kontrol noktası orta + aşağı bump.
    final Offset control =
        Offset.lerp(start, target, 0.5)! +
        Offset(_random.nextDouble() * 70 - 35, 30 + _random.nextDouble() * 50);

    final AnimationController controller = AnimationController(
      vsync: this,
      duration: _flightDuration,
    );
    final SceneFlight flight = SceneFlight(
      asset: ref.read(screenshotRepositoryProvider).assetFor(item.assetId),
      start: start,
      control: control,
      end: target,
      controller: controller,
    );
    _ensureOverlay();
    controller.forward().whenComplete(() => _onLanded(flight, item));
    setState(() => _flights.add(flight));
    _overlayEntry?.markNeedsBuild();
  }

  void _onLanded(SceneFlight flight, AnalyzedItem item) {
    if (!mounted) return;
    flight.controller.dispose();
    setState(() {
      _flights.remove(flight);
      _landed[item.category] = (_landed[item.category] ?? 0) + 1;
      _landedTotal += 1;
      _bursts.add(_Burst(flight.end));
    });
    _overlayEntry?.markNeedsBuild();
    if (_landedTotal % Haptics.progressTickEvery == 0) Haptics.tick();
    _drainSpawnQueue();
    _maybeFinish(ref.read(analysisQueueProvider));
  }

  void _removeBurst(_Burst burst) {
    if (!mounted) return;
    _bursts.remove(burst);
    _overlayEntry?.markNeedsBuild();
    _maybeRemoveOverlay();
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

  // ---- Uçuş katmanı (Overlay) --------------------------------------------

  void _ensureOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = OverlayEntry(builder: _buildFlightLayer);
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _maybeRemoveOverlay() {
    if (_flights.isEmpty &&
        _bursts.isEmpty &&
        !ref.read(analysisQueueProvider).isRunning) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  Widget _buildFlightLayer(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: Stack(
        children: [
          for (final _Burst burst in _bursts)
            Positioned(
              left: burst.center.dx - _burstSize / 2,
              top: burst.center.dy - _burstSize / 2,
              width: _burstSize,
              height: _burstSize,
              child: LandingBurst(
                key: burst.key,
                color: scheme.primary,
                onDone: () => _removeBurst(burst),
              ),
            ),
          for (final SceneFlight flight in _flights)
            SceneFlyingCard(flight: flight),
        ],
      ),
    );
  }

  // ---- Global koordinat yardımcıları -------------------------------------

  /// Yüzen cam navbar + safe area'nın alttan kapladığı bant (px); hedef bunun
  /// üstüne clamp'lenir ki fotoğraf navbar'ın altına inmesin.
  double _navBandInset() {
    final double safe = MediaQuery.paddingOf(context).bottom;
    return AppSpacing.sm +
        AppSizes.navBarHeight +
        (safe > 0 ? safe : AppSpacing.md);
  }

  /// Kaynak yığının ekran (global) merkezi; henüz yerleşmemişse null.
  Offset? _sourceCenter() {
    final RenderBox? box =
        _clusterKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  /// Hedef: kategori karosunun ekran merkezi (navbar üstüne clamp'li). Karo
  /// görünmüyorsa (henüz oluşmadı) board bölgesine index'ten türetilen bir
  /// noktaya düşer — böylece uçuş hiç donmaz.
  Offset _targetCenter(ScreenshotCategory category, Offset source) {
    final Size screen = MediaQuery.sizeOf(context);
    final double maxY =
        screen.height - _navBandInset() - sceneCardSize.height / 2;
    final GlobalKey? key = CategoryTargetScope.of(context)?.keyFor(category);
    final RenderBox? box =
        key?.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.attached && box.hasSize) {
      final Offset c = box.localToGlobal(box.size.center(Offset.zero));
      return Offset(c.dx, min(c.dy, maxY));
    }
    final bool leftColumn = category.index.isEven;
    return Offset(
      screen.width * (leftColumn ? 0.30 : 0.70),
      min(source.dy + 300, maxY),
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
    _currentPhase = phase;

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
        duration: _revealDuration,
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: ClipRect(
          child: AnimatedSwitcher(
            duration: _revealDuration,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: _horizontalReveal,
            child: KeyedSubtree(key: ValueKey<String>(phase), child: inner),
          ),
        ),
      ),
    );
  }

  /// Yeni içerik sağdan girer, eski içerik sola çıkar (istatistikler kaybolmaz,
  /// sola kayar; fotoğraf grubu sağdan gelir).
  Widget _horizontalReveal(Widget child, Animation<double> animation) {
    final bool incoming = child.key == ValueKey<String>(_currentPhase);
    final Offset begin = incoming ? const Offset(1, 0) : const Offset(-1, 0);
    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: Offset.zero,
      ).animate(animation),
      child: child,
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
    if (_animating) return ('anim', _clusterContent(queue));

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

  /// Analiz sürerken kart içeriği: başlık/ilerleme + kaynak fotoğraf yığını.
  /// Fotoğraflar bu yığından çıkıp kartın dışındaki karolara uçar.
  Widget _clusterContent(AnalysisQueueState queue) {
    final int remaining = (queue.total - _landedTotal).clamp(0, queue.total);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AnimHeader(queue: queue, onCancel: _onCancelPressed),
        const SizedBox(height: AppSpacing.sm),
        SourceCluster(sourceKey: _clusterKey, remaining: remaining),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  /// Çarpıya basınca: yarıda kes (inenler kalsın) veya sıfırla (baştan) seçimi.
  Future<void> _onCancelPressed() async {
    Haptics.tap();
    final _CancelChoice? choice = await showModalBottomSheet<_CancelChoice>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => const _CancelSheet(),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case _CancelChoice.stop:
        _stopAnalysis();
      case _CancelChoice.reset:
        _resetAnalysis();
    }
  }

  /// Yarıda kes: yeni fotoğraf uçurma, kuyruğu durdur; şimdiye inenlerle özet.
  void _stopAnalysis() {
    Haptics.warning();
    _spawnQueue.clear();
    ref.read(analysisQueueProvider.notifier).cancel();
    _maybeFinish(ref.read(analysisQueueProvider));
  }

  /// Sıfırla: turu tamamen iptal et, kartı anında boşta duruma döndür.
  void _resetAnalysis() {
    Haptics.warning();
    ref.read(analysisQueueProvider.notifier).reset();
    setState(_resetLocal);
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

/// Çarpı pop-up'ının kullanıcı seçimi.
enum _CancelChoice { stop, reset }

/// Analizi yarıda kesme/sıfırlama seçeneklerini sunan alt sayfa.
class _CancelSheet extends StatelessWidget {
  const _CancelSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                l10n.analysisCancelSheetTitle,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
            ListTile(
              leading: Icon(Icons.pause_circle_outline, color: scheme.primary),
              title: Text(l10n.analysisCancelStop),
              subtitle: Text(l10n.analysisCancelStopHint),
              onTap: () => Navigator.of(context).pop(_CancelChoice.stop),
            ),
            ListTile(
              leading: Icon(Icons.restart_alt, color: scheme.error),
              title: Text(l10n.analysisCancelReset),
              subtitle: Text(l10n.analysisCancelResetHint),
              onTap: () => Navigator.of(context).pop(_CancelChoice.reset),
            ),
          ],
        ),
      ),
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

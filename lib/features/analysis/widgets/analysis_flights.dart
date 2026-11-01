// Analiz uçuşları: analiz edilen ekran görüntülerinin küçük resimleri durum
// modülünden kalkıp ilgili kategori karosuna süzülür. Yol, X ve Y eksenlerinde
// ayrı kritik sönümlü yaylardan ve kalkıştaki yukarı atış hızından doğar
// (sabit süreli eğri yok). Katman Kütüphane'nin üstünde, sekme çubuğunun
// altında çizilir; Reduce Motion'da uçuş olmaz.
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../../../core/constants/motion_constants.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/models/screenshot_category.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/utils/motion_physics.dart';

/// Uçacak tek öğe: küçük resmi ve ineceği kategori.
typedef FlightRequest = ({AssetEntity? asset, ScreenshotCategory category});

/// Uçuş katmanının dışa açık yüzü (bkz. [AnalysisFlightScope.of]).
abstract interface class AnalysisFlights {
  /// Kalkış kutusu: uçuşlar bu kutunun sol kenarından [sourceInset] içerideki
  /// orta noktadan kalkar (modüldeki kaynak küçük resmin merkezi).
  GlobalKey get sourceKey;

  /// Kategori karosunun iniş hedefi anahtarı.
  GlobalKey targetKeyFor(ScreenshotCategory category);

  /// Öğeleri sıraya ekler; sabit kadansla teker teker kalkarlar.
  void enqueue(Iterable<FlightRequest> items);

  /// Havadaki ve sıradaki tüm uçuşları anında bitirir.
  void clear();

  /// Havada ya da sırada kart varken true.
  ValueListenable<bool> get busy;
}

/// Kalkış noktasının kaynak kutunun sol kenarına uzaklığı.
const double sourceInset = AppSpacing.md + AppSizes.analysisSourceWidth / 2;

/// Kütüphane ekranını saran uçuş kapsamı: hedef anahtarlarını yaşatır ve
/// uçuş katmanını içeriğin üstüne çizer.
class AnalysisFlightScope extends StatefulWidget {
  const AnalysisFlightScope({super.key, required this.child});

  final Widget child;

  /// En yakın kapsamın uçuş API'si; kapsam yoksa null. Kapsam hiç
  /// değişmediği için bağımlılık kurulmaz.
  static AnalysisFlights? of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_FlightScopeData>()?.flights;

  @override
  State<AnalysisFlightScope> createState() => _AnalysisFlightScopeState();
}

class _AnalysisFlightScopeState extends State<AnalysisFlightScope>
    with SingleTickerProviderStateMixin
    implements AnalysisFlights {
  @override
  final GlobalKey sourceKey = GlobalKey(debugLabel: 'flightSource');

  final Map<ScreenshotCategory, GlobalKey> _targets = {};
  final GlobalKey _layerKey = GlobalKey(debugLabel: 'flightLayer');
  final List<FlightRequest> _waiting = [];
  final List<_Flight> _flights = [];
  final ValueNotifier<bool> _busy = ValueNotifier(false);

  /// Her karede uçuş katmanını yeniden çizdiren sinyal (kapsamın geri kalanı
  /// yeniden kurulmaz).
  final ValueNotifier<int> _frame = ValueNotifier(0);
  final math.Random _random = math.Random();
  late final Ticker _ticker = createTicker(_onTick);

  Duration _elapsed = Duration.zero;
  Duration? _lastSpawn;
  int _landedCount = 0;
  bool _reduceMotion = false;

  @override
  ValueListenable<bool> get busy => _busy;

  @override
  GlobalKey targetKeyFor(ScreenshotCategory category) => _targets.putIfAbsent(
    category,
    () => GlobalKey(debugLabel: 'flightTarget.${category.name}'),
  );

  @override
  void enqueue(Iterable<FlightRequest> items) {
    if (_reduceMotion) return;
    _waiting.addAll(items);
    if (_waiting.isEmpty) return;
    _busy.value = true;
    if (!_ticker.isActive) {
      _lastSpawn = null;
      _ticker.start();
    }
  }

  @override
  void clear() {
    _waiting.clear();
    _flights.clear();
    _stop();
    _frame.value++;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _busy.dispose();
    _frame.dispose();
    super.dispose();
  }

  void _stop() {
    if (_ticker.isActive) _ticker.stop();
    _busy.value = false;
  }

  void _onTick(Duration elapsed) {
    _elapsed = elapsed;
    _maybeSpawn();
    _advance();
    _frame.value++;
    if (_flights.isEmpty && _waiting.isEmpty) _stop();
  }

  void _maybeSpawn() {
    if (_waiting.isEmpty || _flights.length >= AppFlight.maxConcurrent) return;
    final Duration? last = _lastSpawn;
    if (last != null && _elapsed - last < AppFlight.spawnCadence) return;
    final Offset? source = _sourcePoint();
    if (source == null) {
      // Modül görünmüyor (kaydırılıp gitti): sıradakiler uçmadan iner,
      // tur özeti beklemede kalmaz.
      _waiting.clear();
      return;
    }
    final FlightRequest request = _waiting.removeAt(0);
    final double floor = _floorY();
    final Offset target =
        _centerOf(targetKeyFor(request.category)) ?? Offset(source.dx, floor);
    final Offset end = Offset(target.dx, math.min(target.dy, floor));
    final double lateral =
        (_random.nextDouble() * 2 - 1) * AppFlight.lateralJitter;
    _flights.add(
      _Flight(
        asset: request.asset,
        start: source,
        end: end,
        born: _elapsed,
        x: SpringSimulation(AppSprings.flight, source.dx, end.dx, lateral),
        y: SpringSimulation(
          AppSprings.flight,
          source.dy,
          end.dy,
          -AppFlight.launchSpeed,
        ),
      ),
    );
    _lastSpawn = _elapsed;
  }

  void _advance() {
    _flights.removeWhere((flight) {
      final double t =
          (_elapsed - flight.born).inMicroseconds /
          Duration.microsecondsPerSecond;
      flight.update(t);
      final bool landed =
          flight.progress >= AppFlight.landedAt ||
          _elapsed - flight.born >= AppFlight.maxDuration;
      if (landed) _onLanded();
      return landed;
    });
  }

  void _onLanded() {
    _landedCount++;
    // Haptik kartın karoya indiği karede; her inişte değil, aralıklı.
    if (_landedCount % Haptics.progressTickEvery == 0) Haptics.tick();
  }

  RenderBox? _box(GlobalKey key) {
    final RenderObject? object = key.currentContext?.findRenderObject();
    if (object is! RenderBox || !object.attached || !object.hasSize) {
      return null;
    }
    return object;
  }

  /// [key]'li kutunun merkezi, katman koordinatında; ölçülemiyorsa null.
  Offset? _centerOf(GlobalKey key) {
    final RenderBox? box = _box(key);
    if (box == null) return null;
    return _toLayer(box.localToGlobal(box.size.center(Offset.zero)));
  }

  Offset? _sourcePoint() {
    final RenderBox? box = _box(sourceKey);
    if (box == null) return null;
    return _toLayer(
      box.localToGlobal(Offset(sourceInset, box.size.height / 2)),
    );
  }

  Offset? _toLayer(Offset global) => _box(_layerKey)?.globalToLocal(global);

  /// Kartın inebileceği en alt nokta: sekme çubuğunun üstü. Kabuk
  /// `extendBody` kullandığı için gövdenin alt boşluğu çubuğu zaten içerir.
  double _floorY() {
    final double height = _box(_layerKey)?.size.height ?? 0;
    return height -
        MediaQuery.paddingOf(context).bottom -
        AppFlight.cardSize.height / 2;
  }

  @override
  Widget build(BuildContext context) {
    _reduceMotion = context.reduceMotion;
    return _FlightScopeData(
      flights: this,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: ValueListenableBuilder<int>(
                key: _layerKey,
                valueListenable: _frame,
                builder: (context, _, _) => Stack(
                  children: [
                    for (final _Flight flight in _flights)
                      _FlightCard(key: ObjectKey(flight), flight: flight),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlightScopeData extends InheritedWidget {
  const _FlightScopeData({required this.flights, required super.child});

  final AnalysisFlights flights;

  @override
  bool updateShouldNotify(_FlightScopeData oldWidget) => false;
}

/// Tek uçuşun durumu: eksen yayları ve o anki konum/ilerleme.
class _Flight {
  _Flight({
    required this.asset,
    required this.start,
    required this.end,
    required this.born,
    required this.x,
    required this.y,
  }) : position = start;

  final AssetEntity? asset;
  final Offset start;
  final Offset end;
  final Duration born;
  final SpringSimulation x;
  final SpringSimulation y;

  Offset position;

  /// Hedefe kalan yolun tamamlanan oranı (atış başında negatife inebilir).
  double progress = 0;

  void update(double seconds) {
    position = Offset(x.x(seconds), y.x(seconds));
    final double total = (end - start).distance;
    progress = total < 1 ? 1 : 1 - (end - position).distance / total;
  }
}

/// Uçan küçük resim: hedefe yaklaştıkça küçülür, son payda solarak karoya
/// karışır (iniş patlaması yok).
class _FlightCard extends StatelessWidget {
  const _FlightCard({super.key, required this.flight});

  final _Flight flight;

  @override
  Widget build(BuildContext context) {
    final Color fallback = Theme.of(context).colorScheme.surfaceContainerHigh;
    final double done = flight.progress.clamp(0.0, 1.0);
    final double opacity = ((1 - flight.progress) / AppFlight.fadeFraction)
        .clamp(0.0, 1.0);
    final Size size = AppFlight.cardSize;
    final AssetEntity? asset = flight.asset;
    return Positioned(
      left: flight.position.dx - size.width / 2,
      top: flight.position.dy - size.height / 2,
      width: size.width,
      height: size.height,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: lerpDouble(1, AppFlight.landingScale, done),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: asset == null
                ? ColoredBox(color: fallback)
                : AssetEntityImage(
                    asset,
                    isOriginal: false,
                    thumbnailSize: const ThumbnailSize.square(
                      AppSizes.coverThumbnailPx,
                    ),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        ColoredBox(color: fallback),
                  ),
          ),
        ),
      ),
    );
  }
}

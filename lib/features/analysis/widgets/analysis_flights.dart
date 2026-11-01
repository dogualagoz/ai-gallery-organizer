// Analiz uçuşları: analiz edilen ekran görüntülerinin küçük resimleri durum
// modülünden kalkıp ilgili kategori karosuna süzülür. Yol, X ve Y eksenlerinde
// ayrı kritik sönümlü yaylardan ve kalkıştaki yukarı atış hızından doğar
// (sabit süreli eğri yok). Karo her karede yeniden ölçülür; yeri değişirse
// yay o anki konum ve hızından yeni yerine döner. Katman Kütüphane'nin
// üstünde, sekme çubuğunun altında çizilir; Reduce Motion'da uçuş olmaz.
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

  /// Sıradaki (henüz kalkmamış) uçuş; sıra boşsa null. Kaynak küçük resim
  /// bunu gösterir, kalkınca bir sonrakine geçer.
  ValueListenable<FlightRequest?> get nextFlight;
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
  final ValueNotifier<FlightRequest?> _next = ValueNotifier(null);

  /// Her karede uçuş katmanını yeniden çizdiren sinyal (kapsamın geri kalanı
  /// yeniden kurulmaz).
  final ValueNotifier<int> _frame = ValueNotifier(0);
  final math.Random _random = math.Random();
  late final Ticker _ticker = createTicker(_onTick);

  Duration _elapsed = Duration.zero;
  Duration? _lastSpawn;

  /// Sıranın başı hedef karosunu beklemeye başladığı an (bkz.
  /// [_shouldHoldForTarget]); beklemiyorsa null.
  Duration? _headWaitStart;

  /// Bekleme süresinde karosu gelmeyen kategoriler: bu akıştaki sonraki
  /// öğeleri yeniden beklemeden kalkar (karo gelirse yolda hedeflenir).
  final Set<ScreenshotCategory> _unreachable = {};
  int _landedCount = 0;
  bool _reduceMotion = false;

  @override
  ValueListenable<bool> get busy => _busy;

  @override
  ValueListenable<FlightRequest?> get nextFlight => _next;

  void _syncNext() => _next.value = _waiting.firstOrNull;

  @override
  GlobalKey targetKeyFor(ScreenshotCategory category) => _targets.putIfAbsent(
    category,
    () => GlobalKey(debugLabel: 'flightTarget.${category.name}'),
  );

  @override
  void enqueue(Iterable<FlightRequest> items) {
    if (_reduceMotion) return;
    _waiting.addAll(items);
    _syncNext();
    if (_waiting.isEmpty) return;
    _busy.value = true;
    if (!_ticker.isActive) {
      _lastSpawn = null;
      _headWaitStart = null;
      _unreachable.clear();
      _ticker.start();
    }
  }

  @override
  void clear() {
    _waiting.clear();
    _headWaitStart = null;
    _unreachable.clear();
    _syncNext();
    _flights.clear();
    _stop();
    _frame.value++;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _busy.dispose();
    _next.dispose();
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
      _headWaitStart = null;
      _syncNext();
      return;
    }
    final FlightRequest request = _waiting.first;
    final Offset? landing = _landingFor(request.category);
    if (landing == null && _shouldHoldForTarget(request.category)) return;
    _waiting.removeAt(0);
    _headWaitStart = null;
    _syncNext();
    final double lateral =
        (_random.nextDouble() * 2 - 1) * AppFlight.lateralJitter;
    _flights.add(
      _Flight(
        asset: request.asset,
        category: request.category,
        start: source,
        end: landing ?? Offset(source.dx, _floorY()),
        born: _elapsed,
        velocity: Offset(lateral, -AppFlight.launchSpeed),
      ),
    );
    _lastSpawn = _elapsed;
  }

  /// Kategorinin ilk öğesinde karo henüz yok (galeri yenilenince kurulur):
  /// sıranın başı kalkmadan kısa süre bekler ki boşluğa uçmasın. İlk
  /// çağrı bekleme sayacını başlatır; süre dolarsa (karo kaydırılıp gitti)
  /// kategori ulaşılamaz sayılır ve kart sekme çubuğunun üstüne iner.
  bool _shouldHoldForTarget(ScreenshotCategory category) {
    if (_unreachable.contains(category)) return false;
    final Duration since = _headWaitStart ??= _elapsed;
    if (_elapsed - since < AppFlight.targetGrace) return true;
    _unreachable.add(category);
    return false;
  }

  void _advance() {
    _flights.removeWhere((flight) {
      // Araya yeni kategori girdi, ızgara aktı ya da sayfa kaydı: kart
      // karonun o anki yerine yönelir. Ölçüm önceki karenin yerleşimidir
      // (ticker build'den önce çalışır); bir karelik gecikme görünmez.
      // Karo ağaçtan çıktıysa son bilinen hedefe devam edilir.
      final Offset? landing = _landingFor(flight.category);
      if (landing != null) flight.retarget(landing, _elapsed);
      flight.update(_elapsed);
      // Süre sınırı kalkıştan sayılır: sayfa sürekli kaysa da kart takılmaz.
      final bool landed =
          flight.arrived || _elapsed - flight.born >= AppFlight.maxDuration;
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

  /// Kategori karosunun iniş noktası (sekme çubuğunun üstüyle sınırlı);
  /// karo kurulmamışsa null.
  Offset? _landingFor(ScreenshotCategory category) {
    final Offset? center = _centerOf(targetKeyFor(category));
    if (center == null) return null;
    return Offset(center.dx, math.min(center.dy, _floorY()));
  }

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
    required this.category,
    required this.start,
    required Offset end,
    required this.born,
    required Offset velocity,
  }) : position = start,
       _end = end,
       _legStart = born,
       _legDistance = (end - start).distance,
       _x = SpringSimulation(AppSprings.flight, start.dx, end.dx, velocity.dx),
       _y = SpringSimulation(AppSprings.flight, start.dy, end.dy, velocity.dy);

  final AssetEntity? asset;
  final ScreenshotCategory category;
  final Offset start;
  final Duration born;

  Offset _end;

  /// Geçerli yayların başladığı an; her yeniden hedeflemede ilerler.
  Duration _legStart;
  SpringSimulation _x;
  SpringSimulation _y;

  /// Geçerli bacağın başındaki uzaklık ve o ana kadarki görsel ilerleme:
  /// kalan solma payı yeni bacağa yayılır.
  double _legDistance;
  double _legBase = 0;

  /// Geçerli bacağın tamamlanan oranı (atış başında negatife inebilir).
  double _leg = 0;

  Offset position;

  /// Küçülme/solma için yolun tamamlanan oranı (0-1). Yalnız artar: karo
  /// kayınca solmaya başlamış kart yeniden belirmez.
  double progress = 0;

  /// Kart geçerli hedefine vardı (yay kuyruğu beklenmez).
  bool get arrived => _leg >= AppFlight.landedAt;

  static double _seconds(Duration duration) =>
      duration.inMicroseconds / Duration.microsecondsPerSecond;

  /// Hedef kaydıysa yayları [now] anındaki konum ve hızdan yeni hedefe
  /// kurar: yol kırılmadan döner, kart sıçramaz.
  void retarget(Offset end, Duration now) {
    if ((end - _end).distance <= AppFlight.retargetTolerance) return;
    final double t = _seconds(now - _legStart);
    final Offset from = Offset(_x.x(t), _y.x(t));
    _x = SpringSimulation(AppSprings.flight, from.dx, end.dx, _x.dx(t));
    _y = SpringSimulation(AppSprings.flight, from.dy, end.dy, _y.dx(t));
    _end = end;
    _legStart = now;
    _legDistance = (end - from).distance;
    _legBase = progress;
  }

  void update(Duration now) {
    final double t = _seconds(now - _legStart);
    position = Offset(_x.x(t), _y.x(t));
    _leg = _legDistance < 1 ? 1 : 1 - (_end - position).distance / _legDistance;
    progress = math.max(progress, _legBase + (1 - _legBase) * _leg);
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

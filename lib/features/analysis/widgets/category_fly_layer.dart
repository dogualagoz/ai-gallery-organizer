// Analiz sırasında tamamlanan screenshot'ların gölgelerini ilerleme
// kartından ana sayfadaki kategori kartlarına uçuran overlay katmanı.
import 'dart:async';
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
import 'analysis_particle_field.dart';

/// Aynı anda uçabilen gölge sayısı; fazlası kuyrukta sabit kadansla bekler.
const int _maxConcurrentGhosts = 8;

/// Gölge kartın ekran ölçüleri.
const Size _ghostSize = Size(40, 70);

/// Kategori karosuna inişte beliren pulse'ın en büyük yarıçapı.
const double _landingPulseRadius = 34;

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
  final List<_LandingPulse> _pulses = [];
  final List<AnalyzedItem> _spawnQueue = [];
  final Random _random = Random();

  /// Kuyruğu sabit kadansla boşaltan zamanlayıcı — yalnız running iken çalışır.
  /// Ticker tabanlı olmadığı için sekme değişince TickerMode gibi otomatik
  /// durmaz; zararsızdır çünkü eşzamanlılık üst sınırı zaten sınırlar.
  Timer? _spawnTimer;

  /// Katman kurulduğunda süren turun eski sonuçları tekrar oynatılmaz.
  late int _lastSeenDone = ref.read(analysisQueueProvider).done;

  GlobalKey _keyFor(ScreenshotCategory category) =>
      _categoryKeys.putIfAbsent(category, GlobalKey.new);

  @override
  void dispose() {
    _spawnTimer?.cancel();
    for (final _Ghost ghost in _ghosts) {
      ghost.controller.dispose();
    }
    for (final _LandingPulse pulse in _pulses) {
      pulse.controller.dispose();
    }
    super.dispose();
  }

  /// Kuyruk güncellemelerinden yeni tamamlananları çıkarır, gölge kuyruğuna
  /// ekler ve her [Haptics.progressTickEvery] tamamlanmada tik verir.
  void _onQueueChanged(AnalysisQueueState? previous, AnalysisQueueState next) {
    if (next.status == AnalysisQueueStatus.running) {
      _spawnTimer ??= Timer.periodic(AppDurations.fast, (_) => _drainSpawnQueue());
    } else {
      _spawnTimer?.cancel();
      _spawnTimer = null;
    }

    if (next.done < _lastSeenDone) _lastSeenDone = next.done; // yeni tur
    final int newCount = next.done - _lastSeenDone;
    if (newCount <= 0) return;
    _lastSeenDone = next.done;

    // Üst sınır AnalysisQueueState.maxRecentItems ile doğal olarak sınırlı;
    // hızlı burst'lerde de her sonuç kuyruğa girer, sabit kadansla akar.
    final int take = min(newCount, next.recent.length);
    _spawnQueue.addAll(
      next.recent.sublist(next.recent.length - take),
    );
    _drainSpawnQueue();

    final int prevDone = next.done - newCount;
    if (next.done ~/ Haptics.progressTickEvery >
        prevDone ~/ Haptics.progressTickEvery) {
      Haptics.tick();
    }
  }

  /// Bir slot boşsa kuyruktan tek bir gölge çıkarır — patlama yerine sabit
  /// kadanslı, sürekli bir akış hissi versin diye tek tek beslenir.
  void _drainSpawnQueue() {
    if (_ghosts.length >= _maxConcurrentGhosts || _spawnQueue.isEmpty) return;
    _spawnGhost(_spawnQueue.removeAt(0));
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

  /// Katman (stack) ölçüleri; henüz yerleşmemişse null.
  Size? _stackSize() {
    final RenderBox? stack =
        _stackKey.currentContext?.findRenderObject() as RenderBox?;
    return stack?.size;
  }

  /// Uçuşun başlangıcı: koşan banner kartının merkezi. Kart (switcher takası
  /// vb.) çözülemezse üst-orta sabit noktaya düş — böylece gölge hiç düşmez.
  Offset? _sourceCenter(Size stack) {
    return _centerOf(_sourceKey) ?? Offset(stack.width * 0.5, stack.height * 0.14);
  }

  /// Uçuşun hedefi: kategori karosunun merkezi. Karo ekran dışı/henüz yoksa
  /// board bölgesinin görünür alt kenarına düş — kategorinin sabit bir
  /// sütununa (index'ten türetilen sol/sağ) hizalanmış bir nokta.
  Offset _targetCenter(AnalyzedItem item, Size stack) {
    final Offset? real = _centerOf(_keyFor(item.category));
    if (real != null) return real;
    final bool leftColumn = item.category.index.isEven;
    return Offset(
      stack.width * (leftColumn ? 0.28 : 0.72),
      stack.height * 0.82,
    );
  }

  void _spawnGhost(AnalyzedItem item) {
    final Size? stack = _stackSize();
    if (stack == null) return;
    final Offset? source = _sourceCenter(stack);
    if (source == null) return;
    final Offset target = _targetCenter(item, stack);

    // Aynı anda uçanlar üst üste binmesin diye küçük yatay saçılma.
    final Offset start = source + Offset(_random.nextDouble() * 80 - 40, 0);
    // Aşağı bükülen kavis için kontrol noktası: orta nokta + yanal drift +
    // aşağı sarkma (yerçekimi hissi).
    final Offset control = Offset.lerp(start, target, 0.5)! +
        Offset(_random.nextDouble() * 80 - 40, 24 + _random.nextDouble() * 40);

    final AnimationController controller = AnimationController(
      vsync: this,
      duration: AppDurations.slow,
    );
    final _Ghost ghost = _Ghost(
      asset: ref.read(screenshotRepositoryProvider).assetFor(item.assetId),
      start: start,
      control: control,
      end: target,
      spin: _random.nextDouble() * 0.3 - 0.15, // ±0.15 rad hafif dönme
      controller: controller,
    );
    controller.forward().whenComplete(() {
      if (!mounted) return;
      setState(() => _ghosts.remove(ghost));
      controller.dispose();
      _spawnLandingPulse(target);
      _drainSpawnQueue();
    });
    setState(() => _ghosts.add(ghost));
  }

  /// Gölge hedefe ulaştığında karoda kısa süreli genişleyip sönen bir halka.
  void _spawnLandingPulse(Offset target) {
    final AnimationController controller = AnimationController(
      vsync: this,
      duration: AppDurations.medium,
    );
    final _LandingPulse pulse = _LandingPulse(
      center: target,
      controller: controller,
    );
    controller.forward().whenComplete(() {
      if (!mounted) return;
      setState(() => _pulses.remove(pulse));
      controller.dispose();
    });
    setState(() => _pulses.add(pulse));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(analysisQueueProvider, _onQueueChanged);
    final bool running =
        ref.watch(analysisQueueProvider.select((s) => s.isRunning));
    return CategoryFlyScope(
      sourceKey: _sourceKey,
      keyFor: _keyFor,
      child: Stack(
        key: _stackKey,
        children: [
          widget.child,
          // İçeriğin üstünde, ghost/pulse'ların altında: yükselen mor zerreler.
          Positioned.fill(
            child: IgnorePointer(child: AnalysisParticleField(active: running)),
          ),
          for (final _LandingPulse pulse in _pulses)
            IgnorePointer(child: _LandingPulseCard(pulse: pulse)),
          for (final _Ghost ghost in _ghosts)
            IgnorePointer(child: _GhostCard(ghost: ghost)),
        ],
      ),
    );
  }
}

/// Uçuş halindeki tek gölgenin verisi. Yol, kavis için [control] üzerinden
/// geçen quadratic bezier; [spin] uçuş boyunca uygulanan küçük dönme açısı.
class _Ghost {
  _Ghost({
    required this.asset,
    required this.start,
    required this.control,
    required this.end,
    required this.spin,
    required this.controller,
  });

  final AssetEntity? asset;
  final Offset start;
  final Offset control;
  final Offset end;
  final double spin;
  final AnimationController controller;
}

/// Bir gölgenin kategori karosuna inişini işaretleyen kısa ömürlü halka.
class _LandingPulse {
  _LandingPulse({required this.center, required this.controller});

  final Offset center;
  final AnimationController controller;
}

/// İnişte genişleyip sönen halka görseli.
class _LandingPulseCard extends StatelessWidget {
  const _LandingPulseCard({required this.pulse});

  final _LandingPulse pulse;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: pulse.controller,
      builder: (context, child) {
        final double t = Curves.easeOut.transform(pulse.controller.value);
        final double radius = _landingPulseRadius * t;
        return Positioned(
          left: pulse.center.dx - radius,
          top: pulse.center.dy - radius,
          child: Opacity(
            opacity: (1 - t).clamp(0, 1),
            child: Container(
              width: radius * 2,
              height: radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: 0.35),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Aşağı bükülen bezier yolda hızlanarak süzülen, hafifçe dönerek küçülüp
/// hedefte sönen gölge kartı — doğal bir "düşüş" hissi.
class _GhostCard extends StatelessWidget {
  const _GhostCard({required this.ghost});

  final _Ghost ghost;

  /// P0→C→P1 üzerinden geçen quadratic bezier noktası.
  Offset _bezier(double t) {
    final double u = 1 - t;
    return ghost.start * (u * u) +
        ghost.control * (2 * u * t) +
        ghost.end * (t * t);
  }

  @override
  Widget build(BuildContext context) {
    final Color fallback = Theme.of(context).colorScheme.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: ghost.controller,
      builder: (context, child) {
        // Hızlanan düşüş.
        final double t = Curves.easeInCubic.transform(ghost.controller.value);
        final Offset pos = _bezier(t);
        final double opacity = t < 0.75 ? 0.9 : 0.9 * (1 - (t - 0.75) / 0.25);
        return Positioned(
          left: pos.dx - _ghostSize.width / 2,
          top: pos.dy - _ghostSize.height / 2,
          child: Opacity(
            opacity: opacity.clamp(0, 1),
            child: Transform.rotate(
              angle: ghost.spin * t,
              child: Transform.scale(scale: 0.95 - 0.45 * t, child: child),
            ),
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
                      ColoredBox(color: fallback),
                )
              : ColoredBox(color: fallback),
        ),
      ),
    );
  }
}

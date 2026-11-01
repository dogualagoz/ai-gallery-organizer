// Milestone kutlama sahnesi: sheet yerleşince yayla beliren onay rozeti,
// rozetle birlikte açılan ve hafifçe süzülen mini kartlar.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/motion_constants.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/utils/motion_physics.dart';

/// Haftalık kota tamamlandığında gösterilen el yapımı kutlama sahnesi.
///
/// Giriş, rotanın açılış animasyonu bitince başlar (sheet hâlâ kayarken
/// oynayan bir animasyon gözden kaçar). Haptik rozetin tepe anında, yani
/// görsel "vuruşla" aynı karede gelir. Reduce Motion'da sahne son haliyle
/// durur, haptik sheet yerleşince bir kez verilir.
class MilestoneCelebration extends StatefulWidget {
  const MilestoneCelebration({super.key});

  @override
  State<MilestoneCelebration> createState() => _MilestoneCelebrationState();
}

class _MilestoneCelebrationState extends State<MilestoneCelebration>
    with TickerProviderStateMixin {
  /// Kart poz varyasyonları sabit tohumla üretilir: her açılışta aynı sahne.
  static const int _sceneSeed = 7;

  /// Tam tur (radyan).
  static const double _fullTurn = 2 * pi;

  /// Rozet ölçeği; sınırsız çünkü yay hedefi (1) hafifçe aşar.
  late final AnimationController _badge = AnimationController.unbounded(
    vsync: this,
  )..addListener(_watchPeak);

  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: AppDurations.scene * 2,
  );

  late final List<double> _phases = () {
    final Random random = Random(_sceneSeed);
    return List.generate(
      AppCelebration.cardCount,
      (_) => random.nextDouble() * _fullTurn,
    );
  }();

  Animation<double>? _routeAnimation;
  bool _started = false;
  bool _peaked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      _syncDrift();
      return;
    }
    _awaitRoute();
  }

  /// Giriş, rotanın açılış geçişi bitince başlar.
  void _awaitRoute() {
    if (_started || !mounted) return;
    final ModalRoute<Object?>? modal = ModalRoute.of(context);
    // Navigator yeni rotayı ilk karede Hero ölçümü için offstage kurar; o
    // karede animasyon "tamamlandı" görünür. Offstage değişimi bağımlılık
    // bildirimi üretmediği için bir kare sonra yeniden bakılır.
    if (modal != null && modal.offstage) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _awaitRoute());
      return;
    }
    final Animation<double>? route = modal?.animation;
    if (route == null || route.isCompleted) {
      _start();
      return;
    }
    if (!identical(route, _routeAnimation)) {
      _routeAnimation?.removeStatusListener(_onRouteStatus);
      _routeAnimation = route..addStatusListener(_onRouteStatus);
    }
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    _badge.dispose();
    _drift.dispose();
    super.dispose();
  }

  void _onRouteStatus(AnimationStatus status) {
    if (status.isCompleted) _start();
  }

  void _start() {
    if (_started || !mounted) return;
    _started = true;
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    if (context.reduceMotion) {
      _badge.value = 1;
      _celebrate();
      return;
    }
    _badge.animateWith(SpringSimulation(AppSprings.celebrate, 0, 1, 0));
    _syncDrift();
  }

  /// Süzülme yalnız hareket açıkken ve giriş başladıktan sonra döner.
  void _syncDrift() {
    if (context.reduceMotion) {
      _drift.stop();
    } else if (!_drift.isAnimating) {
      _drift.repeat(reverse: true);
    }
  }

  /// Tepe: yay hedefi aşıp geri dönmeye başladığı kare (hız işaret
  /// değiştirir). Yay taşmadan durursa da bitişte bir kez verilir.
  void _watchPeak() {
    if (_peaked) return;
    final bool turned = _badge.value >= 1 && _badge.velocity <= 0;
    if (turned || !_badge.isAnimating) _celebrate();
  }

  void _celebrate() {
    if (_peaked) return;
    _peaked = true;
    Haptics.milestone();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          height: AppCelebration.sceneHeight,
          child: AnimatedBuilder(
            animation: Listenable.merge([_badge, _drift]),
            builder: (context, _) => Stack(
              alignment: Alignment.center,
              children: [
                for (int i = 0; i < AppCelebration.cardCount; i++)
                  _OrbitCard(
                    angle: _fullTurn * i / AppCelebration.cardCount,
                    wobble: sin(_drift.value * _fullTurn + _phases[i]),
                    spread: _badge.value,
                  ),
                _Badge(scale: max(0, _badge.value)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rozet çevresinde yörüngede süzülen tek mini kart. Rozetin yayıyla
/// birlikte dışa açılır (taşmayı da paylaşır).
class _OrbitCard extends StatelessWidget {
  const _OrbitCard({
    required this.angle,
    required this.wobble,
    required this.spread,
  });

  final double angle;

  /// -1..1 salınım konumu.
  final double wobble;

  /// 0 = merkezde, 1 = yörüngede.
  final double spread;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double radius =
        (AppCelebration.orbitRadius + wobble * AppCelebration.wobble) * spread;

    return Transform.translate(
      offset: Offset(cos(angle) * radius, sin(angle) * radius),
      child: Transform.rotate(
        angle: wobble * AppCelebration.wobbleTilt,
        child: Opacity(
          opacity: spread.clamp(0.0, 1.0),
          child: Container(
            width: AppCelebration.cardSize.width,
            height: AppCelebration.cardSize.height,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: scheme.outlineVariant),
            ),
          ),
        ),
      ),
    );
  }
}

/// Merkezdeki onay rozeti.
class _Badge extends StatelessWidget {
  const _Badge({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: AppCelebration.badgeSize,
        height: AppCelebration.badgeSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.primaryContainer,
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: AppCelebration.glowAlpha),
              blurRadius: AppCelebration.glowBlur,
              spreadRadius: AppCelebration.glowSpread,
            ),
          ],
        ),
        child: Icon(
          AppIcons.check,
          size: AppCelebration.badgeGlyph,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

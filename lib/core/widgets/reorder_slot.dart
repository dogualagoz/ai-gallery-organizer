// Sıralanabilir ızgaranın hücre parçaları: yayla yerine giden yuva ve
// kaldırılan karonun büyüme + gölge süslemesi.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../constants/motion_constants.dart';
import '../constants/ui_constants.dart';
import '../utils/motion_physics.dart';

/// Konumuna yayla giden hücre. [follow] verilirken parmağı birebir izler
/// (değer her değiştiğinde, ızgara yeniden kurulmadan); bırakılınca
/// [releaseVelocity] ile momentum yayına geçer. Yer değişimi transform ile
/// yapılır (her karede yeniden yerleşim yok).
class ReorderSpringSlot extends StatefulWidget {
  const ReorderSpringSlot({
    super.key,
    required this.target,
    required this.releaseVelocity,
    required this.size,
    required this.child,
    this.follow,
  });

  /// Yayın hedeflediği sol üst köşe (ızgara koordinatı).
  final Offset target;

  /// Sürüklenirken karonun anlık köşesi; null ise karo [target]'a yaylanır.
  final ValueListenable<Offset>? follow;

  /// Bırakılan karonun devraldığı parmak hızı (px/sn).
  final Offset releaseVelocity;
  final Size size;
  final Widget child;

  @override
  State<ReorderSpringSlot> createState() => _ReorderSpringSlotState();
}

class _ReorderSpringSlotState extends State<ReorderSpringSlot>
    with TickerProviderStateMixin {
  late final AnimationController _x = AnimationController.unbounded(
    vsync: this,
    value: widget.target.dx,
  );
  late final AnimationController _y = AnimationController.unbounded(
    vsync: this,
    value: widget.target.dy,
  );
  late final Listenable _position = Listenable.merge([_x, _y]);

  @override
  void initState() {
    super.initState();
    widget.follow?.addListener(_jumpToFollow);
  }

  @override
  void didUpdateWidget(ReorderSpringSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.follow != widget.follow) {
      oldWidget.follow?.removeListener(_jumpToFollow);
      widget.follow?.addListener(_jumpToFollow);
    }
    if (widget.follow != null) {
      _jumpToFollow();
      return;
    }
    final bool released = oldWidget.follow != null;
    if (!released && oldWidget.target == widget.target) return;
    // Bırakılan karo parmağın hızını devralır (hafif sekme yalnız burada);
    // akan komşular o anki konum ve hızlarından sekmesiz yeniden hedeflenir.
    final SpringDescription spring = released
        ? AppSprings.momentum
        : AppSprings.standard;
    final Offset velocity = released
        ? widget.releaseVelocity
        : Offset(_x.velocity, _y.velocity);
    _springTo(_x, widget.target.dx, velocity.dx, spring);
    _springTo(_y, widget.target.dy, velocity.dy, spring);
  }

  void _jumpToFollow() {
    final Offset? follow = widget.follow?.value;
    if (follow == null) return;
    _x.value = follow.dx;
    _y.value = follow.dy;
  }

  void _springTo(
    AnimationController axis,
    double target,
    double velocity,
    SpringDescription spring,
  ) {
    if (context.reduceMotion) {
      axis.value = target;
      return;
    }
    axis.animateWith(SpringSimulation(spring, axis.value, target, velocity));
  }

  @override
  void dispose() {
    widget.follow?.removeListener(_jumpToFollow);
    _x.dispose();
    _y.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      top: 0,
      width: widget.size.width,
      height: widget.size.height,
      child: AnimatedBuilder(
        animation: _position,
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: Offset(_x.value, _y.value),
          child: child,
        ),
      ),
    );
  }
}

/// Kaldırılan karonun büyümesi ve altına düşen gölgesi; [lift] 0 = yerinde,
/// 1 = parmağın altında yükselmiş.
class ReorderLiftDecoration extends AnimatedWidget {
  const ReorderLiftDecoration({
    super.key,
    required Animation<double> lift,
    required this.child,
  }) : super(listenable: lift);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double t = (listenable as Animation<double>).value;
    final double shadow = t.clamp(0.0, 1.0);
    return Transform.scale(
      scale: 1 + (AppLift.scale - 1) * t,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: shadow <= 0
              ? null
              : [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow
                        .withValues(alpha: AppLift.shadowAlpha * shadow),
                    blurRadius: AppLift.shadowBlur,
                    offset: Offset(0, AppLift.shadowOffsetY * shadow),
                  ),
                ],
        ),
        child: child,
      ),
    );
  }
}

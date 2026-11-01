// Düzenleme modunda yeniden sıralanabilen sabit sütunlu ızgara. Karolar
// yerlerine yayla gider: basılı tutulan karo kalkar ve parmağı 1:1 izler,
// komşular yeni yerlerine akar, bırakınca karo parmağın hızını devralarak
// yerine oturur. Sıralama verisi dışarıda: [onReorder] eski→yeni index verir.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../constants/motion_constants.dart';
import '../constants/ui_constants.dart';
import '../services/haptic_service.dart';
import '../utils/motion_physics.dart';
import '../utils/text_scale.dart';
import 'jiggle.dart';

class ReorderableTileGrid extends StatefulWidget {
  const ReorderableTileGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.keyBuilder,
    required this.editing,
    required this.onReorder,
    this.crossAxisCount = 2,
    this.childAspectRatio = AppSizes.boardTileAspect,
    this.spacing = AppSpacing.sm,
    this.trailing,
  });

  final int itemCount;

  /// Karonun görselini üretir (dokunma davranışı çağırana ait).
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// Karo kimliği: sıra değişse de karonun state'i ve yay konumu korunur.
  final Key Function(int index) keyBuilder;

  /// true iken karolar titrer ve basılı tutularak taşınabilir.
  final bool editing;

  /// [from] index'indeki karo [to] konumuna taşındı.
  final void Function(int from, int to) onReorder;

  final int crossAxisCount;
  final double childAspectRatio;
  final double spacing;

  /// Sıralanmayan son hücre (ör. "yeni pano" kartı). null ise yok.
  final Widget? trailing;

  @override
  State<ReorderableTileGrid> createState() => _ReorderableTileGridState();
}

/// Son hücrenin anahtar türü; karo anahtarlarıyla çakışmaz.
class _TrailingSlot {}

class _ReorderableTileGridState extends State<ReorderableTileGrid>
    with SingleTickerProviderStateMixin {
  /// Kaldırma: 0 = yerinde, 1 = parmağın altında yükselmiş.
  late final AnimationController _lift = AnimationController.unbounded(
    vsync: this,
  );

  /// Görüntülenen sıra (veri index'leri). null = veri sırası. Sürüklerken
  /// önizlemedir; bırakınca veri güncellenene dek kullanıcının sırası kalır.
  List<int>? _displayOrder;

  /// Bırakılan sıranın anahtarları; veri bu sıraya gelince temizlenir.
  List<Key>? _pendingKeys;

  /// Veri sırayı makul sürede yakalamazsa (kayıt başarısız) önizleme bırakılır
  /// ve ızgara veri sırasına döner; sürükleme kilitli kalmaz.
  Timer? _pendingTimeout;

  /// Sürüklenen karonun veri index'i ve sol üst köşesi (ızgara koordinatı).
  int? _dragItem;
  Offset _dragOrigin = Offset.zero;

  /// Parmağın, tutulan karonun köşesine uzaklığı (tutulan yer korunur).
  Offset _grab = Offset.zero;

  Offset _releaseVelocity = Offset.zero;

  /// Kalkık görünen (sürüklenen ya da yerine oturan) karo; en üstte çizilir.
  Key? _liftedKey;

  Size _cell = Size.zero;

  /// Geçerli sütun sayısı; [_cell] ile aynı yerleşimde (build) hesaplanır ki
  /// jest sırasında yazı ölçeği değişse de slot hesapları tutarlı kalsın.
  int _columns = 1;

  List<Key> get _keys => [
    for (int i = 0; i < widget.itemCount; i++) widget.keyBuilder(i),
  ];

  List<int> get _order =>
      _displayOrder ?? List<int>.generate(widget.itemCount, (i) => i);

  @override
  void didUpdateWidget(ReorderableTileGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    final List<Key> keys = _keys;
    final List<Key>? pending = _pendingKeys;
    if (pending != null &&
        (!widget.editing ||
            listEquals(keys, pending) ||
            !setEquals(keys.toSet(), pending.toSet()))) {
      // Veri sırayı yakaladı, öğeler değişti ya da düzenleme bitti:
      // önizleme artık geçersiz.
      _clearPending();
    }
    final bool countChanged = oldWidget.itemCount != widget.itemCount;
    if (_dragItem != null && (!widget.editing || countChanged)) _cancelDrag();
  }

  @override
  void dispose() {
    _pendingTimeout?.cancel();
    _lift.dispose();
    super.dispose();
  }

  void _clearPending() {
    _pendingTimeout?.cancel();
    _pendingTimeout = null;
    _pendingKeys = null;
    _displayOrder = null;
  }

  Offset _slotOrigin(int position) {
    final int column = position % _columns;
    final int row = position ~/ _columns;
    return Offset(
      column * (_cell.width + widget.spacing),
      row * (_cell.height + widget.spacing),
    );
  }

  /// [point]'in düştüğü karo konumu (yalnız sıralanabilir hücreler).
  int _slotAt(Offset point) {
    final int column = (point.dx / (_cell.width + widget.spacing))
        .floor()
        .clamp(0, _columns - 1);
    final int row = (point.dy / (_cell.height + widget.spacing)).floor().clamp(
      0,
      (widget.itemCount - 1) ~/ _columns,
    );
    return (row * _columns + column).clamp(0, widget.itemCount - 1);
  }

  Offset _toLocal(Offset global) =>
      (context.findRenderObject()! as RenderBox).globalToLocal(global);

  TickerFuture _springLift(double target) {
    if (context.reduceMotion) {
      _lift.value = target;
      return TickerFuture.complete();
    }
    return _lift.animateWith(
      SpringSimulation(AppSprings.snappy, _lift.value, target, _lift.velocity),
    );
  }

  void _onLiftStart(int item, Offset global) {
    final List<int> order = _order;
    final Offset origin = _slotOrigin(order.indexOf(item));
    setState(() {
      _displayOrder = order;
      _dragItem = item;
      _liftedKey = widget.keyBuilder(item);
      _grab = _toLocal(global) - origin;
      _dragOrigin = origin;
    });
    // Kaldırma haptiği karonun yükselmeye başladığı karede.
    Haptics.tick();
    _springLift(1);
  }

  void _onLiftMove(Offset global) {
    final int? item = _dragItem;
    final List<int>? order = _displayOrder;
    if (item == null || order == null) return;
    final Offset origin = _toLocal(global) - _grab;
    final int target = _slotAt(origin + _cell.center(Offset.zero));
    setState(() {
      _dragOrigin = origin;
      if (order.indexOf(item) == target) return;
      order
        ..remove(item)
        ..insert(target, item);
    });
  }

  void _onLiftEnd(Offset velocity) {
    final int? item = _dragItem;
    final List<int>? order = _displayOrder;
    if (item == null || order == null) return;
    final int to = order.indexOf(item);
    final bool moved = to != item;
    setState(() {
      _releaseVelocity = velocity;
      _dragItem = null;
      if (moved) {
        _pendingKeys = [for (final int i in order) widget.keyBuilder(i)];
        _pendingTimeout = Timer(AppMotion.reorderCommitTimeout, () {
          if (mounted) setState(_clearPending);
        });
      } else {
        _displayOrder = null;
      }
    });
    Haptics.tap();
    _settleLift();
    if (moved) widget.onReorder(item, to);
  }

  void _cancelDrag() {
    _dragItem = null;
    _displayOrder = null;
    _releaseVelocity = Offset.zero;
    _settleLift();
  }

  /// Karo yere indiğinde kalkık görünümü bırakır.
  void _settleLift() {
    _springLift(0).whenCompleteOrCancel(() {
      if (mounted && _dragItem == null) setState(() => _liftedKey = null);
    });
  }

  Map<Type, GestureRecognizerFactory> _liftGestures(int item) {
    // Bekleyen bir sıra varken yeni sürükleme başlamaz: index'ler henüz
    // verinin sırasıyla örtüşmez.
    if (!widget.editing || _pendingKeys != null) return const {};
    return {
      LongPressGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            () => LongPressGestureRecognizer(
              duration: AppMotion.liftDelay,
              debugOwner: this,
            ),
            (recognizer) {
              recognizer.onLongPressStart = (details) =>
                  _onLiftStart(item, details.globalPosition);
              recognizer.onLongPressMoveUpdate = (details) =>
                  _onLiftMove(details.globalPosition);
              recognizer.onLongPressEnd = (details) =>
                  _onLiftEnd(details.velocity.pixelsPerSecond);
              recognizer.onLongPressCancel = () => _onLiftEnd(Offset.zero);
            },
          ),
    };
  }

  Widget _buildTile(BuildContext context, int item, Key key) {
    final bool lifted = key == _liftedKey;
    return RawGestureDetector(
      gestures: _liftGestures(item),
      child: _LiftDecoration(
        lift: lifted ? _lift : kAlwaysDismissedAnimation,
        child: Jiggle(
          enabled: widget.editing && !lifted,
          seed: key.hashCode,
          child: widget.itemBuilder(context, item),
        ),
      ),
    );
  }

  /// Karoları görüntülenen sıradaki yerlerine koyar; kalkık karo en son
  /// (komşularının üstünden geçsin diye), sıralanmayan son hücre ondan önce.
  List<Widget> _buildSlots(BuildContext context) {
    final List<Widget> children = [];
    Widget? lifted;
    final List<int> order = _order;
    for (int position = 0; position < order.length; position++) {
      final int item = order[position];
      final Key key = widget.keyBuilder(item);
      final Widget slot = _SpringSlot(
        key: key,
        target: _slotOrigin(position),
        follow: item == _dragItem ? _dragOrigin : null,
        releaseVelocity: _releaseVelocity,
        size: _cell,
        child: _buildTile(context, item, key),
      );
      if (key == _liftedKey) {
        lifted = slot;
      } else {
        children.add(slot);
      }
    }
    final Widget? trailing = widget.trailing;
    if (trailing != null) {
      children.add(
        _SpringSlot(
          key: const ValueKey<Type>(_TrailingSlot),
          target: _slotOrigin(widget.itemCount),
          releaseVelocity: Offset.zero,
          size: _cell,
          child: trailing,
        ),
      );
    }
    if (lifted != null) children.add(lifted);
    return children;
  }

  @override
  Widget build(BuildContext context) {
    final bool large = context.accessibilityText;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Erişilebilirlik boyutlarında tek sütun: iki sütunlu karoda büyük
        // başlık kapağı ezer (Fotoğraflar albümleri de böyle akar).
        final int columns = _columns = large ? 1 : widget.crossAxisCount;
        final double width = constraints.maxWidth;
        final double cellWidth =
            (width - widget.spacing * (columns - 1)) / columns;
        _cell = Size(cellWidth, cellWidth / widget.childAspectRatio);
        final int total = widget.itemCount + (widget.trailing == null ? 0 : 1);
        final int rows = (total / columns).ceil();
        return SizedBox(
          width: width,
          height: rows == 0
              ? 0
              : rows * _cell.height + (rows - 1) * widget.spacing,
          child: Stack(clipBehavior: Clip.none, children: _buildSlots(context)),
        );
      },
    );
  }
}

/// Konumuna yayla giden hücre. [follow] verilirken parmağı birebir izler;
/// bırakılınca [releaseVelocity] ile momentum yayına geçer. Yer değişimi
/// transform ile yapılır (her karede yeniden yerleşim yok).
class _SpringSlot extends StatefulWidget {
  const _SpringSlot({
    super.key,
    required this.target,
    required this.releaseVelocity,
    required this.size,
    required this.child,
    this.follow,
  });

  final Offset target;
  final Offset? follow;
  final Offset releaseVelocity;
  final Size size;
  final Widget child;

  @override
  State<_SpringSlot> createState() => _SpringSlotState();
}

class _SpringSlotState extends State<_SpringSlot>
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
  void didUpdateWidget(_SpringSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    final Offset? follow = widget.follow;
    if (follow != null) {
      _x.value = follow.dx;
      _y.value = follow.dy;
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

/// Kaldırılan karonun büyümesi ve altına düşen gölgesi.
class _LiftDecoration extends AnimatedWidget {
  const _LiftDecoration({required Animation<double> lift, required this.child})
    : super(listenable: lift);

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

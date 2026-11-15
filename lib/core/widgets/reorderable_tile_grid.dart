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
import 'reorder_grid_layout.dart';
import 'reorder_slot.dart';

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
  /// Köşe her parmak hareketinde değişir; yalnız sürüklenen yuva dinler,
  /// ızgara yalnız önizleme sırası değişince yeniden kurulur.
  int? _dragItem;
  final ValueNotifier<Offset> _dragOrigin = ValueNotifier(Offset.zero);

  /// Parmağın, tutulan karonun köşesine uzaklığı (tutulan yer korunur).
  Offset _grab = Offset.zero;

  Offset _releaseVelocity = Offset.zero;

  /// Kalkık görünen (sürüklenen ya da yerine oturan) karo; en üstte çizilir.
  Key? _liftedKey;

  /// Son yerleşim turunun hücre geometrisi (build'de hesaplanır).
  ReorderGridLayout _layout = ReorderGridLayout.initial;

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
    _dragOrigin.dispose();
    super.dispose();
  }

  void _clearPending() {
    _pendingTimeout?.cancel();
    _pendingTimeout = null;
    _pendingKeys = null;
    _displayOrder = null;
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
    final Offset origin = _layout.originOf(order.indexOf(item));
    _dragOrigin.value = origin;
    setState(() {
      _displayOrder = order;
      _dragItem = item;
      _liftedKey = widget.keyBuilder(item);
      _grab = _toLocal(global) - origin;
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
    _dragOrigin.value = origin;
    final int target = _layout.slotAt(
      origin + _layout.cell.center(Offset.zero),
      itemCount: widget.itemCount,
    );
    if (order.indexOf(item) == target) return;
    setState(() {
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
      child: ReorderLiftDecoration(
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
      final Widget slot = ReorderSpringSlot(
        key: key,
        target: _layout.originOf(position),
        follow: item == _dragItem ? _dragOrigin : null,
        releaseVelocity: _releaseVelocity,
        size: _layout.cell,
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
        ReorderSpringSlot(
          key: const ValueKey<Type>(_TrailingSlot),
          target: _layout.originOf(widget.itemCount),
          releaseVelocity: Offset.zero,
          size: _layout.cell,
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
        final int columns = large ? 1 : widget.crossAxisCount;
        final double width = constraints.maxWidth;
        final double cellWidth =
            (width - widget.spacing * (columns - 1)) / columns;
        final ReorderGridLayout layout = _layout = ReorderGridLayout(
          columns: columns,
          cell: Size(cellWidth, cellWidth / widget.childAspectRatio),
          spacing: widget.spacing,
        );
        final int total = widget.itemCount + (widget.trailing == null ? 0 : 1);
        return SizedBox(
          width: width,
          height: layout.extentFor(total),
          child: Stack(clipBehavior: Clip.none, children: _buildSlots(context)),
        );
      },
    );
  }
}

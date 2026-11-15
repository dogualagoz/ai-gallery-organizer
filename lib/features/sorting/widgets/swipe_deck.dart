// Temizle destesi: üstteki kart parmağı 1:1 izler ve tutulan noktadan döner;
// bırakışta konum + hız projeksiyonuyla karar verir. Giden kart bırakış
// hızıyla uçar ve beklenmez — sıradaki kart anında tutulabilir.
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../../core/constants/motion_constants.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/utils/motion_physics.dart';
import '../swipe_decision.dart';
import 'departing_card.dart';
import 'swipe_card.dart';
import 'swipe_deck_controller.dart';

export 'swipe_deck_controller.dart';

/// Üst kart + arkasındaki sıradaki kart + uçmakta olan kartlar.
class SwipeDeck extends StatefulWidget {
  const SwipeDeck({
    super.key,
    required this.top,
    required this.next,
    required this.controller,
    required this.onSwipe,
    required this.assignIcon,
    required this.assignLabel,
  });

  /// Üstteki (etkileşimli) kart; null ise yalnız uçan kartlar çizilir.
  final SwipeDeckItem? top;
  final SwipeDeckItem? next;
  final SwipeDeckController controller;

  /// Kart gitmeye karar verildiği karede çağrılır; çağıran kartı hemen
  /// desteden çıkarmalıdır (üste sıradaki kart gelir).
  final void Function(String id, SwipeDirection direction) onSwipe;

  final IconData assignIcon;
  final String assignLabel;

  @override
  State<SwipeDeck> createState() => _SwipeDeckState();
}

/// Beklenen geri dönüş: kartın döneceği başlangıç noktası.
class _Return {
  const _Return(this.id, this.from);

  final String id;
  final Offset from;
}

class _SwipeDeckState extends State<SwipeDeck>
    with TickerProviderStateMixin
    implements SwipeDeckCommands {
  /// Üst kartın ofseti; iki eksen ayrı yaylarla sürülür (farklı hızlar
  /// birbirini bozmaz). Sınırsızdır, her hareket o anki değerden başlar.
  late final AnimationController _x = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _y = AnimationController.unbounded(
    vsync: this,
  );

  /// Üste çıkan kartın arkadaki ölçeğinden 1'e büyümesi.
  late final AnimationController _scale = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );

  /// Hareketi Azalt'ta geri gelen kartın belirmesi.
  late final AnimationController _opacity = AnimationController(
    vsync: this,
    value: 1,
  );

  late final Listenable _topMotion = Listenable.merge([
    _x,
    _y,
    _scale,
    _opacity,
  ]);

  final List<DeckDeparture> _departures = [];
  _Return? _expected;

  /// Son gönderilen kartın kimliği ve o an arkadaki kartın ölçeği: üste
  /// çıkan kart bu ölçekten büyür.
  String? _departedId;
  double _promoteFrom = 1;

  Offset _dragOrigin = Offset.zero;
  bool _dragging = false;

  /// Eşiği geçilmiş yön (haptik tekrarı için).
  SwipeDirection? _armed;

  Size _cardSize = Size.zero;
  Size _screen = Size.zero;

  Offset get _offset => Offset(_x.value, _y.value);

  double get _nextScale =>
      lerpDouble(AppSwipe.nextCardScale, 1, swipeProgress(_offset))!;

  @override
  void initState() {
    super.initState();
    widget.controller.attach(this);
  }

  @override
  void didUpdateWidget(SwipeDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.detach(this);
      widget.controller.attach(this);
    }
    final String? previousId = oldWidget.top?.id;
    final String? id = widget.top?.id;
    if (previousId == id) return;
    final _Return? expected = _expected;
    if (id != null && expected?.id == id) {
      _expected = null;
      _enter(expected!);
    } else if (previousId != null && previousId == _departedId) {
      _promote();
    } else {
      // Kart dışarıdan değişti (ör. analiz kategorisini buldu): yerinde.
      _resetTop();
    }
    _departedId = null;
  }

  @override
  void dispose() {
    widget.controller.detach(this);
    _x.dispose();
    _y.dispose();
    _scale.dispose();
    _opacity.dispose();
    super.dispose();
  }

  bool _isDeparting(String id) =>
      _departures.any((departure) => departure.item.id == id);

  // ---- Jest -------------------------------------------------------------

  void _onPanStart(DragStartDetails details) {
    _x.stop();
    _y.stop();
    _dragging = true;
    // Yarıda yakalanan kart bulunduğu yerden devam eder (sıçrama yok).
    _dragOrigin = details.globalPosition - _offset;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_dragging) return;
    final Offset raw = details.globalPosition - _dragOrigin;
    _x.value = raw.dx;
    // Aşağının karşılığı yok: lastik bantla direnir.
    _y.value = raw.dy > 0 ? rubberband(raw.dy, _cardSize.height) : raw.dy;
    final SwipeDirection? armed = armedDirection(_offset, _armed);
    if (armed != _armed && armed != null) Haptics.tick();
    _armed = armed;
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_dragging) return;
    _dragging = false;
    final Offset velocity = details.velocity.pixelsPerSecond;
    final SwipeDirection? direction = decideSwipe(_offset, velocity);
    if (direction == null) {
      _returnHome(velocity);
    } else {
      _commit(direction, velocity);
    }
  }

  void _onPanCancel() {
    if (!_dragging) return;
    _dragging = false;
    _returnHome(Offset.zero);
  }

  // ---- Hareketler --------------------------------------------------------

  @override
  void swipeByButton(SwipeDirection direction) {
    final SwipeDeckItem? top = widget.top;
    if (top == null || _dragging || _isDeparting(top.id)) return;
    _commit(direction, Offset.zero);
  }

  /// Kartı gönderir: uçuşu ayrı bir kart üstlenir, üst yuva sıradakine kalır.
  void _commit(SwipeDirection direction, Offset velocity) {
    final SwipeDeckItem? top = widget.top;
    if (top == null || _isDeparting(top.id)) return;
    _x.stop();
    _y.stop();
    _promoteFrom = _nextScale;
    setState(() {
      _departures.add(
        DeckDeparture(
          item: top,
          direction: direction,
          from: _offset,
          velocity: throwVelocity(direction, velocity),
          scale: _scale.value,
        ),
      );
      _departedId = top.id;
      _armed = null;
    });
    _x.value = 0;
    _y.value = 0;
    widget.onSwipe(top.id, direction);
  }

  /// Bırakılan kart yerine döner; parmağın hızını devralır, hızlı
  /// bırakılmışsa hafifçe taşar.
  void _returnHome(Offset velocity) {
    _armed = null;
    if (context.reduceMotion) {
      _x.animateTo(0, duration: AppMotion.reducedCrossfade);
      _y.animateTo(0, duration: AppMotion.reducedCrossfade);
      return;
    }
    _springHome(_x, AppSprings.momentum, velocity.dx);
    _springHome(_y, AppSprings.momentum, velocity.dy);
  }

  /// [axis]'i yayla sıfıra götürür. Yay toleransla durduğu için sonunda tam
  /// sıfıra oturtulur (dinlenen kart tam yerinde, sonraki kart hesapları
  /// sıfırdan başlar). Hareket yarıda kesilirse (kart yakalandı) oturtma
  /// yapılmaz.
  void _springHome(
    AnimationController axis,
    SpringDescription spring,
    double velocity,
  ) {
    axis
        .animateWith(SpringSimulation(spring, axis.value, 0, velocity))
        .whenComplete(() => axis.value = 0);
  }

  /// Arkadaki kart üste çıktı: bulunduğu ölçekten tam boya büyür.
  void _promote() {
    _resetTop();
    if (context.reduceMotion) return;
    _scale
      ..value = _promoteFrom
      ..animateWith(SpringSimulation(AppSprings.standard, _promoteFrom, 1, 0));
  }

  @override
  void expectReturn(String id, SwipeDirection direction) {
    final DeckDeparture? flying = _departures
        .where((departure) => departure.item.id == id)
        .firstOrNull;
    if (flying == null) {
      _expected = _Return(id, returnOrigin(direction, _screen));
      return;
    }
    // Henüz ekrandan çıkmamış kart yarıda yakalanır: bulunduğu yerden döner.
    _expected = _Return(id, flying.offset);
    setState(() => _departures.remove(flying));
  }

  /// Geri alınan kart geldiği kenardan yerine yaylanır (simetrik yol).
  void _enter(_Return expected) {
    _resetTop();
    if (context.reduceMotion) {
      _opacity
        ..value = 0
        ..animateTo(1, duration: AppMotion.reducedCrossfade);
      return;
    }
    _x.value = expected.from.dx;
    _y.value = expected.from.dy;
    _springHome(_x, AppSprings.standard, 0);
    _springHome(_y, AppSprings.standard, 0);
  }

  /// Üst yuvayı dinlenme haline alır (yarım kalan sürükleme de biter).
  void _resetTop() {
    _dragging = false;
    _armed = null;
    _x
      ..stop()
      ..value = 0;
    _y
      ..stop()
      ..value = 0;
    _scale
      ..stop()
      ..value = 1;
    _opacity.value = 1;
  }

  void _removeDeparture(DeckDeparture departure) {
    if (!_departures.contains(departure)) return;
    setState(() => _departures.remove(departure));
  }

  // ---- Çizim -------------------------------------------------------------

  /// 9:16 kartın alana sığan en büyük ölçüsü.
  static Size _fit(Size space) {
    double height = space.height;
    double width = height * AppDeck.cardAspect;
    if (width > space.width) {
      width = space.width;
      height = width / AppDeck.cardAspect;
    }
    return Size(width, height);
  }

  @override
  Widget build(BuildContext context) {
    _screen = MediaQuery.sizeOf(context);
    final bool reduceMotion = context.reduceMotion;
    final SwipeDeckItem? top = widget.top;
    final SwipeDeckItem? next = widget.next;
    return LayoutBuilder(
      builder: (context, constraints) {
        _cardSize = _fit(constraints.biggest);
        return Center(
          child: SizedBox.fromSize(
            size: _cardSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (next != null) _nextCard(next),
                if (top != null && !_isDeparting(top.id)) _topCard(top),
                for (final DeckDeparture departure in _departures)
                  DepartingCard(
                    key: departure.key,
                    departure: departure,
                    cardSize: _cardSize,
                    screen: _screen,
                    reduceMotion: reduceMotion,
                    assignIcon: widget.assignIcon,
                    assignLabel: widget.assignLabel,
                    onGone: () => _removeDeparture(departure),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Sıradaki kart: üst kart eşiğe yaklaştıkça arkadan tam boya büyür.
  Widget _nextCard(SwipeDeckItem item) {
    return Positioned.fill(
      key: ValueKey('next-${item.id}'),
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _topMotion,
          builder: (context, child) =>
              Transform.scale(scale: _nextScale, child: child),
          child: SwipeCard(
            asset: item.asset,
            assignIcon: widget.assignIcon,
            assignLabel: widget.assignLabel,
          ),
        ),
      ),
    );
  }

  Widget _topCard(SwipeDeckItem item) {
    // Kimlikle anahtarlanır: kart değişince eski parmak yenisini sürüklemez.
    return Positioned.fill(
      key: ValueKey('top-${item.id}'),
      child: AnimatedBuilder(
        animation: _topMotion,
        builder: (context, child) {
          final Offset offset = _offset;
          return Opacity(
            opacity: _opacity.value,
            child: CardTransform(
              offset: offset,
              scale: _scale.value,
              cardSize: _cardSize,
              // Jest kartın içinde: dönerken yakalanan kart da tutulabilir.
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                onPanCancel: _onPanCancel,
                child: SwipeCard(
                  asset: item.asset,
                  assignIcon: widget.assignIcon,
                  assignLabel: widget.assignLabel,
                  direction: directionOf(offset),
                  progress: swipeProgress(offset),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

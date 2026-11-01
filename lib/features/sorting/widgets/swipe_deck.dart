// Temizle destesi: üstteki kart parmağı 1:1 izler ve tutulan noktadan döner;
// bırakışta konum + hız projeksiyonuyla karar verir. Giden kart bırakış
// hızıyla uçar ve beklenmez — sıradaki kart anında tutulabilir.
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/constants/motion_constants.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/utils/motion_physics.dart';
import '../swipe_decision.dart';
import 'swipe_card.dart';

/// Destedeki tek kart: kimlik + görsel kaynağı.
@immutable
class SwipeDeckItem {
  const SwipeDeckItem(this.id, this.asset);

  final String id;
  final AssetEntity? asset;
}

/// Desteye dışarıdan (alttaki butonlar, geri al) komut veren köprü.
class SwipeDeckController {
  _SwipeDeckState? _deck;

  /// Bağlı deste var mı (test ve teşhis için).
  bool get isAttached => _deck != null;

  void _attach(_SwipeDeckState deck) => _deck = deck;

  /// Yalnız kendi bağladığı desteyi çözer: yeni deste, eskisinin
  /// `dispose`'undan önce bağlanabilir; kimlik bakılmazsa eski deste yeninin
  /// bağlantısını silip butonları öldürürdü.
  void _detach(_SwipeDeckState deck) {
    if (identical(_deck, deck)) _deck = null;
  }

  /// Üstteki kartı [direction] yönünde fırlatır (buton dokunuşu).
  void swipe(SwipeDirection direction) => _deck?._swipeByButton(direction);

  /// [id]'li kart birazdan geri gelecek (geri al): üste çıktığında
  /// [direction] kenarından — hâlâ uçuyorsa bulunduğu yerden — yayla döner.
  void expectReturn(String id, SwipeDirection direction) =>
      _deck?._expectReturn(id, direction);
}

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

/// Uçmakta olan kartın verisi; [offset] uçuş boyunca güncellenir (geri al
/// kartı yarıda yakalarsa oradan döndürür). Dinleyicisi yok, düz alan: kart
/// ağaçtan çıktıktan sonra son yay karesi yazsa da sorun olmaz.
class _Departure {
  _Departure({
    required this.item,
    required this.direction,
    required this.from,
    required this.velocity,
    required this.scale,
  }) : offset = from;

  final Key key = UniqueKey();
  final SwipeDeckItem item;
  final SwipeDirection direction;
  final Offset from;
  final Offset velocity;
  final double scale;
  Offset offset;
}

/// Beklenen geri dönüş: kartın döneceği başlangıç noktası.
class _Return {
  const _Return(this.id, this.from);

  final String id;
  final Offset from;
}

class _SwipeDeckState extends State<SwipeDeck> with TickerProviderStateMixin {
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

  final List<_Departure> _departures = [];
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
    widget.controller._attach(this);
  }

  @override
  void didUpdateWidget(SwipeDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller._detach(this);
      widget.controller._attach(this);
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
    widget.controller._detach(this);
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

  void _swipeByButton(SwipeDirection direction) {
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
        _Departure(
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

  void _expectReturn(String id, SwipeDirection direction) {
    final _Departure? flying = _departures
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

  void _removeDeparture(_Departure departure) {
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
                for (final _Departure departure in _departures)
                  _DepartingCard(
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
            child: _CardTransform(
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

/// Kartı ofset kadar taşır ve çekildiği yöne yatırır.
class _CardTransform extends StatelessWidget {
  const _CardTransform({
    required this.offset,
    required this.scale,
    required this.cardSize,
    required this.child,
  });

  final Offset offset;
  final double scale;
  final Size cardSize;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: swipeRotation(offset.dx, cardSize.width),
        // Mil alt kenarda: kart avuçtaki iskambil gibi yelpazelenir ve en
        // sık tutulan alt yarı başparmağın altından kaymaz.
        origin: Offset(0, cardSize.height / 2),
        child: Transform.scale(scale: scale, child: child),
      ),
    );
  }
}

/// Gönderilmiş, ekrandan çıkmakta olan kart: bırakış hızıyla başlayan iki
/// eksenli yayla ekranın dışına uçar, sonra kendini kaldırır. Dokunulmaz.
class _DepartingCard extends StatefulWidget {
  const _DepartingCard({
    super.key,
    required this.departure,
    required this.cardSize,
    required this.screen,
    required this.reduceMotion,
    required this.assignIcon,
    required this.assignLabel,
    required this.onGone,
  });

  final _Departure departure;
  final Size cardSize;
  final Size screen;

  /// Hareketi Azalt: uçmak yerine yerinde söner.
  final bool reduceMotion;
  final IconData assignIcon;
  final String assignLabel;
  final VoidCallback onGone;

  @override
  State<_DepartingCard> createState() => _DepartingCardState();
}

class _DepartingCardState extends State<_DepartingCard>
    with TickerProviderStateMixin {
  late final _Departure _departure = widget.departure;
  late final AnimationController _x = AnimationController.unbounded(
    vsync: this,
    value: _departure.from.dx,
  );
  late final AnimationController _y = AnimationController.unbounded(
    vsync: this,
    value: _departure.from.dy,
  );

  /// Kartın ağaçtaki ömrü (0 → 1); Hareketi Azalt'ta solmayı da sürer.
  late final AnimationController _life = AnimationController(
    vsync: this,
    duration: widget.reduceMotion
        ? AppMotion.reducedCrossfade
        : AppSwipe.exitDuration,
  );

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) {
      final Offset target = exitTarget(
        _departure.direction,
        _departure.from,
        _departure.velocity,
        widget.screen,
      );
      _x.animateWith(
        SpringSimulation(
          AppSprings.standard,
          _departure.from.dx,
          target.dx,
          _departure.velocity.dx,
        ),
      );
      _y.animateWith(
        SpringSimulation(
          AppSprings.standard,
          _departure.from.dy,
          target.dy,
          _departure.velocity.dy,
        ),
      );
    }
    _x.addListener(_report);
    _y.addListener(_report);
    _life.forward().whenComplete(() {
      if (mounted) widget.onGone();
    });
  }

  @override
  void dispose() {
    _x.dispose();
    _y.dispose();
    _life.dispose();
    super.dispose();
  }

  void _report() => _departure.offset = Offset(_x.value, _y.value);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: Listenable.merge([_x, _y, _life]),
          builder: (context, child) {
            final Offset offset = Offset(_x.value, _y.value);
            final double travel = travelAlong(offset, _departure.direction);
            return Opacity(
              opacity: widget.reduceMotion ? 1 - _life.value : 1,
              child: _CardTransform(
                offset: offset,
                scale: _departure.scale,
                cardSize: widget.cardSize,
                child: SwipeCard(
                  asset: _departure.item.asset,
                  assignIcon: widget.assignIcon,
                  assignLabel: widget.assignLabel,
                  direction: _departure.direction,
                  progress: (travel / AppSwipe.threshold).clamp(0.0, 1.0),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

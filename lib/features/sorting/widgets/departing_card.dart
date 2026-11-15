// Temizle destesinden gönderilen kartın uçuşu ve kart dönüşümü: bırakış
// hızıyla ekran dışına yaylanır, sonra kendini kaldırır.
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../../core/constants/motion_constants.dart';
import '../swipe_decision.dart';
import 'swipe_card.dart';
import 'swipe_deck_controller.dart';

/// Uçmakta olan kartın verisi; [offset] uçuş boyunca güncellenir (geri al
/// kartı yarıda yakalarsa oradan döndürür). Dinleyicisi yok, düz alan: kart
/// ağaçtan çıktıktan sonra son yay karesi yazsa da sorun olmaz.
class DeckDeparture {
  DeckDeparture({
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

/// Kartı ofset kadar taşır ve çekildiği yöne yatırır.
class CardTransform extends StatelessWidget {
  const CardTransform({
    super.key,
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
class DepartingCard extends StatefulWidget {
  const DepartingCard({
    super.key,
    required this.departure,
    required this.cardSize,
    required this.screen,
    required this.reduceMotion,
    required this.assignIcon,
    required this.assignLabel,
    required this.onGone,
  });

  final DeckDeparture departure;
  final Size cardSize;
  final Size screen;

  /// Hareketi Azalt: uçmak yerine yerinde söner.
  final bool reduceMotion;
  final IconData assignIcon;
  final String assignLabel;

  /// Uçuş bitip kart ağaçtan çıkarılabilir olduğunda çağrılır.
  final VoidCallback onGone;

  @override
  State<DepartingCard> createState() => _DepartingCardState();
}

class _DepartingCardState extends State<DepartingCard>
    with TickerProviderStateMixin {
  late final DeckDeparture _departure = widget.departure;
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

  /// Konum ve ömrün birleşimi; her build'de yeniden kurulmaz.
  late final Listenable _changes = Listenable.merge([_x, _y, _life]);

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
          animation: _changes,
          builder: (context, child) {
            final Offset offset = Offset(_x.value, _y.value);
            final double travel = travelAlong(offset, _departure.direction);
            return Opacity(
              opacity: widget.reduceMotion ? 1 - _life.value : 1,
              child: CardTransform(
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

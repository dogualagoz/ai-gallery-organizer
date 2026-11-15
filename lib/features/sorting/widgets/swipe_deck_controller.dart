// Temizle destesinin veri birimi ve desteye dışarıdan komut veren köprü.
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

import '../swipe_decision.dart';

/// Destedeki tek kart: kimlik + görsel kaynağı.
@immutable
class SwipeDeckItem {
  const SwipeDeckItem(this.id, this.asset);

  final String id;
  final AssetEntity? asset;
}

/// Destenin dışarıdan sürülebilen komutları; yalnız `SwipeDeck` uygular.
abstract interface class SwipeDeckCommands {
  /// Üstteki kartı [direction] yönünde fırlatır.
  void swipeByButton(SwipeDirection direction);

  /// [id]'li kartın [direction] kenarından geri döneceğini bildirir.
  void expectReturn(String id, SwipeDirection direction);
}

/// Desteye dışarıdan (alttaki butonlar, geri al) komut veren köprü.
class SwipeDeckController {
  SwipeDeckCommands? _deck;

  /// Bağlı deste var mı (test ve teşhis için).
  bool get isAttached => _deck != null;

  /// Desteyi bağlar; yalnız `SwipeDeck` çağırır.
  void attach(SwipeDeckCommands deck) => _deck = deck;

  /// Yalnız kendi bağladığı desteyi çözer: yeni deste, eskisinin
  /// `dispose`'undan önce bağlanabilir; kimlik bakılmazsa eski deste yeninin
  /// bağlantısını silip butonları öldürürdü. Yalnız `SwipeDeck` çağırır.
  void detach(SwipeDeckCommands deck) {
    if (identical(_deck, deck)) _deck = null;
  }

  /// Üstteki kartı [direction] yönünde fırlatır (buton dokunuşu).
  void swipe(SwipeDirection direction) => _deck?.swipeByButton(direction);

  /// [id]'li kart birazdan geri gelecek (geri al): üste çıktığında
  /// [direction] kenarından — hâlâ uçuyorsa bulunduğu yerden — yayla döner.
  void expectReturn(String id, SwipeDirection direction) =>
      _deck?.expectReturn(id, direction);
}

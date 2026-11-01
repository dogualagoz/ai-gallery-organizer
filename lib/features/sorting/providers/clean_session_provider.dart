// Temizle oturumunun durumu: atlananlar, silinmeyi bekleyenler, bu oturumda
// atananlar ve geri alma geçmişi. Sekme değişse de korunur; sekme rozeti
// bekleyen silme sayısını buradan okur.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/screenshot_category.dart';
import '../../../core/models/screenshot_entry.dart';
import '../../../core/services/entitlement_service.dart';
import '../../gallery/data/screenshot_repository.dart';
import '../../gallery/providers/gallery_provider.dart';
import '../swipe_decision.dart';

/// Oturumdaki tek kaydırma; "Geri al" için saklanır.
@immutable
class CleanMove {
  const CleanMove(this.assetId, this.direction, {this.placement});

  final String assetId;
  final SwipeDirection direction;

  /// Atama öncesi yerleşim (yalnız yukarı kaydırmada): geri alınca kayıt
  /// birebir eski haline döner.
  final ScreenshotPlacement? placement;
}

/// Temizle destesinin oturum durumu (değişmez; her hareket yeni örnek üretir).
@immutable
class CleanSession {
  const CleanSession({
    this.skipped = const {},
    this.pendingDeletes = const {},
    this.assigned = const {},
    this.history = const [],
    this.front,
  });

  /// Bu oturumda atlananlar (kalıcı değil).
  final Set<String> skipped;

  /// Sola kaydırılıp silinmeyi bekleyenler; kullanıcı onaylayınca silinir.
  final Set<String> pendingDeletes;

  /// Kategoriye atananlar: kayıt yazılıp galeri yenilenene kadar desteden
  /// hemen düşsünler (aynı kart ikinci kez işlenemez).
  final Set<String> assigned;

  final List<CleanMove> history;

  /// Geri alınan kart: deste başına alınır ki kullanıcı onu hemen görsün.
  final String? front;

  bool get canUndo => history.isNotEmpty;

  /// Destedeki sıra: analiz bekleyen ya da "Diğer"e düşmüş, panoda olmayan
  /// ve bu oturumda ele alınmamış kayıtlar; geri alınan kart başta.
  List<ScreenshotEntry> queue(List<ScreenshotEntry> entries) {
    final List<ScreenshotEntry> deck = [
      for (final ScreenshotEntry entry in entries)
        if (_needsCleaning(entry) && !_handled(entry.assetId)) entry,
    ];
    final int index = deck.indexWhere((entry) => entry.assetId == front);
    if (index > 0) deck.insert(0, deck.removeAt(index));
    return deck;
  }

  static bool _needsCleaning(ScreenshotEntry entry) =>
      entry.boardId == null &&
      (entry.isPending || entry.category == ScreenshotCategory.other);

  bool _handled(String assetId) =>
      skipped.contains(assetId) ||
      pendingDeletes.contains(assetId) ||
      assigned.contains(assetId);

  /// [front] bilerek verilmezse temizlenir: geri alınan kart bir sonraki
  /// harekette sıradan bir kart olur.
  CleanSession _copyWith({
    Set<String>? skipped,
    Set<String>? pendingDeletes,
    Set<String>? assigned,
    List<CleanMove>? history,
    String? front,
  }) {
    return CleanSession(
      skipped: skipped ?? this.skipped,
      pendingDeletes: pendingDeletes ?? this.pendingDeletes,
      assigned: assigned ?? this.assigned,
      history: history ?? this.history,
      front: front,
    );
  }
}

/// Oturum durumu; uygulama açık kaldıkça yaşar.
final cleanSessionProvider =
    NotifierProvider<CleanSessionNotifier, CleanSession>(
      CleanSessionNotifier.new,
    );

/// Galeride hâlâ duran bekleyen silmeler (başka ekrandan silinenler düşer).
/// Sekme rozeti ve silme çubuğu bu listeyi kullanır.
final pendingDeleteIdsProvider = Provider<List<String>>((ref) {
  final Set<String> pending = ref.watch(
    cleanSessionProvider.select((session) => session.pendingDeletes),
  );
  if (pending.isEmpty) return const [];
  final List<ScreenshotEntry> entries =
      ref.watch(galleryProvider).value ?? const [];
  return [
    for (final ScreenshotEntry entry in entries)
      if (pending.contains(entry.assetId)) entry.assetId,
  ];
});

/// Kaydırmaları işler ve geri alır.
class CleanSessionNotifier extends Notifier<CleanSession> {
  /// Atamanın geri yazımı sürüyor: art arda dokunuş aynı hamleyi iki kez
  /// geri almasın.
  bool _undoing = false;

  @override
  CleanSession build() => const CleanSession();

  /// [entry]'yi [direction] yönünde işler. Durum anında güncellenir (kart
  /// desteden hemen çıkar); atamanın kalıcı yazımı ardından yapılır. Yazım
  /// başarısızsa kart desteye geri döner ve false döner.
  Future<bool> swipe(
    ScreenshotEntry entry,
    SwipeDirection direction,
    ScreenshotCategory target,
  ) async {
    final String id = entry.assetId;
    final CleanSession session = state;
    switch (direction) {
      case SwipeDirection.left:
        state = session._copyWith(
          pendingDeletes: {...session.pendingDeletes, id},
          history: [...session.history, CleanMove(id, direction)],
        );
      case SwipeDirection.right:
        state = session._copyWith(
          skipped: {...session.skipped, id},
          history: [...session.history, CleanMove(id, direction)],
        );
        return true;
      case SwipeDirection.up:
        state = session._copyWith(
          assigned: {...session.assigned, id},
          history: [
            ...session.history,
            CleanMove(id, direction, placement: ScreenshotPlacement.of(entry)),
          ],
        );
        try {
          await ref.read(screenshotRepositoryProvider).setCategory(id, target);
        } catch (error, stackTrace) {
          debugPrint('Swipe kategori ataması yazılamadı: $error\n$stackTrace');
          state = state._copyWith(
            assigned: {...state.assigned}..remove(id),
            history: [
              for (final CleanMove move in state.history)
                if (move.assetId != id) move,
            ],
            front: id,
          );
          return false;
        }
    }
    await ref.read(entitlementProvider.notifier).registerSwipe();
    return true;
  }

  /// Son kaydırmayı geri alır; kart deste başına döner. [onReturn] durum
  /// değişmeden hemen önce çağrılır (deste kartın dönüşünü beklesin). Yukarı
  /// atama önce kalıcı olarak geri yazılır; yazılamazsa false döner, hamle
  /// geçmişte kalır ve kart dönmez.
  Future<bool> undo({VoidCallback? onReturn}) async {
    if (_undoing) return true;
    final CleanMove? move = state.history.lastOrNull;
    if (move == null) return true;
    final ScreenshotPlacement? placement = move.placement;
    if (placement != null) {
      _undoing = true;
      try {
        await ref
            .read(screenshotRepositoryProvider)
            .restorePlacement(placement);
      } catch (error, stackTrace) {
        debugPrint('Swipe ataması geri alınamadı: $error\n$stackTrace');
        return false;
      } finally {
        _undoing = false;
      }
    }
    final CleanSession session = state;
    final String id = move.assetId;
    // Beklerken başka kartlar kaydırılmış olabilir: yalnız bu hamle düşer.
    final List<CleanMove> history = [...session.history]..remove(move);
    onReturn?.call();
    state = switch (move.direction) {
      SwipeDirection.left => session._copyWith(
        pendingDeletes: {...session.pendingDeletes}..remove(id),
        history: history,
        front: id,
      ),
      SwipeDirection.right => session._copyWith(
        skipped: {...session.skipped}..remove(id),
        history: history,
        front: id,
      ),
      SwipeDirection.up => session._copyWith(
        assigned: {...session.assigned}..remove(id),
        history: history,
        front: id,
      ),
    };
    return true;
  }

  /// Fotoğraf kütüphanesinden silinen [ids] bekleyenlerden ve geçmişten
  /// düşer (artık geri alınacak bir kart yok).
  void markDeleted(Iterable<String> ids) {
    final Set<String> gone = ids.toSet();
    state = state._copyWith(
      pendingDeletes: state.pendingDeletes.difference(gone),
      history: [
        for (final CleanMove move in state.history)
          if (!gone.contains(move.assetId)) move,
      ],
      front: state.front,
    );
  }

  /// Bekleyen silmelerden vazgeçer: kartlar desteye geri döner.
  void keepPendingDeletes() {
    final Set<String> kept = state.pendingDeletes;
    state = state._copyWith(
      pendingDeletes: const {},
      history: [
        for (final CleanMove move in state.history)
          if (!kept.contains(move.assetId)) move,
      ],
    );
  }

  /// Atlananları desteye geri getirir (deste bittikten sonra).
  void resetSkipped() {
    final Set<String> skipped = state.skipped;
    state = state._copyWith(
      skipped: const {},
      history: [
        for (final CleanMove move in state.history)
          if (!skipped.contains(move.assetId)) move,
      ],
    );
  }
}

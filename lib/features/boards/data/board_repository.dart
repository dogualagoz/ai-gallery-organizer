// Kullanıcı board'larına erişim katmanı (Hive box sarmalayıcısı).
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../../../core/models/board.dart';
import '../../../core/services/hive_service.dart';

final boardRepositoryProvider = Provider<BoardRepository>((ref) {
  return BoardRepository(HiveService.boards);
});

class BoardRepository {
  BoardRepository(this._box);

  final Box<Board> _box;
  static final Random _idRandom = Random();

  /// Board'lar kullanıcının belirlediği sıraya göre; eşitlikte en eski önce.
  List<Board> sortedBoards() {
    final List<Board> boards = _box.values.toList()
      ..sort((a, b) {
        final int byOrder = a.sortOrder.compareTo(b.sortOrder);
        return byOrder != 0 ? byOrder : a.createdAt.compareTo(b.createdAt);
      });
    return boards;
  }

  Stream<BoxEvent> watchChanges() => _box.watch();

  Board? boardFor(String id) => _box.get(id);

  Future<Board> create(String name) async {
    // Yeni board her zaman listenin sonuna eklenir.
    final int maxOrder = _box.values.fold<int>(
      -1,
      (int max, Board b) => b.sortOrder > max ? b.sortOrder : max,
    );
    final Board board = Board(
      id: _generateId(),
      name: name,
      createdAt: DateTime.now(),
      sortOrder: maxOrder + 1,
    );
    await _box.put(board.id, board);
    return board;
  }

  /// [orderedIds] sırasına göre tüm board'ların [Board.sortOrder] alanını
  /// yeniden yazar (0'dan artan). Listede olmayan id'ler atlanır.
  Future<void> reorder(List<String> orderedIds) async {
    for (int i = 0; i < orderedIds.length; i++) {
      final Board? board = _box.get(orderedIds[i]);
      if (board == null || board.sortOrder == i) continue;
      board.sortOrder = i;
      await _box.put(board.id, board);
    }
  }

  Future<void> rename(String id, String name) async {
    final Board? board = _box.get(id);
    if (board == null) return;
    board.name = name;
    await _box.put(id, board);
  }

  Future<void> delete(String id) => _box.delete(id);

  /// Zaman damgası + rastgele ek — uuid bağımlılığı gerektirmeyen basit,
  /// çakışma ihtimali ihmal edilebilir yerel kimlik üretimi.
  String _generateId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_idRandom.nextInt(1 << 32)}';
}

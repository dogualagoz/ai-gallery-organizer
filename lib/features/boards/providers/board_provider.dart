// Board listesi state'i: Hive box değişikliklerini dinler, CRUD aksiyonları sunar.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/board.dart';
import '../../gallery/data/screenshot_repository.dart';
import '../data/board_repository.dart';

final boardsProvider = AsyncNotifierProvider<BoardsNotifier, List<Board>>(
  BoardsNotifier.new,
);

class BoardsNotifier extends AsyncNotifier<List<Board>> {
  Timer? _reloadDebounce;

  @override
  Future<List<Board>> build() async {
    final BoardRepository repo = ref.watch(boardRepositoryProvider);

    final StreamSubscription<void> subscription = repo.watchChanges().listen((
      _,
    ) {
      _reloadDebounce?.cancel();
      _reloadDebounce = Timer(const Duration(milliseconds: 100), () {
        state = AsyncData(repo.sortedBoards());
      });
    });
    ref.onDispose(() {
      subscription.cancel();
      _reloadDebounce?.cancel();
    });

    return repo.sortedBoards();
  }

  Future<Board> create(String name) =>
      ref.read(boardRepositoryProvider).create(name);

  Future<void> rename(String id, String name) =>
      ref.read(boardRepositoryProvider).rename(id, name);

  /// Board'ları [orderedIds] sırasına göre yeniden dizer (sürükle-bırak sonrası).
  Future<void> reorder(List<String> orderedIds) =>
      ref.read(boardRepositoryProvider).reorder(orderedIds);

  /// Board'u siler; içindeki screenshot kayıtları silinmez, yalnızca
  /// board bağlantıları kaldırılır (kategori görünümlerinde kalmaya devam ederler).
  Future<void> delete(String id) async {
    final ScreenshotRepository screenshotRepo = ref.read(
      screenshotRepositoryProvider,
    );
    final Iterable<String> assignedAssetIds = screenshotRepo.sortedEntries()
        .where((entry) => entry.boardId == id)
        .map((entry) => entry.assetId);
    for (final String assetId in assignedAssetIds) {
      await screenshotRepo.assignToBoard(assetId, null);
    }
    await ref.read(boardRepositoryProvider).delete(id);
  }
}

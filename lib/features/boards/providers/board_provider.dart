// Board listesi state'i: Hive box değişikliklerini dinler, CRUD aksiyonları sunar.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/board.dart';
import '../../../core/utils/debounced_listen.dart';
import '../../gallery/data/screenshot_repository.dart';
import '../data/board_repository.dart';

final boardsProvider = AsyncNotifierProvider<BoardsNotifier, List<Board>>(
  BoardsNotifier.new,
);

/// Id'si verilen pano; listede yoksa (yüklenmedi ya da silindi) null.
final boardByIdProvider = Provider.family<Board?, String>((ref, id) {
  final List<Board> boards = ref.watch(boardsProvider).value ?? const [];
  return boards.where((board) => board.id == id).firstOrNull;
});

/// Anasayfadaki pano/kategori ızgaralarının "düzenleme modu" (iOS jiggle).
/// Uzun basınca açılır, "Bitti" ile kapanır; her iki ızgara da paylaşır.
final boardsEditModeProvider = NotifierProvider<BoardsEditModeNotifier, bool>(
  BoardsEditModeNotifier.new,
);

class BoardsEditModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void enable() => state = true;
  void disable() => state = false;
}

class BoardsNotifier extends AsyncNotifier<List<Board>> {
  @override
  Future<List<Board>> build() async {
    final BoardRepository repo = ref.watch(boardRepositoryProvider);
    listenDebounced(
      ref,
      repo.watchChanges(),
      () => state = AsyncData(repo.sortedBoards()),
    );
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
    await screenshotRepo.assignManyToBoard(
      screenshotRepo.assetIdsInBoard(id),
      null,
    );
    await ref.read(boardRepositoryProvider).delete(id);
  }
}

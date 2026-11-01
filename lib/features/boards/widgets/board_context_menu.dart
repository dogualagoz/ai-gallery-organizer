// Karoya uzun basınca açılan iOS bağlam menüsü: karo büyüyerek öne çıkar,
// altında Yeniden adlandır / Yeniden analiz et / Seç / Sil eylemleri durur.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/board.dart';
import '../../../core/models/screenshot_category.dart';
import '../../../core/widgets/app_menus.dart';
import 'board_edit_actions.dart';

/// [child] karosunu bağlam menüsüyle sarar. [board] ya da [category]'den tam
/// biri verilmelidir. Önizleme karonun ızgaradaki ölçüsüyle çizilir.
///
/// Karonun altında GlobalKey bulunmamalı: menü, önizleme için çocuğu ikinci
/// kez kurar. Uçuş hedefi anahtarı bu widget'ın dışına konur.
class BoardContextMenu extends ConsumerWidget {
  const BoardContextMenu({
    super.key,
    required this.child,
    required this.isEmpty,
    this.board,
    this.category,
  }) : assert((board == null) != (category == null));

  final Widget child;

  /// Panoda içerik yoksa seçme/silme eylemleri gösterilmez.
  final bool isEmpty;
  final Board? board;
  final ScreenshotCategory? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppContextMenu(
      actions: boardMenuActions(
        context,
        ref,
        isEmpty: isEmpty,
        board: board,
        category: category,
        onSelect: () =>
            openBoardSelection(context, ref, board: board, category: category),
      ),
      child: child,
    );
  }
}

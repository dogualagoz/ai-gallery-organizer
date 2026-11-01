// Karoya uzun basınca açılan iOS bağlam menüsü: karo büyüyerek öne çıkar,
// altında Yeniden adlandır / Yeniden analiz et / Seç / Sil eylemleri durur.
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/models/board.dart';
import '../../../core/models/screenshot_category.dart';
import 'board_edit_actions.dart';

/// [child] karosunu bağlam menüsüyle sarar. [board] ya da [category]'den tam
/// biri verilmelidir. Önizleme karonun ızgaradaki ölçüsüyle çizilir.
///
/// Karonun altında GlobalKey/Hero bulunmamalı: menü, önizleme için çocuğu
/// ikinci kez kurar. Uçuş hedefi anahtarı bu widget'ın dışına konur.
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
    final l10n = context.l10n;
    final ScreenshotCategory? category = this.category;
    final Board? board = this.board;

    /// Menüyü kapatıp eylemi karonun (hâlâ bağlı) context'iyle çalıştırır.
    Widget action({
      required String label,
      required IconData icon,
      required VoidCallback onPressed,
      bool destructive = false,
    }) {
      return CupertinoContextMenuAction(
        trailingIcon: icon,
        isDestructiveAction: destructive,
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop();
          onPressed();
        },
        child: Text(label),
      );
    }

    return LayoutBuilder(
      // Menü önizlemesi çocuğu gevşek kısıtla kurar; ızgara hücresinin ölçüsü
      // sabitlenmezse karo içindeki Expanded sınırsız yüksekliğe yayılır.
      builder: (_, constraints) => CupertinoContextMenu(
        enableHapticFeedback: true,
        actions: [
          action(
            label: l10n.boardsRenameAction,
            icon: AppIcons.edit,
            onPressed: () =>
                renameBoard(context, ref, board: board, category: category),
          ),
          if (category != null && !isEmpty)
            action(
              label: l10n.categoryReanalyzeAction,
              icon: AppIcons.reanalyze,
              onPressed: () => reanalyzeCategory(context, ref, category),
            ),
          if (!isEmpty)
            action(
              label: l10n.bulkSelectAction,
              icon: AppIcons.select,
              onPressed: () => openBoardSelection(
                context,
                ref,
                board: board,
                category: category,
              ),
            ),
          if (board != null)
            action(
              label: l10n.boardsDeleteAction,
              icon: AppIcons.delete,
              destructive: true,
              onPressed: () => deleteBoard(context, ref, board),
            )
          else if (!isEmpty)
            action(
              label: l10n.categoryDeleteAllAction,
              icon: AppIcons.delete,
              destructive: true,
              onPressed: () => deleteAllInBoard(
                context,
                ref,
                boardEntries(ref, category: category),
              ),
            ),
        ],
        child: SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: child,
        ),
      ),
    );
  }
}

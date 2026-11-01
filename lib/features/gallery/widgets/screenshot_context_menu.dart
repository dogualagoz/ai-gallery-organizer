// Izgara karosuna uzun basınca açılan bağlam menüsü: ekran görüntüsü büyüyerek
// öne çıkar, altında Paylaş / Taşı / Sil durur.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/models/screenshot_entry.dart';
import '../../../core/widgets/app_menus.dart';
import '../screenshot_actions.dart';

/// [child] karosunu [entry] için bağlam menüsüyle sarar.
class ScreenshotContextMenu extends ConsumerWidget {
  const ScreenshotContextMenu({
    super.key,
    required this.entry,
    required this.child,
  });

  final ScreenshotEntry entry;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final List<String> ids = [entry.assetId];
    return AppContextMenu(
      actions: [
        AppMenuAction(
          label: l10n.shareAction,
          icon: AppIcons.share,
          onPressed: () => shareScreenshots(context, ref, ids),
        ),
        AppMenuAction(
          label: l10n.moveAction,
          icon: AppIcons.move,
          onPressed: () => moveScreenshots(
            context,
            ref,
            ids,
            currentCategory: entry.category,
            currentBoardId: entry.boardId,
          ),
        ),
        AppMenuAction(
          label: l10n.deleteAction,
          icon: AppIcons.delete,
          destructive: true,
          onPressed: () => deleteScreenshots(context, ref, ids),
        ),
      ],
      child: child,
    );
  }
}

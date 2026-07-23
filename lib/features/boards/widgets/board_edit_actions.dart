// Jiggle düzenleme modunda bir karoya dokununca açılan yönetim aksiyon sayfası:
// yeniden adlandır, fotoğrafları seç (toplu sil/taşı), tümünü sil ve (özel
// board'da) panoyu sil. Sistem kategorilerinde varsayılan amaç bilgi olarak kalır.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/category_labels.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/models/board.dart';
import '../../../core/models/screenshot_category.dart';
import '../../../core/models/screenshot_entry.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/category_names_service.dart';
import '../../../core/services/entitlement_service.dart';
import '../../../core/widgets/confirm_sheet.dart';
import '../../gallery/data/screenshot_repository.dart';
import '../../gallery/providers/gallery_provider.dart';
import '../board_detail_screen.dart';
import '../providers/board_provider.dart';
import 'board_name_dialog.dart';

/// Düzenleme modu aksiyon sayfasından seçilen işlem.
enum _BoardEditAction { rename, select, deleteAll, deleteBoard }

/// [board] ya da [category] için düzenleme aksiyon sayfasını açar ve seçilen
/// işlemi çalıştırır. İkisinden tam biri verilmelidir.
Future<void> showBoardEditActions(
  BuildContext context,
  WidgetRef ref, {
  Board? board,
  ScreenshotCategory? category,
}) async {
  assert(
    (board == null) != (category == null),
    'Tam olarak board ya da category verilmeli.',
  );
  final l10n = context.l10n;
  final ColorScheme scheme = Theme.of(context).colorScheme;
  final List<ScreenshotEntry> entries =
      ref.read(galleryProvider).value ?? const [];
  final List<ScreenshotEntry> filtered = category != null
      ? entries.where((entry) => entry.category == category).toList()
      : entries.where((entry) => entry.boardId == board!.id).toList();
  final Map<int, String> names = ref.read(categoryNamesProvider);
  final String title = category != null
      ? category.displayName(l10n, names)
      : board!.name;
  // Sistem kategorisinin özgün amacı: yeniden adlandırılsa da otomatik sıralama
  // buna göre çalışır; kullanıcı ne olduğunu unutmasın diye bilgi olarak durur.
  final String? subtitle = category != null
      ? l10n.categoryDefaultNameHint(category.label(l10n))
      : null;

  final _BoardEditAction? action = await showModalBottomSheet<_BoardEditAction>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(
              category != null
                  ? l10n.categoryRenameAction
                  : l10n.boardsRenameAction,
            ),
            onTap: () =>
                Navigator.of(sheetContext).pop(_BoardEditAction.rename),
          ),
          if (filtered.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.checklist_outlined),
              title: Text(l10n.bulkSelectAction),
              onTap: () =>
                  Navigator.of(sheetContext).pop(_BoardEditAction.select),
            ),
          if (filtered.isNotEmpty)
            ListTile(
              leading: Icon(Icons.delete_sweep_outlined, color: scheme.error),
              title: Text(
                l10n.categoryDeleteAllAction,
                style: TextStyle(color: scheme.error),
              ),
              onTap: () =>
                  Navigator.of(sheetContext).pop(_BoardEditAction.deleteAll),
            ),
          if (board != null)
            ListTile(
              leading: Icon(Icons.delete_outline, color: scheme.error),
              title: Text(
                l10n.boardsDeleteAction,
                style: TextStyle(color: scheme.error),
              ),
              onTap: () =>
                  Navigator.of(sheetContext).pop(_BoardEditAction.deleteBoard),
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    ),
  );

  if (action == null || !context.mounted) return;
  switch (action) {
    case _BoardEditAction.rename:
      await _rename(context, ref, board: board, category: category);
    case _BoardEditAction.select:
      _openSelection(context, ref, board: board, category: category);
    case _BoardEditAction.deleteAll:
      await _deleteAll(context, ref, filtered);
    case _BoardEditAction.deleteBoard:
      await _deleteBoard(context, ref, board!);
  }
}

/// Yeniden adlandırma: sistem kategorisinde ad override'ı, özel board'da isim.
Future<void> _rename(
  BuildContext context,
  WidgetRef ref, {
  Board? board,
  ScreenshotCategory? category,
}) async {
  final l10n = context.l10n;
  if (category != null) {
    final Map<int, String> names = ref.read(categoryNamesProvider);
    final String current = names[category.index] ?? category.label(l10n);
    final String? name = await showDialog<String>(
      context: context,
      builder: (_) => BoardNameDialog(
        title: l10n.categoryRenameDialogTitle,
        confirmLabel: l10n.categoryRenameAction,
        initialValue: current,
      ),
    );
    if (name == null) return;
    final CategoryNamesNotifier notifier = ref.read(
      categoryNamesProvider.notifier,
    );
    // Varsayılan etiketle aynıysa override'ı temizle (özel ad kaldır).
    if (name.trim() == category.label(l10n)) {
      await notifier.clear(category);
    } else {
      await notifier.setName(category, name);
    }
    return;
  }

  final String? name = await showDialog<String>(
    context: context,
    builder: (_) => BoardNameDialog(
      title: l10n.boardsRenameDialogTitle,
      confirmLabel: l10n.boardsRenameAction,
      initialValue: board!.name,
    ),
  );
  if (name == null || name.isEmpty) return;
  await ref.read(boardsProvider.notifier).rename(board!.id, name);
}

/// Board/kategori detayını doğrudan seçim modunda açar (toplu sil/taşı).
/// Toplu işlem Pro'ya bağlı; değilse paywall'a yönlendirir.
void _openSelection(
  BuildContext context,
  WidgetRef ref, {
  Board? board,
  ScreenshotCategory? category,
}) {
  if (!ref.read(entitlementProvider).canBulkDelete) {
    context.push(AppRoutes.paywall);
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => category != null
          ? BoardDetailScreen.category(
              category: category,
              startInSelection: true,
            )
          : BoardDetailScreen.custom(
              boardId: board!.id,
              startInSelection: true,
            ),
    ),
  );
}

/// Board/kategorideki tüm fotoğrafları tek onayla galeriden kalıcı siler.
Future<void> _deleteAll(
  BuildContext context,
  WidgetRef ref,
  List<ScreenshotEntry> filtered,
) async {
  if (filtered.isEmpty) return;
  final l10n = context.l10n;
  final bool confirmed = await showConfirmSheet(
    context,
    title: l10n.categoryDeleteAllConfirmTitle(filtered.length),
    body: l10n.categoryDeleteAllConfirmBody,
    confirmLabel: l10n.categoryDeleteAllAction,
    icon: Icons.delete_sweep_outlined,
    destructive: true,
  );
  if (!confirmed || !context.mounted) return;

  final ScreenshotRepository repo = ref.read(screenshotRepositoryProvider);
  final List<String> ids = filtered.map((e) => e.assetId).toList();
  try {
    final List<String> deleted = await PhotoManager.editor.deleteWithIds(ids);
    for (final String assetId in deleted) {
      await repo.removeEntry(assetId);
    }
  } catch (error, stackTrace) {
    debugPrint('Düzenleme modu toplu silme hatası: $error\n$stackTrace');
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.bulkDeleteFailed)));
    }
  }
}

/// Özel board'u siler (içindeki fotoğraflar galeride kalır, bağ kaldırılır).
Future<void> _deleteBoard(
  BuildContext context,
  WidgetRef ref,
  Board board,
) async {
  final l10n = context.l10n;
  final bool confirmed = await showConfirmSheet(
    context,
    title: l10n.boardsDeleteConfirmTitle,
    body: l10n.boardsDeleteConfirmBody,
    confirmLabel: l10n.boardsDeleteAction,
    icon: Icons.delete_outline,
    destructive: true,
  );
  if (!confirmed) return;
  await ref.read(boardsProvider.notifier).delete(board.id);
}

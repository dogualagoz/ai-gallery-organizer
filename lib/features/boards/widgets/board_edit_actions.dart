// Pano/kategori yönetim eylemleri: düzenleme modu action sheet'i, karo bağlam
// menüsü ve detaydaki "…" menüsünün paylaştığı yeniden adlandır, yeniden analiz
// et, seç (toplu sil/taşı), tümünü sil ve panoyu sil işlemleri.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/l10n/category_labels.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/models/board.dart';
import '../../../core/models/screenshot_category.dart';
import '../../../core/models/screenshot_entry.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/category_names_service.dart';
import '../../../core/services/entitlement_service.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_menus.dart';
import '../../../core/widgets/status_toast.dart';
import '../../analysis/providers/analysis_queue_provider.dart';
import '../../gallery/data/screenshot_repository.dart';
import '../../gallery/providers/gallery_provider.dart';
import '../../paywall/open_paywall.dart';
import '../providers/board_provider.dart';

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
  final List<ScreenshotEntry> filtered = boardEntries(
    ref,
    board: board,
    category: category,
  );
  final Map<int, String> names = ref.read(categoryNamesProvider);
  final String title = category != null
      ? category.displayName(l10n, names)
      : board!.name;
  // Sistem kategorisinin özgün amacı: yeniden adlandırılsa da otomatik sıralama
  // buna göre çalışır; kullanıcı ne olduğunu unutmasın diye bilgi olarak durur.
  final String? subtitle = category != null
      ? l10n.categoryDefaultNameHint(category.label(l10n))
      : null;

  final _BoardEditAction? action = await showActionSheet<_BoardEditAction>(
    context,
    title: title,
    message: subtitle,
    actions: [
      SheetAction(
        label: category != null
            ? l10n.categoryRenameAction
            : l10n.boardsRenameAction,
        value: _BoardEditAction.rename,
      ),
      if (filtered.isNotEmpty)
        SheetAction(
          label: l10n.bulkSelectAction,
          value: _BoardEditAction.select,
        ),
      if (filtered.isNotEmpty)
        SheetAction(
          label: l10n.categoryDeleteAllAction,
          value: _BoardEditAction.deleteAll,
          destructive: true,
        ),
      if (board != null)
        SheetAction(
          label: l10n.boardsDeleteAction,
          value: _BoardEditAction.deleteBoard,
          destructive: true,
        ),
    ],
  );

  if (action == null || !context.mounted) return;
  switch (action) {
    case _BoardEditAction.rename:
      await renameBoard(context, ref, board: board, category: category);
    case _BoardEditAction.select:
      openBoardSelection(context, ref, board: board, category: category);
    case _BoardEditAction.deleteAll:
      await deleteAllInBoard(context, ref, filtered);
    case _BoardEditAction.deleteBoard:
      await deleteBoard(context, ref, board!);
  }
}

/// Bağlam menüsü ve detaydaki "…" menüsünün ortak eylem listesi. Build içinde
/// çağrılır (Pro durumunu izler). [onSelect] verilirse "Seç" eklenir; Pro
/// değilse kilit glifiyle görünür. [onLeave], panoyu geride bırakan
/// eylemlerden (pano silindi, yeniden analiz başladı) sonra çağrılır.
List<AppMenuAction> boardMenuActions(
  BuildContext context,
  WidgetRef ref, {
  required bool isEmpty,
  Board? board,
  ScreenshotCategory? category,
  VoidCallback? onSelect,
  VoidCallback? onLeave,
}) {
  final l10n = context.l10n;
  final bool canSelect = ref.watch(entitlementProvider).canBulkDelete;
  return [
    AppMenuAction(
      label: l10n.boardsRenameAction,
      icon: AppIcons.edit,
      onPressed: () =>
          renameBoard(context, ref, board: board, category: category),
    ),
    if (category != null && !isEmpty)
      AppMenuAction(
        label: l10n.categoryReanalyzeAction,
        icon: AppIcons.reanalyze,
        onPressed: () async {
          if (await reanalyzeCategory(context, ref, category)) onLeave?.call();
        },
      ),
    if (onSelect != null && !isEmpty)
      AppMenuAction(
        label: l10n.bulkSelectAction,
        icon: canSelect ? AppIcons.select : AppIcons.lock,
        onPressed: onSelect,
      ),
    if (board != null)
      AppMenuAction(
        label: l10n.boardsDeleteAction,
        icon: AppIcons.delete,
        destructive: true,
        onPressed: () async {
          if (await deleteBoard(context, ref, board)) onLeave?.call();
        },
      )
    else if (!isEmpty)
      AppMenuAction(
        label: l10n.categoryDeleteAllAction,
        icon: AppIcons.delete,
        destructive: true,
        onPressed: () => deleteAllInBoard(
          context,
          ref,
          boardEntries(ref, category: category),
        ),
      ),
  ];
}

/// [board] ya da [category] içindeki kayıtlar (galeri sırasıyla).
List<ScreenshotEntry> boardEntries(
  WidgetRef ref, {
  Board? board,
  ScreenshotCategory? category,
}) {
  final List<ScreenshotEntry> entries =
      ref.read(galleryProvider).value ?? const [];
  return category != null
      ? entries.where((entry) => entry.category == category).toList()
      : entries.where((entry) => entry.boardId == board!.id).toList();
}

/// Yeniden adlandırma: sistem kategorisinde ad override'ı, özel board'da isim.
Future<void> renameBoard(
  BuildContext context,
  WidgetRef ref, {
  Board? board,
  ScreenshotCategory? category,
}) async {
  final l10n = context.l10n;
  if (category != null) {
    final Map<int, String> names = ref.read(categoryNamesProvider);
    final String current = names[category.index] ?? category.label(l10n);
    final String? name = await showTextPrompt(
      context,
      title: l10n.categoryRenameDialogTitle,
      confirmLabel: l10n.categoryRenameAction,
      initialValue: current,
      placeholder: l10n.boardsNewBoardHint,
    );
    if (name == null || !context.mounted) return;
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

  final String? name = await showTextPrompt(
    context,
    title: l10n.boardsRenameDialogTitle,
    confirmLabel: l10n.boardsRenameAction,
    initialValue: board!.name,
    placeholder: l10n.boardsNewBoardHint,
  );
  if (name == null || !context.mounted) return;
  await ref.read(boardsProvider.notifier).rename(board.id, name);
}

/// Kategoriyi yeniden analiz eder: onaydan sonra kayıtları bekleyen yapıp
/// kuyruğu yalnız onlarla başlatır; animasyon Kütüphane'deki modülde oynar.
/// Ücretsizde haftalık kotadan, denemede deneme hakkından harcanır; onay metni
/// buna göre seçilir. Analiz başladıysa true.
Future<bool> reanalyzeCategory(
  BuildContext context,
  WidgetRef ref,
  ScreenshotCategory category,
) async {
  final l10n = context.l10n;
  final List<ScreenshotEntry> filtered = boardEntries(ref, category: category);
  if (filtered.isEmpty) return false;
  final EntitlementState entitlement = ref.read(entitlementProvider);
  final bool confirmed = await showConfirmAlert(
    context,
    title: l10n.categoryReanalyzeConfirmTitle,
    message: entitlement.isInTrialWindow
        ? l10n.categoryReanalyzeConfirmBodyTrial
        : entitlement.isPro
        ? l10n.categoryReanalyzeConfirmBodyPro
        : l10n.categoryReanalyzeConfirmBody,
    confirmLabel: l10n.categoryReanalyzeAction,
  );
  if (!confirmed || !context.mounted) return false;

  final ScreenshotRepository repo = ref.read(screenshotRepositoryProvider);
  final AnalysisQueueNotifier queue = ref.read(analysisQueueProvider.notifier);
  final List<String> ids = filtered.map((e) => e.assetId).toList();
  for (final String assetId in ids) {
    await repo.markPending(assetId);
  }
  queue.start(onlyAssetIds: ids);
  return true;
}

/// Board/kategori detayını doğrudan seçim modunda açar (toplu sil/taşı).
/// Toplu işlem Pro'ya bağlı; değilse paywall'a yönlendirir.
void openBoardSelection(
  BuildContext context,
  WidgetRef ref, {
  Board? board,
  ScreenshotCategory? category,
}) {
  if (!ref.read(entitlementProvider).canBulkDelete) {
    openPaywall(context);
    return;
  }
  context.push(
    category != null
        ? AppRoutes.category(category, select: true)
        : AppRoutes.board(board!.id, select: true),
  );
}

/// Board/kategorideki tüm fotoğrafları tek onayla galeriden kalıcı siler.
Future<void> deleteAllInBoard(
  BuildContext context,
  WidgetRef ref,
  List<ScreenshotEntry> filtered,
) async {
  if (filtered.isEmpty) return;
  final l10n = context.l10n;
  final bool confirmed = await showDestructiveConfirm(
    context,
    title: l10n.categoryDeleteAllConfirmTitle(filtered.length),
    message: l10n.categoryDeleteAllConfirmBody,
    confirmLabel: l10n.categoryDeleteAllAction,
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
    debugPrint('Pano toplu silme hatası: $error\n$stackTrace');
    if (context.mounted) {
      showStatusToast(
        context,
        l10n.bulkDeleteFailed,
        tone: StatusToastTone.error,
      );
    }
  }
}

/// Özel board'u siler (içindeki fotoğraflar galeride kalır, bağ kaldırılır).
/// Silindiyse true.
Future<bool> deleteBoard(
  BuildContext context,
  WidgetRef ref,
  Board board,
) async {
  final l10n = context.l10n;
  final bool confirmed = await showDestructiveConfirm(
    context,
    title: l10n.boardsDeleteConfirmTitle,
    message: l10n.boardsDeleteConfirmBody,
    confirmLabel: l10n.boardsDeleteAction,
  );
  if (!confirmed || !context.mounted) return false;
  await ref.read(boardsProvider.notifier).delete(board.id);
  return true;
}

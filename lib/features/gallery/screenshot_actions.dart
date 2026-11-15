// Ekran görüntüsü eylemleri: paylaş, taşı (geri alınabilir) ve sil. Izgara
// bağlam menüsü, seçim araç çubuğu ve görüntüleyici aynı yolu kullanır.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_icons.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/screenshot_category.dart';
import '../../core/services/haptic_service.dart';
import '../../core/utils/app_logger.dart';
import '../../core/widgets/status_toast.dart';
import 'data/screenshot_commands.dart';
import 'data/screenshot_repository.dart';
import 'widgets/move_target_sheet.dart';

/// Orijinal dosyaları iOS paylaşım sayfasıyla paylaşır. Paylaşım sayfası
/// (iPad'de) [context]'in kutusundan açılır. Hiçbir dosya alınamazsa hata
/// bildirimi gösterilir; bir kısmı alınamazsa kalanlar paylaşılır.
Future<void> shareScreenshots(
  BuildContext context,
  WidgetRef ref,
  List<String> assetIds,
) async {
  final String failure = context.l10n.detailShareFailed;
  final StatusToaster toaster = StatusToaster.of(context);
  final Rect? origin = _boundsOf(context);
  final ScreenshotRepository repo = ref.read(screenshotRepositoryProvider);

  final List<XFile> files = [];
  for (final String assetId in assetIds) {
    try {
      final File? file = await repo.assetFor(assetId)?.file;
      if (file != null) files.add(XFile(file.path));
    } catch (error, stackTrace) {
      logError('Paylaşım dosyası alınamadı ($assetId)', error, stackTrace);
    }
  }
  if (files.isEmpty) {
    toaster.show(failure, tone: StatusToastTone.error);
    return;
  }
  try {
    await SharePlus.instance.share(
      ShareParams(files: files, sharePositionOrigin: origin),
    );
  } catch (error, stackTrace) {
    logError('Paylaşım açılamadı', error, stackTrace);
    toaster.show(failure, tone: StatusToastTone.error);
  }
}

/// Hedef seçtirip taşır ve "Geri al"lı bildirim gösterir. [currentCategory] /
/// [currentBoardId] bulunulan yer; hedef listesinde gösterilmez. Taşındıysa
/// true (seçim modu kapanabilir).
Future<bool> moveScreenshots(
  BuildContext context,
  WidgetRef ref,
  List<String> assetIds, {
  ScreenshotCategory? currentCategory,
  String? currentBoardId,
}) async {
  final MoveTarget? target = await showMoveTargetSheet(
    context,
    currentCategory: currentCategory,
    currentBoardId: currentBoardId,
  );
  if (target == null || !context.mounted) return false;

  final l10n = context.l10n;
  final StatusToaster toaster = StatusToaster.of(context);
  final ScreenshotCommands commands = ref.read(screenshotCommandsProvider);
  final List<ScreenshotPlacement> before;
  try {
    before = await commands.move(
      assetIds,
      category: target.category,
      boardId: target.boardId,
    );
  } catch (error, stackTrace) {
    logError('Taşıma hatası', error, stackTrace);
    toaster.show(l10n.moveFailed, tone: StatusToastTone.error);
    return false;
  }

  Haptics.confirm();
  toaster.show(
    l10n.movedToast(target.label),
    tone: StatusToastTone.success,
    icon: AppIcons.move,
    actionLabel: l10n.undoAction,
    onAction: () async {
      try {
        await commands.undoMove(before);
      } catch (error, stackTrace) {
        logError('Taşıma geri alınamadı', error, stackTrace);
        toaster.show(l10n.undoFailed, tone: StatusToastTone.error);
      }
    },
  );
  return true;
}

/// Fotoğraf kütüphanesinden siler; onayı iOS'un kendi diyaloğu ister (ek
/// diyalog yok). Silinenlerin kimliklerini döndürür; boş = vazgeçildi ya da
/// başarısız (kısmi silmede yalnız silinenler).
Future<List<String>> deleteScreenshots(
  BuildContext context,
  WidgetRef ref,
  List<String> assetIds,
) async {
  final l10n = context.l10n;
  final String failure = assetIds.length == 1
      ? l10n.detailDeleteFailed
      : l10n.bulkDeleteFailed;
  final StatusToaster toaster = StatusToaster.of(context);
  try {
    return await ref.read(screenshotCommandsProvider).delete(assetIds);
  } catch (error, stackTrace) {
    logError('Silme hatası', error, stackTrace);
    toaster.show(failure, tone: StatusToastTone.error);
    return const [];
  }
}

/// Paylaşım sayfasının çıkış noktası: eylemi başlatan öğenin ekrandaki kutusu.
Rect? _boundsOf(BuildContext context) {
  final RenderObject? box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

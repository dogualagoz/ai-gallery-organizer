// Ekran görüntüsü eylemleri: paylaş, taşı (geri alınabilir) ve sil. Izgara
// bağlam menüsü, seçim araç çubuğu ve görüntüleyici aynı yolu kullanır.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_icons.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/screenshot_category.dart';
import '../../core/models/screenshot_entry.dart';
import '../../core/services/haptic_service.dart';
import '../../core/widgets/status_toast.dart';
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
      debugPrint('Paylaşım dosyası alınamadı ($assetId): $error\n$stackTrace');
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
    debugPrint('Paylaşım açılamadı: $error\n$stackTrace');
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
  final ScreenshotRepository repo = ref.read(screenshotRepositoryProvider);
  // Geri al için taşımadan önceki yerleşim saklanır.
  final List<ScreenshotPlacement> before = [
    for (final String assetId in assetIds)
      if (repo.entryFor(assetId) case final ScreenshotEntry entry)
        ScreenshotPlacement.of(entry),
  ];
  try {
    for (final String assetId in assetIds) {
      final ScreenshotCategory? category = target.category;
      if (category != null) {
        await repo.setCategory(assetId, category);
      } else {
        await repo.assignToBoard(assetId, target.boardId);
      }
    }
  } catch (error, stackTrace) {
    debugPrint('Taşıma hatası: $error\n$stackTrace');
    // Yarıda kalan taşıma geri sarılır: "taşınamadı" deyip bir kısmını
    // taşınmış bırakmayalım.
    await _undoMove(repo, before);
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
      if (!await _undoMove(repo, before)) {
        toaster.show(l10n.undoFailed, tone: StatusToastTone.error);
      }
    },
  );
  return true;
}

/// Kayıtları taşıma öncesi yerleşimlerine döndürür; başarılıysa true.
Future<bool> _undoMove(
  ScreenshotRepository repo,
  List<ScreenshotPlacement> before,
) async {
  try {
    for (final ScreenshotPlacement placement in before) {
      await repo.restorePlacement(placement);
    }
    return true;
  } catch (error, stackTrace) {
    debugPrint('Taşıma geri alınamadı: $error\n$stackTrace');
    return false;
  }
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
  final ScreenshotRepository repo = ref.read(screenshotRepositoryProvider);
  try {
    final List<String> deleted = await PhotoManager.editor.deleteWithIds(
      assetIds,
    );
    for (final String assetId in deleted) {
      await repo.removeEntry(assetId);
    }
    return deleted;
  } catch (error, stackTrace) {
    debugPrint('Silme hatası: $error\n$stackTrace');
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

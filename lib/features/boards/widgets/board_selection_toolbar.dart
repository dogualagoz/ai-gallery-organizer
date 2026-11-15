// Pano/kategori detayının seçim araç çubuğu: sekme çubuğunun yerinde durur,
// seçim sayısını gösterir; Paylaş / Taşı / Sil.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/models/screenshot_entry.dart';
import '../../../core/widgets/selection_toolbar.dart';
import '../../../core/widgets/spring_visibility.dart';
import '../board_selection.dart';

/// Seçim araç çubuğu; yalnız [visible] iken görünür (sekme çubuğuyla aynı
/// yaylı geçişle yer değiştirir). Seçim değişince yalnız bu çubuk yenilenir.
/// Stack'in doğrudan çocuğu olarak kullanılır.
class BoardSelectionToolbar extends StatelessWidget {
  const BoardSelectionToolbar({
    super.key,
    required this.visible,
    required this.busy,
    required this.entries,
    required this.selection,
    required this.onShare,
    required this.onMove,
    required this.onDelete,
  });

  final bool visible;

  /// Paylaşım hazırlanırken ya da silme onayı beklenirken true.
  final bool busy;
  final List<ScreenshotEntry> entries;
  final ValueListenable<Set<String>> selection;
  final ValueChanged<List<String>> onShare;
  final ValueChanged<List<String>> onMove;
  final ValueChanged<List<String>> onDelete;

  @override
  Widget build(BuildContext context) {
    // Kabuk Scaffold'u gövdeden cihaz alt boşluğunu çıkarır; sekme çubuğuyla
    // aynı hizaya oturmak için pencerenin kendi değeri okunur.
    final double deviceInset = MediaQueryData.fromView(View.of(context))
        .padding
        .bottom;
    return Positioned(
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      bottom: AppSizes.navBarBottomGap(deviceInset),
      child: SpringVisibility(
        visible: visible,
        child: ValueListenableBuilder<Set<String>>(
          valueListenable: selection,
          builder: (context, ids, _) =>
              _toolbar(context, selectedAssetIds(entries, ids)),
        ),
      ),
    );
  }

  Widget _toolbar(BuildContext context, List<String> selected) {
    final l10n = context.l10n;
    final bool none = selected.isEmpty;
    return SelectionToolbar(
      busy: busy,
      status: none
          ? l10n.selectItemsTitle
          : l10n.bulkSelectionCount(selected.length),
      leading: [
        ToolbarAction(
          icon: AppIcons.share,
          label: l10n.shareAction,
          onPressed: none ? null : () => onShare(selected),
        ),
      ],
      trailing: [
        ToolbarAction(
          icon: AppIcons.move,
          label: l10n.moveAction,
          onPressed: none ? null : () => onMove(selected),
        ),
        ToolbarAction(
          icon: AppIcons.delete,
          label: l10n.deleteAction,
          destructive: true,
          onPressed: none ? null : () => onDelete(selected),
        ),
      ],
    );
  }
}

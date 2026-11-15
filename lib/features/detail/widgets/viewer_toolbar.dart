// Görüntüleyicinin alt cam çubuğu: Paylaş / Bilgi / Taşı / Sil.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/widgets/glass_toolbar.dart';

/// Görüntüleyici araç çubuğu. Bilgi butonunun ikonu [infoOpen]'ı izler;
/// panel açılıp kapanınca yalnız bu çubuk yeniden kurulur.
class ViewerToolbar extends StatelessWidget {
  const ViewerToolbar({
    super.key,
    required this.infoOpen,
    required this.enabled,
    required this.onShare,
    required this.onInfo,
    required this.onMove,
    required this.onDelete,
  });

  final ValueListenable<bool> infoOpen;

  /// false iken (paylaşım hazırlanırken, silme onayı beklenirken) butonlar
  /// devre dışı.
  final bool enabled;
  final VoidCallback onShare;
  final VoidCallback onInfo;
  final VoidCallback onMove;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ValueListenableBuilder<bool>(
      valueListenable: infoOpen,
      builder: (context, infoOpen, _) {
        final List<ToolbarAction> actions = [
          ToolbarAction(
            icon: AppIcons.share,
            label: l10n.shareAction,
            onPressed: onShare,
          ),
          ToolbarAction(
            icon: infoOpen ? AppIcons.infoFill : AppIcons.info,
            label: l10n.infoAction,
            onPressed: onInfo,
          ),
          ToolbarAction(
            icon: AppIcons.move,
            label: l10n.moveAction,
            onPressed: onMove,
          ),
          ToolbarAction(
            icon: AppIcons.delete,
            label: l10n.deleteAction,
            destructive: true,
            onPressed: onDelete,
          ),
        ];
        return GlassToolbar(
          alignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final ToolbarAction action in actions)
              ToolbarButton(action: action, enabled: enabled),
          ],
        );
      },
    );
  }
}

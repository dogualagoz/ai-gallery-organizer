// Ortak iOS menüleri: karoya uzun basınca açılan bağlam menüsü ve gezinme
// barındaki "…" açılır menüsü aynı eylem tanımını paylaşır.
import 'package:flutter/cupertino.dart';

import '../constants/app_icons.dart';
import 'app_nav_scaffold.dart';

/// Menüdeki tek eylem. Yıkıcı eylemler listenin sonuna konur.
class AppMenuAction {
  const AppMenuAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool destructive;
}

/// Uzun basınca [child] büyüyerek öne çıkar, altında [actions] listelenir.
///
/// Önizleme çocuğu gevşek kısıtla ikinci kez kurar; çocuk bu yüzden hücre
/// ölçüsüne sabitlenir ve altında GlobalKey bulunmamalıdır. Seçilen eylem menü
/// kapanırken, çocuğun (hâlâ bağlı) context'iyle çalışır.
class AppContextMenu extends StatelessWidget {
  const AppContextMenu({super.key, required this.actions, required this.child});

  final List<AppMenuAction> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return child;
    return LayoutBuilder(
      builder: (_, constraints) => CupertinoContextMenu(
        enableHapticFeedback: true,
        actions: [
          for (final AppMenuAction action in actions)
            CupertinoContextMenuAction(
              trailingIcon: action.icon,
              isDestructiveAction: action.destructive,
              onPressed: () {
                // Menü kök navigator'da açılır; önce o kapanır.
                Navigator.of(context, rootNavigator: true).pop();
                action.onPressed();
              },
              child: Text(action.label),
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

/// Gezinme barındaki "…" butonu: dokununca butona bağlı açılır menü (iOS
/// pull-down). Yıkıcı eylemler ince bir ayırıcıyla ayrılır.
class AppMoreMenuButton extends StatelessWidget {
  const AppMoreMenuButton({
    super.key,
    required this.label,
    required this.actions,
  });

  /// Butonun VoiceOver etiketi.
  final String label;
  final List<AppMenuAction> actions;

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = [];
    // Yalnız yıkıcı eylem varsa ayırıcıya gerek yok.
    bool divided = actions.every((action) => action.destructive);
    for (final AppMenuAction action in actions) {
      if (action.destructive && !divided) {
        items.add(const CupertinoMenuDivider());
        divided = true;
      }
      items.add(
        CupertinoMenuItem(
          trailing: Icon(action.icon),
          isDestructiveAction: action.destructive,
          onPressed: action.onPressed,
          child: Text(action.label),
        ),
      );
    }
    return CupertinoMenuAnchor(
      // Menü uzunsa sekme çubuğunun altında kalmasın.
      useRootOverlay: true,
      menuChildren: items,
      builder: (context, controller, _) => NavBarButton.icon(
        icon: AppIcons.more,
        label: label,
        onPressed: actions.isEmpty
            ? null
            : () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

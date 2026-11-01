// Yüzen cam araç çubuğu parçaları: sekme çubuğuyla aynı ölçüde kapsül ve ikon
// eylem butonu. Seçim araç çubuğu ile görüntüleyici bunları paylaşır.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';
import 'glass_panel.dart';

/// Araç çubuğundaki tek ikon eylem; [label] VoiceOver'da okunur.
class ToolbarAction {
  const ToolbarAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });

  final IconData icon;
  final String label;

  /// null ise eylem pasif görünür (ör. hiçbir şey seçili değil).
  final VoidCallback? onPressed;
  final bool destructive;
}

/// Sekme çubuğuyla aynı yükseklikte cam kapsül; [children] yatayda dizilir.
/// Sabit yükseklikli olduğu için metin ölçeği sınırlanır.
class GlassToolbar extends StatelessWidget {
  const GlassToolbar({
    super.key,
    required this.children,
    this.alignment = MainAxisAlignment.start,
  });

  final List<Widget> children;
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: AppSizes.navBarMaxTextScale,
      child: GlassPanel(
        borderRadius: BorderRadius.circular(AppSizes.navBarHeight / 2),
        child: SizedBox(
          height: AppSizes.navBarHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(mainAxisAlignment: alignment, children: children),
          ),
        ),
      ),
    );
  }
}

/// [GlassToolbar] içindeki 44pt ikon butonu: pasifken soluk, yıkıcıysa
/// kırmızı, değilse aksan renginde.
class ToolbarButton extends StatelessWidget {
  const ToolbarButton({super.key, required this.action, this.enabled = true});

  final ToolbarAction action;

  /// false ise eylem geçici olarak kilitlenir (ör. işlem sürüyor).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final VoidCallback? onPressed = enabled ? action.onPressed : null;
    final Color color = onPressed == null
        ? scheme.outline
        : action.destructive
        ? scheme.error
        : scheme.primary;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size.square(kMinInteractiveDimensionCupertino),
      onPressed: onPressed,
      child: Icon(
        action.icon,
        size: AppSizes.navBarIcon,
        color: color,
        semanticLabel: action.label,
      ),
    );
  }
}

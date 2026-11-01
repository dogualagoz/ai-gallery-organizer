// Seçim modunun yüzen cam araç çubuğu: sekme çubuğunun yerinde durur, solda
// ve sağda ikon eylemler, ortada seçim durumu (Fotoğraflar uygulaması deseni).
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

/// Sekme çubuğuyla aynı ölçüde cam kapsül. [busy] iken eylemler kilitlenir ve
/// ortadaki metnin yerine etkinlik göstergesi döner.
class SelectionToolbar extends StatelessWidget {
  const SelectionToolbar({
    super.key,
    required this.status,
    required this.leading,
    required this.trailing,
    this.busy = false,
  });

  /// Ortadaki durum metni (ör. "3 seçildi").
  final String status;
  final List<ToolbarAction> leading;
  final List<ToolbarAction> trailing;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    // Sekme çubuğu gibi sabit yükseklikli: metin ölçeği sınırlanır.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: AppSizes.navBarMaxTextScale,
      child: _panel(text),
    );
  }

  Widget _panel(TextTheme text) {
    return GlassPanel(
      borderRadius: BorderRadius.circular(AppSizes.navBarHeight / 2),
      child: SizedBox(
        height: AppSizes.navBarHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            children: [
              for (final ToolbarAction action in leading)
                _ToolbarButton(action: action, enabled: !busy),
              Expanded(
                child: busy
                    ? const CupertinoActivityIndicator()
                    : Semantics(
                        liveRegion: true,
                        child: Text(
                          status,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall,
                        ),
                      ),
              ),
              for (final ToolbarAction action in trailing)
                _ToolbarButton(action: action, enabled: !busy),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({required this.action, required this.enabled});

  final ToolbarAction action;
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

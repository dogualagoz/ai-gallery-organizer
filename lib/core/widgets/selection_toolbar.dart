// Seçim modunun yüzen cam araç çubuğu: sekme çubuğunun yerinde durur, solda
// ve sağda ikon eylemler, ortada seçim durumu (Fotoğraflar uygulaması deseni).
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'glass_toolbar.dart';

export 'glass_toolbar.dart' show ToolbarAction;

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
    return GlassToolbar(
      children: [
        for (final ToolbarAction action in leading)
          ToolbarButton(action: action, enabled: !busy),
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
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
        ),
        for (final ToolbarAction action in trailing)
          ToolbarButton(action: action, enabled: !busy),
      ],
    );
  }
}

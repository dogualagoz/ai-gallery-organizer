// Üstten yaylı kayan cam durum kapsülü: SnackBar'ın iOS karşılığı. Geldiği
// yoldan (yukarı) çıkar; parmakla yukarı fırlatılarak da kapatılabilir.
import 'package:flutter/widgets.dart';

import 'status_toast_view.dart';

export 'status_toast_view.dart' show StatusToastTone;

/// Kök Overlay'e toast basan gösterici. `await` sonrası context geçersiz
/// kalabilecekse ([State.mounted] kontrolü gibi) await ÖNCESİ yakalanır:
/// `final toaster = StatusToaster.of(context);` → `toaster.show(...)`.
///
/// Toast kök Overlay'de yaşar, açan ekran kapansa da durur: ekran State'ine
/// dokunan `onAction` kendi içinde `mounted` kontrolü yapmalıdır.
class StatusToaster {
  StatusToaster.of(BuildContext context)
    : _overlay = Overlay.of(context, rootOverlay: true);

  final OverlayState _overlay;

  /// Aynı anda tek toast: yenisi gelince eskisi anında kalkar (üst üste
  /// iki cam kapsül okunmaz).
  static OverlayEntry? _current;

  /// [message]'ı gösterir. [actionLabel] + [onAction] verilirse sağda metin
  /// butonu çıkar (ör. "Geri al") ve süre uzar.
  void show(
    String message, {
    StatusToastTone tone = StatusToastTone.neutral,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    // Önce boşaltılır: eskisinin kapanış geri çağrısı kendini "güncel" sanıp
    // ikinci kez remove etmesin.
    final OverlayEntry? previous = _current;
    _current = null;
    previous?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => StatusToastView(
        message: message,
        tone: tone,
        icon: icon,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismissed: () {
          if (_current != entry) return;
          _current = null;
          entry.remove();
        },
      ),
    );
    _current = entry;
    _overlay.insert(entry);
  }
}

/// Tek seferlik kısayol: context hâlâ geçerliyken çağrılır.
void showStatusToast(
  BuildContext context,
  String message, {
  StatusToastTone tone = StatusToastTone.neutral,
  IconData? icon,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  StatusToaster.of(context).show(
    message,
    tone: tone,
    icon: icon,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}

// Tek tip iOS diyalogları: seçenekler action sheet, onaylar alert, metin
// girişi alert + text field. Hepsi kök navigator'da (sekme çubuğunun üstünde).
import 'package:flutter/cupertino.dart';

import '../constants/ui_constants.dart';
import '../l10n/l10n_extension.dart';

/// Action sheet'teki tek seçenek.
class SheetAction<T> {
  const SheetAction({
    required this.label,
    required this.value,
    this.destructive = false,
  });

  final String label;
  final T value;

  /// true ise kırmızı (geri alınamaz işlem) gösterilir.
  final bool destructive;
}

/// Seçenek listesini alttan action sheet olarak açar. Seçilenin değeri; iptal
/// ya da dışarı dokunmada null döner. "İptal" her zaman ayrı en altta durur.
Future<T?> showActionSheet<T>(
  BuildContext context, {
  required List<SheetAction<T>> actions,
  String? title,
  String? message,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    builder: (sheetContext) => CupertinoActionSheet(
      title: title == null ? null : Text(title),
      message: message == null ? null : Text(message),
      actions: [
        for (final SheetAction<T> action in actions)
          CupertinoActionSheetAction(
            isDestructiveAction: action.destructive,
            onPressed: () => Navigator.of(sheetContext).pop(action.value),
            child: Text(action.label),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.of(sheetContext).pop(),
        child: Text(sheetContext.l10n.cancelAction),
      ),
    ),
  );
}

/// Geri alınamaz işlem onayı (HIG: tetikleyen yerden açılan action sheet +
/// kırmızı eylem). Onaylanırsa true.
Future<bool> showDestructiveConfirm(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String? message,
}) async {
  final bool? confirmed = await showActionSheet<bool>(
    context,
    title: title,
    message: message,
    actions: [SheetAction(label: confirmLabel, value: true, destructive: true)],
  );
  return confirmed ?? false;
}

/// İki seçenekli uyarı (ör. "Pro'ya geç / Şimdi değil"). Onaylanırsa true;
/// [cancelLabel] verilmezse "İptal".
Future<bool> showConfirmAlert(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String? message,
  String? cancelLabel,
}) async {
  final bool? confirmed = await showCupertinoDialog<bool>(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel ?? dialogContext.l10n.cancelAction),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Tek satır metin isteyen uyarı (pano adı vb.). Kırpılmış metni döndürür;
/// iptalde null. Metin boşken onay butonu pasiftir.
Future<String?> showTextPrompt(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String initialValue = '',
  String? placeholder,
  String? message,
}) {
  return showCupertinoDialog<String>(
    context: context,
    builder: (_) => _TextPromptDialog(
      title: title,
      confirmLabel: confirmLabel,
      initialValue: initialValue,
      placeholder: placeholder,
      message: message,
    ),
  );
}

/// Controller widget'ın kendi State'ine bağlı — Navigator'ın dispose sırasını
/// elle yönetmekten doğan "controller used after disposed" hatasını önler.
class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.confirmLabel,
    required this.initialValue,
    this.placeholder,
    this.message,
  });

  final String title;
  final String confirmLabel;
  final String initialValue;
  final String? placeholder;
  final String? message;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final String value = _controller.text.trim();
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.message != null) Text(widget.message!),
          const SizedBox(height: AppSpacing.md),
          CupertinoTextField(
            controller: _controller,
            autofocus: true,
            placeholder: widget.placeholder,
            textCapitalization: TextCapitalization.sentences,
            clearButtonMode: OverlayVisibilityMode.editing,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancelAction),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, _) => CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: value.text.trim().isEmpty ? null : _submit,
            child: Text(widget.confirmLabel),
          ),
        ),
      ],
    );
  }
}

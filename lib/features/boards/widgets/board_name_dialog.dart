// Pano adı giren diyalog (oluşturma/yeniden adlandırma ortak): controller
// widget'ın kendi State'ine bağlı — Navigator'ın dispose sırasını manuel
// yönetmekten kaynaklanan "controller used after disposed" hatasını önler.
import 'package:flutter/material.dart';

import '../../../core/l10n/l10n_extension.dart';

class BoardNameDialog extends StatefulWidget {
  const BoardNameDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    this.initialValue = '',
  });

  final String title;
  final String confirmLabel;
  final String initialValue;

  @override
  State<BoardNameDialog> createState() => _BoardNameDialogState();
}

class _BoardNameDialogState extends State<BoardNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: l10n.boardsNewBoardHint),
        onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelAction),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

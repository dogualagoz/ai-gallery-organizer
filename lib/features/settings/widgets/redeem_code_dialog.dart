// Redeem kodu giren diyalog: controller widget'ın kendi State'inde yönetilir
// ("controller used after disposed" yarışını önlemek için — [BoardNameDialog]
// ile aynı desen). Onayda kodu doğrular, sonucu (RedeemOutcome) döndürür.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/redeem_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/services/entitlement_service.dart';

/// Redeem kodu diyalogu — kapanırken [RedeemOutcome] ile pop eder (iptalde null).
class RedeemCodeDialog extends ConsumerStatefulWidget {
  const RedeemCodeDialog({super.key});

  @override
  ConsumerState<RedeemCodeDialog> createState() => _RedeemCodeDialogState();
}

class _RedeemCodeDialogState extends ConsumerState<RedeemCodeDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String code = _controller.text.trim();
    if (code.isEmpty || _busy) return;
    setState(() => _busy = true);
    final RedeemOutcome outcome =
        await ref.read(entitlementProvider.notifier).redeemCode(code);
    if (!mounted) return;
    Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.redeemTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        enabled: !_busy,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(hintText: l10n.redeemHint),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancelAction),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(l10n.redeemConfirm),
        ),
      ],
    );
  }
}

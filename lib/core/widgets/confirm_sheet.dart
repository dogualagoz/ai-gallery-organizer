// Tek belirgin aksiyonlu onay bottom sheet'i: AlertDialog'un buton yığılması
// sorununu bitirir. Onaylanırsa true döner; iptal/dışarı dokunma false.
import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';
import '../l10n/l10n_extension.dart';

/// Onay sheet'ini açar. [destructive] true ise onay butonu hata (kırmızı) rengi.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  IconData? icon,
  bool destructive = false,
}) async {
  final bool? result = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (_) => _ConfirmSheet(
      title: title,
      body: body,
      confirmLabel: confirmLabel,
      icon: icon,
      destructive: destructive,
    ),
  );
  return result ?? false;
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.destructive,
    this.icon,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final bool destructive;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color accent = destructive ? scheme.error : scheme.primary;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (icon != null) ...[
              Icon(icon, color: accent, size: 32),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                    )
                  : null,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancelAction),
            ),
          ],
        ),
      ),
    );
  }
}

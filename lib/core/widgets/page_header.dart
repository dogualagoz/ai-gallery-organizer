// Sayfa içine gömülü iOS-tarzı büyük başlık: AppBar yerine kullanılır.
// Üstte (opsiyonel) geri + aksiyon satırı, altında büyük başlık (+ yan rozet).
import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';

/// Ana ekranların üstünde AppBar yerine geçen gömülü başlık bloğu.
/// Status bar boşluğunu kendi ekler; scroll view'ın ilk elemanı olarak konur.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.leading,
    this.actions = const [],
    this.titleTrailing,
  });

  /// Büyük başlık metni.
  final String title;

  /// Sol üst öğe (ör. geri chevron). Yoksa aksiyon satırı yalnız sağa yaslanır.
  final Widget? leading;

  /// Sağ üstteki aksiyonlar (ikon butonlar vb.).
  final List<Widget> actions;

  /// Başlığın yanındaki küçük öğe (ör. Pro rozeti).
  final Widget? titleTrailing;

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.paddingOf(context).top;
    final bool hasActionRow = leading != null || actions.isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        topInset + AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasActionRow)
            Row(
              children: [
                ?leading,
                const Spacer(),
                ...actions,
              ],
            ),
          Padding(
            // Aksiyon satırı varsa başlık ona hafif yaklaşır; yoksa üstten pay.
            padding: EdgeInsets.only(
              top: hasActionRow ? AppSpacing.xs : AppSpacing.sm,
              right: AppSpacing.md,
            ),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (titleTrailing != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  titleTrailing!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

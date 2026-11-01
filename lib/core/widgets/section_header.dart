// Sayfa içi bölüm başlığı (iOS Title 3 düzeni): solda başlık, sağda
// opsiyonel metin eylemi (ör. "Düzenle", "Tümü", "Temizle").
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';

/// Bölüm başlığı: başlık metni + sağda opsiyonel 44pt metin eylemi.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final String? label = actionLabel;
    return SizedBox(
      height: kMinInteractiveDimensionCupertino,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (label != null)
            CupertinoButton(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              minimumSize: const Size.square(kMinInteractiveDimensionCupertino),
              onPressed: onAction,
              child: Text(label),
            ),
        ],
      ),
    );
  }
}

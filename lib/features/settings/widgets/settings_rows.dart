// Ayarlar'a özgü satırlar: dolgulu ikon karolu Pro durumu satırı ve bölüm
// içinde tam genişlikte duran kayan segment seçici.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/services/haptic_service.dart';

/// Pro durumu satırı: free'de paywall'a götüren teklif, Pro'da teşekkür ve
/// (denemedeyse) kalan hak. Alt yazı birkaç satıra sarılabilir.
class ProStatusTile extends StatelessWidget {
  const ProStatusTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final String title;
  final String subtitle;

  /// Verilirse satır dokunulabilir olur ve chevron alır.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return CupertinoListTile(
      leadingSize: AppSizes.settingsProTile,
      leading: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: SizedBox.square(
          dimension: AppSizes.settingsProTile,
          child: Icon(
            AppIcons.pro,
            size: AppSizes.settingsProGlyph,
            color: scheme.onPrimary,
          ),
        ),
      ),
      title: Text(title, style: TextStyle(color: scheme.onSurface)),
      // Liste satırı tek satıra kırpar; açıklama büyük metinde de okunsun.
      subtitle: Text(
        subtitle,
        maxLines: 3,
        style: TextStyle(color: scheme.onSurfaceVariant),
      ),
      trailing: onTap == null ? null : const CupertinoListTileChevron(),
      onTap: onTap,
      backgroundColorActivated: scheme.surfaceContainerHigh,
    );
  }
}

/// Bölüm kartı içinde tam genişlikte [CupertinoSlidingSegmentedControl].
/// Aynı değere yeniden dokunmak bir şey yapmaz; değişimde seçim tıkı verir.
class SegmentedRow<T extends Object> extends StatelessWidget {
  const SegmentedRow({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;

  /// Seçenekler ve etiketleri, gösterim sırasıyla.
  final Map<T, String> options;

  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl<T>(
          groupValue: value,
          children: {
            for (final MapEntry<T, String> option in options.entries)
              option.key: Text(
                option.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          },
          onValueChanged: (next) {
            if (next == null || next == value) return;
            Haptics.tap();
            onChanged(next);
          },
        ),
      ),
    );
  }
}

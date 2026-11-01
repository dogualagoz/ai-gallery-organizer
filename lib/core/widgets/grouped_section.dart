// iOS Ayarlar tarzı inset-grouped liste bölümü ve satırı (chevron, değer,
// yıkıcı stil) — renkler colorScheme'den gelir.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Yuvarlatılmış kart içinde gruplanmış satırlar; üstte başlık, altta
/// açıklayıcı dipnot. Satırların ikonu varsa ayırıcılar metinden başlar.
class GroupedSection extends StatelessWidget {
  const GroupedSection({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.margin,
  });

  final List<Widget> children;
  final String? header;

  /// Kartın dış boşluğu; verilmezse iOS varsayılanı. Sayfa içi bölüm
  /// başlığıyla hizalamak için verilir.
  final EdgeInsetsGeometry? margin;

  /// Bölüm altındaki açıklama (uzun bilgi satıra değil buraya yazılır).
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String? headerText = header;
    final String? footerText = footer;
    return CupertinoListSection.insetGrouped(
      backgroundColor: scheme.surfaceContainer,
      decoration: BoxDecoration(color: scheme.surface),
      separatorColor: scheme.outlineVariant,
      hasLeading: children.any(
        (child) => child is GroupedRow && child.icon != null,
      ),
      header: headerText == null ? null : Text(headerText),
      footer: footerText == null ? null : Text(footerText),
      margin: margin,
      children: children,
    );
  }
}

/// [GroupedSection] satırı. [onTap] varsa ve sağda başka öğe yoksa chevron
/// gösterilir; [destructive] satır kırmızıdır ve chevron almaz.
class GroupedRow extends StatelessWidget {
  const GroupedRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.value,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.showChevron,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  /// Sağda gri mevcut değer (ör. seçili dil).
  final String? value;

  /// Sağdaki özel öğe (ör. CupertinoSwitch); chevron'un yerini alır.
  final Widget? trailing;

  final VoidCallback? onTap;
  final bool destructive;

  /// Otomatik chevron kararını ezer.
  final bool? showChevron;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String? subtitleText = subtitle;
    final String? valueText = value;
    final bool chevron =
        showChevron ?? (onTap != null && trailing == null && !destructive);

    return CupertinoListTile(
      leading: icon == null
          ? null
          : Icon(icon, color: destructive ? scheme.error : scheme.primary),
      title: Text(
        title,
        style: TextStyle(color: destructive ? scheme.error : scheme.onSurface),
      ),
      subtitle: subtitleText == null
          ? null
          : Text(
              subtitleText,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
      additionalInfo: valueText == null
          ? null
          : Text(valueText, style: TextStyle(color: scheme.onSurfaceVariant)),
      trailing: trailing ?? (chevron ? const CupertinoListTileChevron() : null),
      onTap: onTap,
      backgroundColorActivated: scheme.surfaceContainerHigh,
    );
  }
}

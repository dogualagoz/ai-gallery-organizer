// iOS büyük başlıklı sayfa iskeleti: kaydırınca 34pt başlık inline başlığa
// küçülür, içerik yarı saydam bulanık barın altından akar.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';
import '../services/haptic_service.dart';

/// Ekran iskeleti: [CupertinoSliverNavigationBar] + içerik sliver'ları.
///
/// Bar, içerik altına girene kadar zeminle aynı renkte ve kenarlıksızdır;
/// içerik altına girince bulanık malzemeye ve ince ayırıcıya geçer (iOS
/// scroll edge davranışı). Gezinilebilir rotada geri chevron'u kendisi koyar.
/// Alt boşluk yüzen sekme çubuğunu ve home indicator'ı hesaba katar.
class AppNavScaffold extends StatelessWidget {
  const AppNavScaffold({
    super.key,
    required this.title,
    required this.slivers,
    this.titleTrailing,
    this.leading,
    this.trailing,
    this.onRefresh,
    this.controller,
  });

  /// Büyük başlık; küçülünce barın ortasında aynı metin görünür.
  final String title;

  /// Başlığın altındaki içerik.
  final List<Widget> slivers;

  /// Yalnız büyük başlığın yanında duran küçük öğe (ör. Pro rozeti).
  final Widget? titleTrailing;

  /// Sol üst öğe; null ise rota geri gidebiliyorsa chevron otomatik gelir.
  final Widget? leading;

  /// Sağ üst aksiyonlar (genelde [NavBarButton]'lardan bir Row).
  final Widget? trailing;

  /// Verilirse büyük başlığın altında aşağı çekip yenileme açılır.
  final Future<void> Function()? onRefresh;

  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    final Future<void> Function()? refresh = onRefresh;

    return Scaffold(
      // Bar bu rengi "içerik altında değilken" zemini olarak kullanır.
      body: CupertinoPageScaffoldBackgroundColor(
        color: scheme.surfaceContainer,
        child: CustomScrollView(
          controller: controller,
          // Kısa içerikte de büyük başlık küçülebilsin ve yenileme çekilebilsin.
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: _largeTitle(),
              middle: Text(title),
              alwaysShowMiddle: false,
              leading: leading,
              trailing: trailing,
              backgroundColor: scheme.surfaceContainer.withValues(
                alpha: AppGlass.navBarFillAlpha,
              ),
              border: Border(
                bottom: BorderSide(color: scheme.outlineVariant, width: 0),
              ),
              // Sekme dallarının her biri ayrı navigator; kök rota geçişinde
              // aynı varsayılan hero tag'li birden çok bar çakışırdı.
              transitionBetweenRoutes: false,
            ),
            if (refresh != null)
              CupertinoSliverRefreshControl(
                onRefresh: () {
                  // Haptic yenilemenin tetiklendiği karede (görselle uyumlu).
                  Haptics.tick();
                  return refresh();
                },
              ),
            ...slivers,
            SliverToBoxAdapter(
              child: SizedBox(height: bottomInset + AppSpacing.md),
            ),
          ],
        ),
      ),
    );
  }

  Widget _largeTitle() {
    final Widget text = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final Widget? badge = titleTrailing;
    if (badge == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: text),
        const SizedBox(width: AppSpacing.sm),
        badge,
      ],
    );
  }
}

/// Gezinme barı butonu: ikon ya da metin, 44pt dokunma alanı, iOS basış
/// opaklığı. İkon butonunda [label] VoiceOver etiketi olarak okunur.
class NavBarButton extends StatelessWidget {
  const NavBarButton.icon({
    super.key,
    required IconData this.icon,
    required this.label,
    required this.onPressed,
  });

  const NavBarButton.text({
    super.key,
    required this.label,
    required this.onPressed,
  }) : icon = null;

  final IconData? icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final IconData? glyph = icon;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size.square(kMinInteractiveDimensionCupertino),
      onPressed: onPressed,
      child: glyph == null ? Text(label) : Icon(glyph, semanticLabel: label),
    );
  }
}

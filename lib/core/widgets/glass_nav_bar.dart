// Yüzen buzlu-cam (glassmorphism) alt gezinme pili: parlak yarı-opak kapsül,
// seçili sekmeyi camın üstünde duran düz tonlu bir kapsül gösterir, sekmeler
// arası akıcı kayar ve parmakla yatay sürüklemeyi birebir takip eder.
import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';
import '../services/haptic_service.dart';
import 'glass_panel.dart';

/// Sekmeye basılıyken uygulanan çok hafif küçülme (dokunma geri bildirimi).
/// iOS'ta dokunmada bileşen neredeyse yer değiştirmez — düşük tutulur.
const double _navItemPressScale = 0.95;

/// Kayan seçim göstergesinin yerleşme eğrisi: hafif "settle" yapar, easeOutBack
/// gibi çizgi film taşması vermez (iOS tab bar göstergesi hissi).
const Cubic _indicatorSettleCurve = Cubic(0.33, 1.12, 0.66, 1);

/// [GlassNavBar] içindeki tek sekme tanımı.
class GlassNavDestination {
  const GlassNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Yüzen buzlu-cam gezinme pili. Scaffold'a `extendBody: true` ile verilmelidir;
/// içerik çubuğun arkasından akar ve [GlassPanel]'in BackdropFilter'ı onu
/// bulanıklaştırarak frosted etkiyi görünür kılar. Dokunmanın yanı sıra parmakla
/// yatay kaydırarak sekme değiştirmeyi de destekler.
class GlassNavBar extends StatefulWidget {
  const GlassNavBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<GlassNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  State<GlassNavBar> createState() => _GlassNavBarState();
}

class _GlassNavBarState extends State<GlassNavBar> {
  /// Sürükleme sırasında göstergenin sürekli (kesirli) konumu; parmağı birebir
  /// takip eder. Sürükleme yoksa null → gösterge seçili sekmeye yaslanır.
  double? _dragPos;

  /// Parmağın x konumunu 0..(count-1) aralığında kesirli sekme konumuna çevirir.
  double _posForDx(double dx, double width) {
    final int count = widget.destinations.length;
    final double itemWidth = width / count;
    return (dx / itemWidth - 0.5).clamp(0.0, (count - 1).toDouble());
  }

  void _handleDragUpdate(DragUpdateDetails details, double width) {
    final double pos = _posForDx(details.localPosition.dx, width);
    final int prevNearest = (_dragPos ?? widget.selectedIndex.toDouble())
        .round();
    // Yeni bir sekmenin üzerine gelince hafif haptik; sekme değişimi bırakınca.
    if (pos.round() != prevNearest) Haptics.tap();
    setState(() => _dragPos = pos);
  }

  void _handleDragEnd() {
    final int target = (_dragPos ?? widget.selectedIndex.toDouble()).round();
    setState(() => _dragPos = null);
    if (target != widget.selectedIndex) widget.onSelected(target);
  }

  @override
  Widget build(BuildContext context) {
    // Dış boşluk paylaşılan tek bir inset olarak _MainShell'de uygulanıyor
    // (pil + ayrık aksiyon butonu aynı hizada yüzsün diye).
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) =>
            setState(() => _dragPos = widget.selectedIndex.toDouble()),
        onHorizontalDragUpdate: (details) =>
            _handleDragUpdate(details, constraints.maxWidth),
        onHorizontalDragEnd: (_) => _handleDragEnd(),
        onHorizontalDragCancel: () => setState(() => _dragPos = null),
        child: _buildPill(context),
      ),
    );
  }

  Widget _buildPill(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double radius = AppSizes.navBarHeight / 2;
    final int count = widget.destinations.length;
    final double pos = _dragPos ?? widget.selectedIndex.toDouble();
    final double x = count == 1 ? 0 : -1 + (2 * pos / (count - 1));

    return GlassPanel(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: AppSizes.navBarHeight,
        child: Stack(
          children: [
            // Kayan seçim göstergesi — düz tonlu kapsül, camın üstünde.
            _dragPos == null
                ? AnimatedAlign(
                    duration: AppDurations.medium,
                    curve: _indicatorSettleCurve,
                    alignment: Alignment(x, 0),
                    child: _indicator(scheme, count),
                  )
                : Align(
                    // Sürüklerken parmağı anında izler (animasyonsuz).
                    alignment: Alignment(x, 0),
                    child: _indicator(scheme, count),
                  ),
            Row(
              children: [
                for (int i = 0; i < count; i++)
                  Expanded(
                    child: _NavItem(
                      destination: widget.destinations[i],
                      selected: i == widget.selectedIndex,
                      onTap: () {
                        Haptics.tap();
                        widget.onSelected(i);
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Seçili sekmeyi saran düz, hafif primary tonlu kapsül (seçim göstergesi).
  Widget _indicator(ColorScheme scheme, int count) {
    return FractionallySizedBox(
      widthFactor: 1 / count,
      heightFactor: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: AppGlass.indicatorTint),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
    );
  }
}

/// İkon + etiketten oluşan tek sekme düğmesi. Basılıyken hafifçe küçülür;
/// seçilince renk primary olur ve ikon dolgulu türüne geçer.
class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final GlassNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    // Referans tab bar yüksek kontrastlı: seçili değilken de neredeyse tam koyu.
    final Color color = widget.selected
        ? scheme.primary
        : scheme.onSurface.withValues(alpha: 0.85);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? _navItemPressScale : 1.0,
        duration: AppDurations.fast,
        curve: Curves.easeOut,
        child: Semantics(
          selected: widget.selected,
          button: true,
          label: widget.destination.label,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: AppDurations.fast,
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: Icon(
                  widget.selected
                      ? widget.destination.selectedIcon
                      : widget.destination.icon,
                  key: ValueKey(widget.selected),
                  color: color,
                  size: AppSizes.navBarIcon,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.destination.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: widget.selected
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

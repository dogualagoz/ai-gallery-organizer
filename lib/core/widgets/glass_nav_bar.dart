// iOS tarzı yüzen buzlu-cam (glassmorphism) alt gezinme çubuğu; seçim kayarak
// taşınır ve parmak sürüklemesini takip eder.
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';
import '../services/haptic_service.dart';

/// Sekmeye basılıyken uygulanan hafif küçülme (dokunma geri bildirimi).
const double _navItemPressScale = 0.9;

/// Seçili sekme ikonunun kısa "pop" büyümesi.
const double _navItemSelectedScale = 1.14;

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

/// Yüzen buzlu-cam (glassmorphism) gezinme pili. Scaffold'a `extendBody: true`
/// ile verilmelidir; içerik çubuğun arkasından akar ve [GlassSurface]'in
/// BackdropFilter'ı onu bulanıklaştırarak frosted etkiyi görünür kılar.
/// Dokunmanın yanı sıra parmakla yatay kaydırarak sekme değiştirmeyi de destekler.
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
    // Dış boşluk artık paylaşılan tek bir inset olarak _MainShell'de
    // uygulanıyor (pil + ayrık aksiyon butonu aynı hizada yüzsün diye).
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) =>
            setState(() => _dragPos = widget.selectedIndex.toDouble()),
        onHorizontalDragUpdate: (details) =>
            _handleDragUpdate(details, constraints.maxWidth),
        onHorizontalDragEnd: (_) => _handleDragEnd(),
        onHorizontalDragCancel: () => setState(() => _dragPos = null),
        child: _buildGlassPill(context),
      ),
    );
  }

  Widget _buildGlassPill(BuildContext context) {
    final double radius = AppSizes.navBarHeight / 2;
    return GlassSurface(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: AppSizes.navBarHeight,
        child: Stack(
          children: [
            _SlidingIndicator(
              itemCount: widget.destinations.length,
              position: _dragPos ?? widget.selectedIndex.toDouble(),
              // Sürüklerken parmağı anında izle; bırakınca yaylanarak yaslan.
              animated: _dragPos == null,
            ),
            Row(
              children: [
                for (int i = 0; i < widget.destinations.length; i++)
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
}

/// Yeniden kullanılabilir buzlu-cam yüzey: arka planı BackdropFilter ile
/// bulanıklaştırır, üzerine yarı saydam tema tonu + ince kenar vurgusu + yumuşak
/// gölge koyar. Navbar pili ve ayrık aksiyon butonu ortak bu yüzeyi kullanır.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.borderRadius,
    required this.child,
  });

  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: scheme.inverseSurface.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppGlass.backdropSigma,
            sigmaY: AppGlass.backdropSigma,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              // Yarı saydam yüzey tonu (açıkta beyazımsı, koyuda koyu frosted).
              color: scheme.surface.withValues(alpha: AppGlass.tintAlpha),
              borderRadius: borderRadius,
              border: Border.all(
                color: scheme.onSurface.withValues(alpha: AppGlass.edgeAlpha),
                width: 0.6,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Seçili sekmenin arkasında kayan vurgu hapı. Sürüklerken [position] kesirli
/// olur ve gösterge parmağı birebir izler ([animated] false); bırakınca
/// [animated] true ile en yakın sekmeye yaylanarak yaslanır.
class _SlidingIndicator extends StatelessWidget {
  const _SlidingIndicator({
    required this.itemCount,
    required this.position,
    required this.animated,
  });

  final int itemCount;
  final double position;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    // Alignment -1..1 aralığında: verilen (kesirli) sekme konumuna denk gelir.
    final double x = itemCount == 1 ? 0 : -1 + (2 * position / (itemCount - 1));
    final Alignment alignment = Alignment(x, 0);

    final Widget pill = FractionallySizedBox(
      widthFactor: 1 / itemCount,
      heightFactor: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs + 2),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      ),
    );

    return animated
        ? AnimatedAlign(
            duration: AppDurations.medium,
            // Yaylı eğri: gösterge hedefe hafif "yaylanarak" oturur.
            curve: Curves.easeOutBack,
            alignment: alignment,
            child: pill,
          )
        : Align(alignment: alignment, child: pill);
  }
}

/// İkon + etiketten oluşan tek sekme düğmesi. Basılıyken hafifçe küçülür,
/// seçilince ikon kısa bir "pop" ile büyür — çubuğa canlılık katar.
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
    final Color color = widget.selected
        ? scheme.primary
        : scheme.onSurfaceVariant;

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
              AnimatedScale(
                scale: widget.selected ? _navItemSelectedScale : 1.0,
                duration: AppDurations.medium,
                curve: Curves.easeOutBack,
                child: AnimatedSwitcher(
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

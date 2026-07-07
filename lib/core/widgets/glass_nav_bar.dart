// iOS 26 liquid glass yüzen alt gezinme çubuğu; seçim kayarak taşınır.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../constants/ui_constants.dart';

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

/// Modern iOS 26 dilinde yüzen, gerçek shader tabanlı liquid glass pil.
/// Scaffold'a `extendBody: true` ile birlikte verilmelidir; içerik
/// çubuğun arkasından akar ve kırılma/parlama efekti görünür olur.
/// Bir ata `LiquidGlassLayer` + `LiquidGlassBlendGroup` içinde
/// kullanılmalıdır (bkz. `_MainShell`) — cam ayarları oradan miras alınır.
/// Dokunmanın yanı sıra parmakla yatay kaydırarak sekme değiştirmeyi de
/// destekler (iOS 26 liquid glass tab bar davranışı).
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
  int? _dragIndex;

  int _indexForDx(double dx, double width) {
    final double itemWidth = width / widget.destinations.length;
    return (dx / itemWidth).floor().clamp(0, widget.destinations.length - 1);
  }

  void _handleDragUpdate(DragUpdateDetails details, double width) {
    final int index = _indexForDx(details.localPosition.dx, width);
    if (index == (_dragIndex ?? widget.selectedIndex)) return;
    _dragIndex = index;
    HapticFeedback.selectionClick();
    widget.onSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    // Dış boşluk artık paylaşılan tek bir inset olarak _MainShell'de
    // uygulanıyor (pil + ayrık aksiyon butonu aynı hizada yüzsün diye).
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) => _dragIndex = widget.selectedIndex,
        onHorizontalDragUpdate: (details) =>
            _handleDragUpdate(details, constraints.maxWidth),
        onHorizontalDragEnd: (_) => _dragIndex = null,
        child: _buildGlassPill(context),
      ),
    );
  }

  /// Kurulu paket sürümünde `shadows` parametresi henüz yok; gölge dıştan
  /// sarmalanan bir DecoratedBox ile veriliyor.
  Widget _buildGlassPill(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.navBarHeight / 2),
        boxShadow: [
          BoxShadow(
            color: scheme.inverseSurface.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LiquidGlass.grouped(
        shape: LiquidRoundedSuperellipse(
          borderRadius: AppSizes.navBarHeight / 2,
        ),
        child: SizedBox(
          height: AppSizes.navBarHeight,
          child: Stack(
            children: [
              _SlidingIndicator(
                itemCount: widget.destinations.length,
                selectedIndex: widget.selectedIndex,
              ),
              Row(
                children: [
                  for (int i = 0; i < widget.destinations.length; i++)
                    Expanded(
                      child: _NavItem(
                        destination: widget.destinations[i],
                        selected: i == widget.selectedIndex,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          widget.onSelected(i);
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Seçili sekmenin arkasında kayarak hareket eden vurgu hapı.
class _SlidingIndicator extends StatelessWidget {
  const _SlidingIndicator({
    required this.itemCount,
    required this.selectedIndex,
  });

  final int itemCount;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    // Alignment -1..1 aralığında: i. sekmenin merkezine denk gelir.
    final double x = itemCount == 1
        ? 0
        : -1 + (2 * selectedIndex / (itemCount - 1));

    return AnimatedAlign(
      duration: AppDurations.medium,
      curve: Curves.easeOutCubic,
      alignment: Alignment(x, 0),
      child: FractionallySizedBox(
        widthFactor: 1 / itemCount,
        heightFactor: 1,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs + 2),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        ),
      ),
    );
  }
}

/// İkon + etiketten oluşan tek sekme düğmesi.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final GlassNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = selected ? scheme.primary : scheme.onSurfaceVariant;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Semantics(
        selected: selected,
        button: true,
        label: destination.label,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: AppDurations.fast,
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: Icon(
                selected ? destination.selectedIcon : destination.icon,
                key: ValueKey(selected),
                color: color,
                size: AppSizes.navBarIcon,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              destination.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

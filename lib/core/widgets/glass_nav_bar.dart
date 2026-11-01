// Yüzen buzlu-cam sekme pili: seçili sekmeyi camın üstündeki tonlu kapsül
// gösterir. Gösterge yayla sürülür, sürüklemeyi 1:1 izler, bırakınca parmağın
// hızını devralır ve uçlarda lastik gibi direnir.
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../constants/motion_constants.dart';
import '../constants/ui_constants.dart';
import '../services/haptic_service.dart';
import '../utils/motion_physics.dart';
import 'glass_panel.dart';
import 'pressable.dart';

/// [GlassNavBar] içindeki tek sekme tanımı.
class GlassNavDestination {
  const GlassNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount = 0,
    this.badgeLabel,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// 0'dan büyükse ikonun sağ üstünde kırmızı sayı rozeti (iOS tab badge).
  final int badgeCount;

  /// Rozetin VoiceOver karşılığı (ör. "3 silinecek").
  final String? badgeLabel;
}

/// Yüzen buzlu-cam sekme pili. Scaffold'a `extendBody: true` ile verilmelidir;
/// içerik çubuğun arkasından akar ve [GlassPanel] onu bulanıklaştırır.
///
/// [selectedIndex] pil dışında bir değerse (ör. ayrık Ara sekmesi seçili)
/// gösterge gizlenir ve son pil sekmesinde bekler. Sekme dokunarak ya da pil
/// üzerinde yatay sürükleyerek değişir; gösterge her yeni sekmenin üstüne
/// geçtiğinde seçim haptiği verilir.
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

class _GlassNavBarState extends State<GlassNavBar>
    with SingleTickerProviderStateMixin {
  /// Göstergenin yaslandığı (son seçilen) pil sekmesi.
  late int _restIndex = _inPill(widget.selectedIndex)
      ? widget.selectedIndex
      : 0;

  /// Göstergenin sekme birimindeki konumu (0 = ilk sekme). Sınırsızdır: lastik
  /// bant ve momentum yayı uçlarda kısa süre aralık dışına taşıyabilir.
  late final AnimationController _position = AnimationController.unbounded(
    vsync: this,
    value: _restIndex.toDouble(),
  );

  bool _dragging = false;

  /// Sürüklemede parmağın dirençsiz konumu (sekme birimi).
  double _dragRaw = 0;

  /// Sürüklerken göstergenin üstünde durduğu sekme (haptik eşiği).
  int _hoverIndex = 0;

  /// Tek sekmenin genişliği (px); sürükleme başında ölçülür.
  double _itemWidth = 1;

  int get _count => widget.destinations.length;

  double get _maxPos => (_count - 1).toDouble();

  bool _inPill(int index) => index >= 0 && index < widget.destinations.length;

  @override
  void didUpdateWidget(GlassNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final int index = widget.selectedIndex;
    if (!_inPill(index) || index == _restIndex) return;
    _restIndex = index;
    if (_dragging) return;
    // Gösterge gizliyken (Ara seçiliydi) kaymadan yerinde belirir.
    if (!_inPill(oldWidget.selectedIndex)) {
      _position.value = index.toDouble();
    } else {
      _settle(AppSprings.standard, _position.velocity);
    }
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  /// Göstergeyi [_restIndex]'e yayla oturtur. O anki konum ve hızdan başlar,
  /// böylece süren bir geçiş yakalanıp yönü değiştirilebilir.
  void _settle(SpringDescription spring, double velocity) {
    final double target = _restIndex.toDouble();
    if (context.reduceMotion) {
      _position.value = target;
      return;
    }
    _position.animateWith(
      SpringSimulation(spring, _position.value, target, velocity),
    );
  }

  int _clampIndex(double position) => position.round().clamp(0, _count - 1);

  void _onDragStart(DragStartDetails details) {
    _itemWidth = context.size!.width / _count;
    _position.stop();
    // Gizli gösterge parmağın altındaki sekmede belirir; görünürken parmak
    // onu tuttuğu yerden sürükler (atlama yok).
    if (!_inPill(widget.selectedIndex)) {
      _position.value = (details.localPosition.dx / _itemWidth)
          .floorToDouble()
          .clamp(0, _maxPos);
    }
    _dragRaw = _position.value;
    _hoverIndex = _clampIndex(_position.value);
    setState(() => _dragging = true);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _dragRaw += details.delta.dx / _itemWidth;
    _position.value = _resist(_dragRaw);
    final int hover = _clampIndex(_position.value);
    if (hover == _hoverIndex) return;
    _hoverIndex = hover;
    Haptics.tap();
  }

  /// Aralık dışına taşan sürüklemeye artan direnç uygular (sekme birimi).
  double _resist(double raw) {
    final double bound = raw.clamp(0, _maxPos);
    final double overshoot = (raw - bound) * _itemWidth;
    return bound + rubberband(overshoot, _itemWidth) / _itemWidth;
  }

  void _onDragEnd(DragEndDetails details) {
    final double velocity = details.velocity.pixelsPerSecond.dx;
    // Hedef bırakış noktasından değil, hızın götüreceği noktadan seçilir:
    // kısa bir fiske de sekmeyi değiştirebilir.
    final double projected =
        _position.value +
        project(velocity, decelerationRate: AppMotion.decelerationFast) /
            _itemWidth;
    final int target = _clampIndex(projected);
    if (target != _hoverIndex) Haptics.tap();
    _restIndex = target;
    _settle(AppSprings.momentum, velocity / _itemWidth);
    setState(() => _dragging = false);
    // Aynı sekmede bırakmak "köke dön" anlamına gelen yeniden seçim değildir.
    if (target != widget.selectedIndex) widget.onSelected(target);
  }

  void _onDragCancel() {
    if (!_dragging) return;
    _settle(AppSprings.standard, 0);
    setState(() => _dragging = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onHorizontalDragCancel: _onDragCancel,
      child: GlassPanel(
        borderRadius: BorderRadius.circular(AppSizes.navBarHeight / 2),
        child: SizedBox(
          height: AppSizes.navBarHeight,
          child: Stack(
            children: [
              _buildIndicator(context),
              Row(
                children: [
                  for (int i = 0; i < _count; i++)
                    Expanded(
                      child: _NavItem(
                        destination: widget.destinations[i],
                        selected: i == widget.selectedIndex,
                        onTap: () => widget.onSelected(i),
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

  /// Her zaman ağaçta duran seçim göstergesi; konumu [_position]'dan okunur.
  Widget _buildIndicator(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return AnimatedOpacity(
      opacity: _dragging || _inPill(widget.selectedIndex) ? 1 : 0,
      duration: AppDurations.fast,
      child: AnimatedBuilder(
        animation: _position,
        builder: (context, child) => Align(
          alignment: Alignment(
            _count == 1 ? 0 : -1 + 2 * _position.value / _maxPos,
            0,
          ),
          child: child,
        ),
        child: FractionallySizedBox(
          widthFactor: 1 / _count,
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
        ),
      ),
    );
  }
}

/// İkon + etiketten oluşan tek sekme. Seçiliyken primary renk ve dolgulu ikon;
/// seçili olmayan sekmeye dokunmak seçim haptiği verir.
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
    final Color color = selected ? scheme.primary : scheme.onSurface;

    final bool badged = destination.badgeCount > 0;
    return Pressable(
      onPressed: onTap,
      haptic: !selected,
      child: Semantics(
        selected: selected,
        value: badged ? destination.badgeLabel : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: AppDurations.fast,
                  child: Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    key: ValueKey(selected),
                    color: color,
                    size: AppSizes.navBarIcon,
                  ),
                ),
                if (badged)
                  PositionedDirectional(
                    top: -AppSpacing.xs,
                    start: AppSizes.navBarIcon - AppSizes.tabBadgeOffset,
                    child: _Badge(count: destination.badgeCount),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.navBarLabelGap),
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

/// Sekme ikonundaki kırmızı sayı rozeti; tek haneli sayıda daire, fazlasında
/// kapsül.
class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        constraints: const BoxConstraints(
          minWidth: AppSizes.tabBadgeMinSize,
          minHeight: AppSizes.tabBadgeMinSize,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.tabBadgePaddingH,
        ),
        decoration: BoxDecoration(
          color: scheme.error,
          borderRadius: BorderRadius.circular(AppSizes.tabBadgeMinSize / 2),
        ),
        alignment: Alignment.center,
        child: Text(
          count > AppSizes.tabBadgeMaxCount
              ? '${AppSizes.tabBadgeMaxCount}+'
              : '$count',
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: scheme.onError, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

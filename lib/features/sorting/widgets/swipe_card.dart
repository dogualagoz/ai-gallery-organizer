// Tinder tarzı sürüklenebilir kart: sola sil, sağa atla, yukarı seçili kategoriye ata.
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';

/// Eşik değeri aşıldığında tetiklenecek yön.
enum SwipeDirection { left, right, up }

/// [SwipeCard]'ı buton dokunuşuyla dışarıdan tetiklemek için köprü.
/// Aynı kart görünür kaldığı sürece tek örnek kullanılır (bkz. [SortingScreen]).
class SwipeCardController {
  VoidCallback? _delete;
  VoidCallback? _assign;
  VoidCallback? _skip;

  void _attach({
    required VoidCallback delete,
    required VoidCallback assign,
    required VoidCallback skip,
  }) {
    _delete = delete;
    _assign = assign;
    _skip = skip;
  }

  void _detach() {
    _delete = null;
    _assign = null;
    _skip = null;
  }

  void triggerDelete() => _delete?.call();
  void triggerAssign() => _assign?.call();
  void triggerSkip() => _skip?.call();
}

class SwipeCard extends StatefulWidget {
  const SwipeCard({
    super.key,
    required this.asset,
    required this.onDelete,
    required this.onSkip,
    required this.onAssign,
    required this.assignIcon,
    required this.assignLabel,
    this.controller,
  });

  final AssetEntity? asset;

  /// Silme işlemini gerçekleştirir (sola); kullanıcı sistem onayını reddederse
  /// `false` döner ve kart geri yaylanır.
  final Future<bool> Function() onDelete;

  /// Atla (sağa): kartı bu oturumda geç.
  final VoidCallback onSkip;

  /// Seçili kategoriye atar (yukarı); atama sonrası kart kuyruktan düşer.
  final VoidCallback onAssign;

  /// Yukarı-ata ipucunda gösterilen seçili kategori ikonu ve adı.
  final IconData assignIcon;
  final String assignLabel;

  /// Alttaki aksiyon butonlarının aynı jestleri tetikleyebilmesi için.
  final SwipeCardController? controller;

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard>
    with SingleTickerProviderStateMixin {
  static const double _threshold = 120;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.medium,
  );

  Offset _dragOffset = Offset.zero;
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _attachController();
  }

  @override
  void didUpdateWidget(covariant SwipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach();
      _attachController();
    }
  }

  void _attachController() {
    widget.controller?._attach(
      delete: () {
        if (!_animating) _performDelete();
      },
      assign: () {
        if (!_animating) _performAssign();
      },
      skip: () {
        if (!_animating) _performSkip();
      },
    );
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_animating) return;
    setState(() => _dragOffset += details.delta);
  }

  Future<void> _onPanEnd(DragEndDetails details) async {
    if (_animating) return;
    final Offset offset = _dragOffset;
    if (offset.dx > _threshold) {
      await _performSkip();
    } else if (offset.dx < -_threshold) {
      await _performDelete();
    } else if (offset.dy < -_threshold && offset.dx.abs() < _threshold) {
      await _performAssign();
    } else {
      await _animateTo(Offset.zero);
    }
  }

  /// Yukarı: seçili kategoriye ata. Kart yukarı uçar, atama sonrası kuyruktan düşer.
  Future<void> _performAssign() async {
    await _animateTo(const Offset(0, -900));
    widget.onAssign();
  }

  Future<void> _performDelete() async {
    await _animateTo(const Offset(-700, 0));
    final bool removed = await widget.onDelete();
    if (!removed && mounted) await _animateTo(Offset.zero);
  }

  /// Sağa: atla (bu oturumda geç). Kart sağa uçar.
  Future<void> _performSkip() async {
    await _animateTo(const Offset(700, 0));
    widget.onSkip();
  }

  Future<void> _animateTo(Offset target) async {
    setState(() => _animating = true);
    final Animation<Offset> animation = Tween<Offset>(
      begin: _dragOffset,
      end: target,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    void listener() => setState(() => _dragOffset = animation.value);
    animation.addListener(listener);
    _controller.value = 0;
    await _controller.forward();
    animation.removeListener(listener);
    if (mounted) setState(() => _animating = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double angle = _dragOffset.dx / 3000;
    final double rightHint = (_dragOffset.dx / _threshold).clamp(0.0, 1.0);
    final double leftHint = (-_dragOffset.dx / _threshold).clamp(0.0, 1.0);
    final double upHint = (-_dragOffset.dy / _threshold).clamp(0.0, 1.0);

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: _dragOffset,
        child: Transform.rotate(
          angle: angle,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _CardImage(asset: widget.asset),
                  if (rightHint > 0)
                    _DirectionHint(
                      opacity: rightHint,
                      alignment: Alignment.centerRight,
                      color: Colors.blueGrey,
                      icon: Icons.arrow_forward,
                      label: l10n.sortingHintSkip,
                    ),
                  if (leftHint > 0)
                    _DirectionHint(
                      opacity: leftHint,
                      alignment: Alignment.centerLeft,
                      color: Colors.red,
                      icon: Icons.delete_outline,
                      label: l10n.sortingHintDelete,
                    ),
                  if (upHint > 0)
                    _DirectionHint(
                      opacity: upHint,
                      alignment: Alignment.topCenter,
                      color: scheme.primary,
                      icon: widget.assignIcon,
                      label: widget.assignLabel,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  const _CardImage({required this.asset});

  final AssetEntity? asset;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    if (asset == null) {
      return ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
      );
    }
    return AssetEntityImage(
      asset!,
      isOriginal: false,
      thumbnailSize: const ThumbnailSize(1080, 1920),
      fit: BoxFit.cover,
    );
  }
}

/// Sürükleme sırasında köşede beliren yön ipucu (ikon + etiket).
class _DirectionHint extends StatelessWidget {
  const _DirectionHint({
    required this.opacity,
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final double opacity;
  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Opacity(
          opacity: opacity,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

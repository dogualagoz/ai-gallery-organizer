// Tinder tarzı sürüklenebilir kart: sola sil, sağa panoya ata, yukarı atla.
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';

/// Eşik değeri aşıldığında tetiklenecek yön.
enum SwipeDirection { left, right, up }

class SwipeCard extends StatefulWidget {
  const SwipeCard({
    super.key,
    required this.asset,
    required this.onDelete,
    required this.onSkip,
    required this.onAssign,
  });

  final AssetEntity? asset;

  /// Silme işlemini gerçekleştirir; kullanıcı sistem onayını reddederse
  /// `false` döner ve kart geri yaylanır.
  final Future<bool> Function() onDelete;

  final VoidCallback onSkip;

  /// Panoya atama akışını başlatır (board seçici); kart her koşulda merkeze
  /// döner, gerçek atama tamamlandığında kart üst sıradan zaten düşer.
  final VoidCallback onAssign;

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
  void dispose() {
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
      await _animateTo(Offset.zero);
      widget.onAssign();
    } else if (offset.dx < -_threshold) {
      await _animateTo(const Offset(-700, 0));
      final bool removed = await widget.onDelete();
      if (!removed && mounted) await _animateTo(Offset.zero);
    } else if (offset.dy < -_threshold && offset.dx.abs() < _threshold) {
      await _animateTo(const Offset(0, -900));
      widget.onSkip();
    } else {
      await _animateTo(Offset.zero);
    }
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _CardImage(asset: widget.asset),
                  if (rightHint > 0)
                    _DirectionHint(
                      opacity: rightHint,
                      alignment: Alignment.centerRight,
                      color: Colors.green,
                      icon: Icons.bookmark_add_outlined,
                      label: l10n.sortingHintAssign,
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
                      color: Colors.blueGrey,
                      icon: Icons.arrow_upward,
                      label: l10n.sortingHintSkip,
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

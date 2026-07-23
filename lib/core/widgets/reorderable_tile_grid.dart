// Düzenleme modunda sürükle-bırak ile yeniden sıralanabilen 2+ sütunlu ızgara.
// [editing] false iken karolar normal davranır (dokunma/açılma çalışır);
// true iken her karo titreşir (Jiggle) ve Draggable/DragTarget ile taşınır.
// Sıralama mantığı dışarıda: [onReorder] eski→yeni index verir.
import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';
import 'jiggle.dart';

class ReorderableTileGrid extends StatelessWidget {
  const ReorderableTileGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.editing,
    required this.onReorder,
    required this.crossAxisCount,
    required this.childAspectRatio,
    this.spacing = AppSpacing.sm,
    this.keyBuilder,
    this.trailing,
  });

  final int itemCount;

  /// Karonun görselini üretir (dokunma/açılma davranışı çağırana ait).
  final Widget Function(BuildContext context, int index) itemBuilder;

  final bool editing;

  /// [from] index'indeki karo, [to] index'inin önüne taşınır.
  final void Function(int from, int to) onReorder;

  final int crossAxisCount;
  final double childAspectRatio;
  final double spacing;

  /// Karo kimliğini sabitler (reorder animasyonu + Jiggle state'i korunur).
  final Key Function(int index)? keyBuilder;

  /// Yeniden sıralanmayan son hücre (ör. "yeni pano" kartı). null ise yok.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final bool hasTrailing = trailing != null;
    final int total = itemCount + (hasTrailing ? 1 : 0);

    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: total,
      itemBuilder: (context, index) {
        if (hasTrailing && index == itemCount) return trailing!;
        final Widget tile = itemBuilder(context, index);
        final Widget cell = editing
            ? _ReorderableCell(
                index: index,
                onReorder: onReorder,
                child: tile,
              )
            : tile;
        final Key? key = keyBuilder?.call(index);
        return key == null ? cell : KeyedSubtree(key: key, child: cell);
      },
    );
  }
}

/// Düzenleme modunda tek karo: sürüklenebilir kaynak + üzerine bırakılabilir hedef.
class _ReorderableCell extends StatelessWidget {
  const _ReorderableCell({
    required this.index,
    required this.onReorder,
    required this.child,
  });

  final int index;
  final void Function(int from, int to) onReorder;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) => onReorder(details.data, index),
      builder: (context, candidate, rejected) {
        final bool highlighted = candidate.isNotEmpty;
        return LayoutBuilder(
          builder: (context, constraints) {
            final Size size = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            return Draggable<int>(
              data: index,
              dragAnchorStrategy: childDragAnchorStrategy,
              feedback: _DragFeedback(size: size, child: child),
              childWhenDragging: Opacity(opacity: 0.25, child: child),
              child: AnimatedScale(
                scale: highlighted ? 1.06 : 1.0,
                duration: AppDurations.fast,
                child: Jiggle(enabled: true, seed: index, child: child),
              ),
            );
          },
        );
      },
    );
  }
}

/// Parmağın altında taşınan karonun görseli: hafif büyütülmüş + gölgeli.
class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.size, required this.child});

  final Size size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Transform.scale(
        scale: 1.06,
        child: SizedBox.fromSize(
          size: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

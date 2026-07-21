// Sol kenardan sağa kaydırınca geri dönmeyi tetikleyen sarmalayıcı.
// OpenContainer ile açılan ekranlarda iOS'un native kenar-swipe jesti devrede
// olmadığından, container-transform animasyonunu koruyup elle bu jesti ekler.
import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';

/// [child]'ı sol kenardan başlayan sağa sürüklemeyle [onBack]'i tetikleyecek
/// şekilde sarar. [enabled] false iken jest tamamen kapalıdır (ör. seçim modu).
class EdgeSwipeBack extends StatefulWidget {
  const EdgeSwipeBack({
    super.key,
    required this.child,
    required this.onBack,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onBack;
  final bool enabled;

  @override
  State<EdgeSwipeBack> createState() => _EdgeSwipeBackState();
}

class _EdgeSwipeBackState extends State<EdgeSwipeBack> {
  // Jest yalnız sol kenarda başladıysa izlenir; ekran ortasındaki yatay
  // kaydırmalar (grid vb.) yanlışlıkla geri dönmeyi tetiklemesin.
  bool _tracking = false;
  double _dragX = 0;

  void _onStart(DragStartDetails details) {
    _tracking = details.globalPosition.dx <= AppSizes.edgeSwipeZone;
    _dragX = 0;
  }

  void _onUpdate(DragUpdateDetails details) {
    if (!_tracking) return;
    _dragX += details.delta.dx;
  }

  void _onEnd(DragEndDetails details) {
    if (!_tracking) return;
    final bool fastFling =
        details.primaryVelocity != null && details.primaryVelocity! > 700;
    if (_dragX >= AppSizes.edgeSwipeTriggerDistance || fastFling) {
      widget.onBack();
    }
    _tracking = false;
    _dragX = 0;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return GestureDetector(
      // Alttaki içerik dikey/dokunma jestlerini almaya devam etsin diye yalnız
      // yatay sürükleme dinlenir.
      onHorizontalDragStart: _onStart,
      onHorizontalDragUpdate: _onUpdate,
      onHorizontalDragEnd: _onEnd,
      child: widget.child,
    );
  }
}

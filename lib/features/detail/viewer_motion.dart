// Görüntüleyicinin dikey jest durumu: aşağı çekip kapatma (parmağı 1:1 izler,
// bırakışta konum + hız projeksiyonuyla karar verir) ve bilgi paneli açıklığı.
import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../../core/constants/motion_constants.dart';
import '../../core/utils/motion_physics.dart';

enum _DragMode { dismiss, info }

/// Sayfanın sürükleme ofseti ve panelin açıklığı. Her hareket o anki
/// değerden başlar: dönüşü ya da açılan paneli yarıda yakalamak mümkündür.
class ViewerMotion {
  ViewerMotion({
    required TickerProvider vsync,
    required this.onDismiss,
    required this.onInfoChanged,
  }) : info = AnimationController.unbounded(vsync: vsync),
       _settle = AnimationController.unbounded(vsync: vsync) {
    _settle
      ..addListener(() => drag.value = _releasedAt * (1 - _settle.value))
      ..addStatusListener((status) {
        // Yay toleransla durur; ofset tam sıfıra oturtulur ki sonraki jest
        // "yarıda kalan kapatma" sanılmasın.
        if (status == AnimationStatus.completed) drag.value = Offset.zero;
      });
  }

  /// Bilgi panelinin açıklığı: 0 kapalı, 1 açık (yay kısa süre 1'i aşabilir).
  final AnimationController info;

  /// Bırakılan sayfanın yerine dönüşü (0 → 1).
  final AnimationController _settle;

  /// Aşağı çekişte sayfanın parmakla birlikte kayması.
  final ValueNotifier<Offset> drag = ValueNotifier(Offset.zero);

  /// Kapanma eşiği geçildi: görüntüleyici kapanmalı.
  final VoidCallback onDismiss;

  /// Panel hedefi değişti (açık/kapalı).
  final ValueChanged<bool> onInfoChanged;

  /// Hareketi Azalt: yay yerine kısa geçiş.
  bool reduceMotion = false;

  /// Panelin hedef durumu (animasyon sürerken de son karar).
  bool get infoShown => _infoShown;
  bool _infoShown = false;

  _DragMode? _mode;
  Offset _origin = Offset.zero;
  double _infoAtStart = 0;
  Offset _releasedAt = Offset.zero;

  /// Ekran yüksekliği [height] iken panelin yüksekliği.
  static double panelHeight(double height) =>
      height * AppViewer.infoPanelFraction;

  /// Kapanma ilerlemesi (0 → 1): zemin solması ve görselin küçülmesi.
  double dismissProgress(double height) {
    if (height <= 0) return 0;
    final double span = height * AppViewer.dismissFadeSpan;
    return (drag.value.dy / span).clamp(0.0, 1.0);
  }

  void dragStart(DragStartDetails details) {
    _settle.stop();
    info.stop();
    _mode = null;
    _origin = details.globalPosition - drag.value;
    _infoAtStart = info.value;
  }

  void dragUpdate(DragUpdateDetails details, double height) {
    final Offset raw = details.globalPosition - _origin;
    // Yön ilk harekette belirlenir: yarıda yakalanan kapatma ya da kapalı
    // panelde aşağı çekiş kapatır; açık panel ya da yukarı çekiş paneli sürer.
    _mode ??= drag.value != Offset.zero || (info.value <= 0 && raw.dy > 0)
        ? _DragMode.dismiss
        : _DragMode.info;
    switch (_mode!) {
      case _DragMode.dismiss:
        // Başlangıcın üstüne çekiş lastik bantla direnir.
        drag.value = Offset(
          raw.dx,
          raw.dy < 0 ? rubberband(raw.dy, height) : raw.dy,
        );
      case _DragMode.info:
        final double panel = panelHeight(height);
        final double open = _infoAtStart - raw.dy / panel;
        info.value = open > 1
            ? 1 + rubberband((open - 1) * panel, height) / panel
            : math.max(0, open);
    }
  }

  void dragEnd(DragEndDetails details, double height) {
    final double velocity = details.velocity.pixelsPerSecond.dy;
    switch (_mode) {
      case _DragMode.dismiss:
        _endDismiss(velocity);
      case _DragMode.info:
        _endInfo(velocity, height);
      case null:
        // Yön belli olmadan biten jest: başlangıçta durdurulan hareketler
        // yarıda asılı kalmasın, hedeflerine devam etsin.
        if (drag.value != Offset.zero) _settleBack(0);
        setInfo(_infoShown);
    }
    _mode = null;
  }

  /// Jest başka tanıyıcıya kaptırıldı: hızsız bırakılmış gibi yerleşir.
  void dragCancel(double height) => dragEnd(DragEndDetails(), height);

  /// Paneli açar/kapatır; [velocity] sürüklemeden devralınan hızdır
  /// (açıklık/sn). Verilmezse süren hareketin hızı korunur.
  void setInfo(bool open, {double? velocity}) {
    if (_infoShown != open) {
      _infoShown = open;
      onInfoChanged(open);
    }
    final double target = open ? 1 : 0;
    if (reduceMotion) {
      info.animateTo(target, duration: AppMotion.reducedCrossfade);
      return;
    }
    info.animateWith(
      SpringSimulation(
        AppSprings.sheet,
        info.value,
        target,
        velocity ?? info.velocity,
      ),
    );
  }

  void _endDismiss(double velocity) {
    final Offset offset = drag.value;
    final double projected =
        offset.dy +
        project(velocity, decelerationRate: AppMotion.decelerationFast);
    if (projected > AppViewer.dismissDistance) {
      onDismiss();
      return;
    }
    _settleBack(velocity);
  }

  /// Sayfayı yerine yayla döndürür; [velocity] bırakış hızıdır (px/sn).
  void _settleBack(double velocity) {
    final Offset offset = drag.value;
    _releasedAt = offset;
    _settle.value = 0;
    if (reduceMotion) {
      _settle.animateTo(1, duration: AppMotion.reducedCrossfade);
      return;
    }
    // Dönüş bırakış hızıyla başlar; hızlı fırlatılmışsa hafifçe taşar.
    _settle.animateWith(
      SpringSimulation(
        AppSprings.momentum,
        0,
        1,
        relativeVelocity(velocity, offset.dy, 0),
      ),
    );
  }

  void _endInfo(double velocity, double height) {
    final double panel = panelHeight(height);
    // Panel fırlatılmak için var: kaydırma gibi uzun projeksiyon, hafif bir
    // fiske açar/kapatır; hızsız bırakışta yarı yol eşiği geçerlidir.
    final double projected = info.value - project(velocity) / panel;
    setInfo(
      projected > AppViewer.infoOpenThreshold,
      velocity: -velocity / panel,
    );
  }

  void dispose() {
    info.dispose();
    _settle.dispose();
    drag.dispose();
  }
}

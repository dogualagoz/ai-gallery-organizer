// Tek analiz uçuşunun fizik modeli: X/Y eksen yayları, yeniden hedefleme ve
// küçülme/solma ilerlemesi. Saf veri; çizim `analysis_flights.dart`'ta.
import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:flutter/physics.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/constants/motion_constants.dart';
import '../../../core/models/screenshot_category.dart';

/// Tek uçuşun durumu: eksen yayları ve o anki konum/ilerleme.
class Flight {
  Flight({
    required this.asset,
    required this.category,
    required this.start,
    required Offset end,
    required this.born,
    required Offset velocity,
  }) : position = start,
       _end = end,
       _legStart = born,
       _legDistance = (end - start).distance,
       _x = SpringSimulation(AppSprings.flight, start.dx, end.dx, velocity.dx),
       _y = SpringSimulation(AppSprings.flight, start.dy, end.dy, velocity.dy);

  final AssetEntity? asset;
  final ScreenshotCategory category;
  final Offset start;
  final Duration born;

  Offset _end;

  /// Geçerli yayların başladığı an; her yeniden hedeflemede ilerler.
  Duration _legStart;
  SpringSimulation _x;
  SpringSimulation _y;

  /// Geçerli bacağın başındaki uzaklık ve o ana kadarki görsel ilerleme:
  /// kalan solma payı yeni bacağa yayılır.
  double _legDistance;
  double _legBase = 0;

  /// Geçerli bacağın tamamlanan oranı (atış başında negatife inebilir).
  double _leg = 0;

  Offset position;

  /// Küçülme/solma için yolun tamamlanan oranı (0-1). Yalnız artar: karo
  /// kayınca solmaya başlamış kart yeniden belirmez.
  double progress = 0;

  /// Kart geçerli hedefine vardı (yay kuyruğu beklenmez).
  bool get arrived => _leg >= AppFlight.landedAt;

  static double _seconds(Duration duration) =>
      duration.inMicroseconds / Duration.microsecondsPerSecond;

  /// Hedef kaydıysa yayları [now] anındaki konum ve hızdan yeni hedefe
  /// kurar: yol kırılmadan döner, kart sıçramaz.
  void retarget(Offset end, Duration now) {
    if ((end - _end).distance <= AppFlight.retargetTolerance) return;
    final double t = _seconds(now - _legStart);
    final Offset from = Offset(_x.x(t), _y.x(t));
    _x = SpringSimulation(AppSprings.flight, from.dx, end.dx, _x.dx(t));
    _y = SpringSimulation(AppSprings.flight, from.dy, end.dy, _y.dx(t));
    _end = end;
    _legStart = now;
    _legDistance = (end - from).distance;
    _legBase = progress;
  }

  /// Konumu ve ilerlemeyi [now] anına göre günceller.
  void update(Duration now) {
    final double t = _seconds(now - _legStart);
    position = Offset(_x.x(t), _y.x(t));
    _leg = _legDistance < 1 ? 1 : 1 - (_end - position).distance / _legDistance;
    progress = math.max(progress, _legBase + (1 - _legBase) * _leg);
  }
}

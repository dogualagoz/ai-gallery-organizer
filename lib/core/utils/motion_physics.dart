// Akışkan arayüz fiziği: momentum projeksiyonu, lastik bant, hız normalize.
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../constants/motion_constants.dart';

/// Bırakış hızından (px/s) jestin "gideceği" ek mesafeyi hesaplar — Apple'ın
/// Designing Fluid Interfaces örneğindeki üstel yavaşlama formülü (fizik
/// kitabındaki v²/2a DEĞİL). Hedef seçimi bu noktaya göre yapılır.
double project(
  double velocity, {
  double decelerationRate = AppMotion.decelerationNormal,
}) {
  return (velocity / Duration.millisecondsPerSecond) *
      decelerationRate /
      (1 - decelerationRate);
}

/// Sınırı [overshoot] kadar aşan sürüklemeye artan direnç uygular: ne kadar
/// uzaklaşılırsa öğe parmağı o kadar az izler, sert duvar hissi oluşmaz.
/// [dimension] ilgili eksendeki görünür boyuttur.
double rubberband(
  double overshoot,
  double dimension, {
  double constant = AppMotion.rubberbandConstant,
}) {
  if (dimension <= 0) return 0;
  return (overshoot * dimension * constant) /
      (dimension + constant * overshoot.abs());
}

/// Mutlak jest hızını (px/s) kalan mesafeye göre normalize eder; birim aralıklı
/// (0→1) controller'lara yay hızı verirken kullanılır. Mesafe ~0 ise 0 döner.
double relativeVelocity(double velocity, double from, double to) {
  final double distance = to - from;
  if (distance.abs() < precisionErrorTolerance) return 0;
  return velocity / distance;
}

/// [value]'ya en yakın tutunma noktasını döndürür. [points] boş olamaz.
double nearestSnap(double value, List<double> points) {
  assert(points.isNotEmpty, 'nearestSnap en az bir nokta ister');
  double best = points.first;
  for (final double point in points) {
    if ((point - value).abs() < (best - value).abs()) best = point;
  }
  return best;
}

/// Yayı, sabit süre isteyen API'lerin (Hero uçuşu, rota geçişi) kullanacağı
/// bir eğriye çevirir: [duration] boyunca yayın 0→1 yolu izlenir, son değer
/// tam 1'e normalize edilir (yerleşme kuyruğu kesilir). Sekmesiz yaylarla
/// kullanılmalı; sekmeli yayda eğri 1'i aşar.
class SpringCurve extends Curve {
  SpringCurve(SpringDescription spring, Duration duration)
    : _simulation = SpringSimulation(spring, 0, 1, 0),
      _seconds = duration.inMicroseconds / Duration.microsecondsPerSecond;

  final SpringSimulation _simulation;
  final double _seconds;

  /// Süre sonunda yayın vardığı nokta; eğri bununla bölünerek 1'de biter.
  late final double _end = _simulation.x(_seconds);

  @override
  double transformInternal(double t) => _simulation.x(t * _seconds) / _end;
}

/// Reduce Motion tercihine kısa erişim.
extension ReduceMotionContext on BuildContext {
  /// Sistem "Hareketi Azalt" açıksa true — yay/kayma yerine çapraz geçiş,
  /// döngüsel animasyonlar durdurulur.
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);
}

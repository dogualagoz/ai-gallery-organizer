// Görüntüleyicinin rota sayfası: saydam (aşağı çekerken arkadaki ızgara
// görünür), solarak açılıp kapanır; görselin yolunu Hero uçuşu taşır.
import 'package:flutter/widgets.dart';

import '../../core/constants/motion_constants.dart';

/// go_router `pageBuilder`'ında kullanılan görüntüleyici sayfası.
class ViewerPage<T> extends Page<T> {
  const ViewerPage({super.key, super.name, required this.child});

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => _ViewerRoute<T>(this);
}

/// Saydam, solarak geçen rota; sonraki rotalara geçiş animasyonu vermez.
class _ViewerRoute<T> extends PageRoute<T> {
  _ViewerRoute(ViewerPage<T> page) : super(settings: page);

  ViewerPage<T> get _page => settings as ViewerPage<T>;

  @override
  bool get opaque => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => AppViewer.transition;

  // Üstüne açılan sheet'ler görüntüleyiciyi geri itmez: saydam rota geri
  // çekilip küçülünce kenarlarından arkadaki kütüphane görünürdü.
  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) => false;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _page.child;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }
}

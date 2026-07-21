// Kategori board karolarının uçuş-hedefi konumlarını paylaşan kapsam:
// SystemBoardsGrid karoları [keyFor] ile bir GlobalKey kaydeder, AnalyzeCard
// uçan fotoğrafın ineceği kategori karosunu bu anahtardan çözer. Böylece uçuş,
// kartın dışına çıkıp anasayfadaki gerçek kategoriye kayabilir.
import 'package:flutter/widgets.dart';

import '../../../core/models/screenshot_category.dart';

class CategoryTargetScope extends InheritedWidget {
  const CategoryTargetScope({
    super.key,
    required this.keyFor,
    required super.child,
  });

  /// Verilen kategori için (kalıcı) hedef anahtarı döndürür.
  final GlobalKey Function(ScreenshotCategory category) keyFor;

  static CategoryTargetScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CategoryTargetScope>();

  @override
  bool updateShouldNotify(CategoryTargetScope oldWidget) => false;
}

/// [CategoryTargetScope]'u sağlayan, kategori→GlobalKey haritasını yaşatan
/// sarmalayıcı. Board karoları ile AnalyzeCard'ı birlikte saran bir yere konur.
class CategoryTargetProvider extends StatefulWidget {
  const CategoryTargetProvider({super.key, required this.child});

  final Widget child;

  @override
  State<CategoryTargetProvider> createState() => _CategoryTargetProviderState();
}

class _CategoryTargetProviderState extends State<CategoryTargetProvider> {
  final Map<ScreenshotCategory, GlobalKey> _keys = {};

  GlobalKey _keyFor(ScreenshotCategory category) =>
      _keys.putIfAbsent(category, GlobalKey.new);

  @override
  Widget build(BuildContext context) =>
      CategoryTargetScope(keyFor: _keyFor, child: widget.child);
}

// Rota yolları, sekme enum'u ve görüntüleyici kapsamı: router'dan bağımsız,
// feature'ların import döngüsüne girmeden kullanabildiği sabitler.
import '../models/screenshot_category.dart';

/// Ana kabuğun sekmeleri. Sıra, [StatefulShellRoute] dal sırasıyla aynıdır.
enum AppTab { library, clean, search }

/// Rota yolları — string tekrarını önlemek için tek yerde.
abstract final class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String library = '/library';
  static const String clean = '/clean';
  static const String search = '/search';
  static const String settings = '/settings';
  static const String paywall = '/paywall';
  static const String analysisMilestone = '/analysis-milestone';
  static const String detailBase = '/detail';

  /// Kütüphane dalının alt rota parçaları; bu ekranlarda sekme çubuğu kalır.
  static const String recentsSegment = 'recents';
  static const String categorySegment = 'category';
  static const String boardSegment = 'board';

  static const String recents = '$library/$recentsSegment';

  /// Pano/kategori detayını doğrudan seçim modunda açan query parametresi.
  static const String selectQuery = 'select';
  static const String selectQueryOn = '1';

  /// Paywall query parametresi: açılışta paket bölümüne kaydır.
  static const String paywallFocusQuery = 'focus';
  static const String paywallFocusPacks = 'packs';

  /// Analiz limiti akışları için: paywall'ı paket bölümünde açar.
  static const String paywallPacks =
      '$paywall?$paywallFocusQuery=$paywallFocusPacks';

  /// Sistem kategorisi panosu (enum index'i ile adreslenir).
  static String category(ScreenshotCategory category, {bool select = false}) =>
      _selectable('$library/$categorySegment/${category.index}', select);

  /// Kullanıcı panosu. Kimlik, slash içerse de tek segment kalsın diye encode
  /// edilir.
  static String board(String boardId, {bool select = false}) => _selectable(
    '$library/$boardSegment/${Uri.encodeComponent(boardId)}',
    select,
  );

  /// Detay rotası assetId parametresi alır. iOS asset ID'leri slash içerir
  /// (`UUID/L0/001`) — encode edilmezse rota fazladan segmentlere bölünüp
  /// eşleşmez; go_router parametreyi okurken kendisi decode eder.
  static String detail(String assetId) =>
      '$detailBase/${Uri.encodeComponent(assetId)}';

  static String _selectable(String path, bool select) =>
      select ? '$path?$selectQuery=$selectQueryOn' : path;
}

/// Görüntüleyicide kaydırılabilen sıralı koleksiyon. Rota ekiyle (extra)
/// taşınır; deep link'te bulunmaz, görüntüleyici tek görselle açılır.
class ViewerScope {
  const ViewerScope(this.assetIds);

  final List<String> assetIds;
}

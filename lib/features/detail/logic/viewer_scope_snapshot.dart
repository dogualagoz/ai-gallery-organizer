// Görüntüleyicinin galeri olaylarında hangi parçasının yeniden kurulacağını
// belirleyen değerler: kapsamın dilimi ve görünen kaydın alanları.
import 'package:flutter/foundation.dart';

import '../../../core/models/screenshot_category.dart';
import '../../../core/models/screenshot_entry.dart';
import '../../gallery/data/screenshot_repository.dart';

/// Görüntüleyicinin (sayfalar dahil) galeriden izlediği dilim: kapsamda hâlâ
/// var olan kayıtlar ve yüklenmiş görsel sayısı. Kayıtların analiz/taşıma
/// alanları burada yok; onları yalnız bilgi paneli izler
/// ([viewerEntryFields]).
@immutable
class ViewerScopeSnapshot {
  const ViewerScopeSnapshot._(this.ids, this.loadedAssets);

  /// [scope] içinden [repo]'da kaydı olanlar.
  factory ViewerScopeSnapshot.of(
    ScreenshotRepository repo,
    List<String> scope,
  ) {
    final List<String> ids = [
      for (final String id in scope)
        if (repo.entryFor(id) != null) id,
    ];
    return ViewerScopeSnapshot._(
      ids,
      ids.where((id) => repo.assetFor(id) != null).length,
    );
  }

  /// Kapsamda kaydı hâlâ var olan kimlikler, kapsam sırasıyla.
  final List<String> ids;

  /// Görseli yüklenmiş (asset önbelleğinde olan) kimlik sayısı. Yalnız sayı
  /// izlenir: eşitlemede aynı görseller yeni nesnelerle gelirse ekran
  /// yenilenmez, eski nesneler aynı görseli göstermeye devam eder.
  final int loadedAssets;

  @override
  bool operator ==(Object other) =>
      other is ViewerScopeSnapshot &&
      listEquals(other.ids, ids) &&
      other.loadedAssets == loadedAssets;

  @override
  int get hashCode => Object.hash(ids.length, loadedAssets);
}

/// Bilgi panelinin gösterdiği, sonradan değişebilen kayıt alanları.
typedef ViewerEntryFields = ({
  ScreenshotCategory? category,
  ScreenshotCategory? aiCategory,
  String? boardId,
  DateTime? analyzedAt,
  String? ocrText,
  List<String> tags,
});

/// [entry]'nin anlık alanları; kayıt yoksa null. Kayıtlar yerinde değiştiği
/// için alanlar değer olarak kopyalanır. Etiketler her analizde yeni listeyle
/// yazılır (yerinde değişmez), bu yüzden liste kimliği karşılaştırma için
/// yeterlidir.
ViewerEntryFields? viewerEntryFields(ScreenshotEntry? entry) => entry == null
    ? null
    : (
        category: entry.category,
        aiCategory: entry.aiCategory,
        boardId: entry.boardId,
        analyzedAt: entry.analyzedAt,
        ocrText: entry.ocrText,
        tags: entry.tags,
      );

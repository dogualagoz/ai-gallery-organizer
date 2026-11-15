// Görüntüleyicinin galeri olaylarında yeniden kurulup kurulmayacağını
// belirleyen değer: kapsamın ve görünen kaydın anlık görüntüsü.
import 'package:flutter/foundation.dart';

import '../../core/models/screenshot_category.dart';
import '../../core/models/screenshot_entry.dart';
import '../gallery/data/screenshot_repository.dart';

/// Görüntüleyicinin galeriden izlediği dilim: kapsamda hâlâ var olan
/// kayıtlar, görünen kaydın yerleşim/analiz alanları ve yüklenmiş görsel
/// sayısı. Kayıtlar yerinde değiştiği için alanlar değer olarak alınır.
@immutable
class ViewerScopeSnapshot {
  const ViewerScopeSnapshot._(this.ids, this.current, this.loadedAssets);

  /// [scope] içinden [repo]'da kaydı olanlar ve [currentId] kaydının anlık
  /// alanları.
  factory ViewerScopeSnapshot.of(
    ScreenshotRepository repo,
    List<String> scope,
    String currentId,
  ) {
    final List<String> ids = [
      for (final String id in scope)
        if (repo.entryFor(id) != null) id,
    ];
    final ScreenshotEntry? entry = repo.entryFor(currentId);
    return ViewerScopeSnapshot._(
      ids,
      entry == null
          ? null
          : (
              entry.category,
              entry.aiCategory,
              entry.boardId,
              entry.analyzedAt,
              entry.ocrText,
              // Etiketler her analizde yeni listeyle yazılır: kimlik yeter.
              entry.tags,
            ),
      ids.where((id) => repo.assetFor(id) != null).length,
    );
  }

  /// Kapsamda kaydı hâlâ var olan kimlikler, kapsam sırasıyla.
  final List<String> ids;

  /// Görünen kaydın kategori, AI kategorisi, pano, analiz anı, OCR metni ve
  /// etiketleri; kayıt yoksa null.
  final (
    ScreenshotCategory?,
    ScreenshotCategory?,
    String?,
    DateTime?,
    String?,
    List<String>,
  )?
  current;

  /// Görseli yüklenmiş (asset önbelleğinde olan) kimlik sayısı.
  final int loadedAssets;

  @override
  bool operator ==(Object other) =>
      other is ViewerScopeSnapshot &&
      listEquals(other.ids, ids) &&
      other.current == current &&
      other.loadedAssets == loadedAssets;

  @override
  int get hashCode => Object.hash(ids.length, current, loadedAssets);
}

// Screenshot verisine erişim katmanı: photo_manager (cihaz kütüphanesi)
// ile Hive (local metadata) arasındaki köprü.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/models/screenshot_category.dart';
import '../../../core/models/screenshot_entry.dart';
import '../../../core/services/hive_service.dart';

final screenshotRepositoryProvider = Provider<ScreenshotRepository>((ref) {
  return ScreenshotRepository(HiveService.screenshots);
});

class ScreenshotRepository {
  ScreenshotRepository(this._box);

  final Box<ScreenshotEntry> _box;

  /// Thumbnail yüklemek için asset nesneleri bellekte tutulur;
  /// Photos kimliği kalıcı olduğu için oturum boyunca geçerlidir.
  final Map<String, AssetEntity> _assetCache = {};

  /// Metadata kayıtları, en yeni screenshot başta olacak şekilde.
  List<ScreenshotEntry> sortedEntries() {
    final List<ScreenshotEntry> entries = _box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  /// Box değişikliklerini dinlemek için (analiz sonuçları vs. yazıldığında).
  Stream<BoxEvent> watchChanges() => _box.watch();

  /// [assetId] için önbellekteki asset (thumbnail/detay görseli yüklemede kullanılır).
  AssetEntity? assetFor(String assetId) => _assetCache[assetId];

  /// Cihazdaki screenshot'ları Hive ile eşitler.
  /// Yeni asset'ler `pending` olarak eklenir, silinmiş asset kayıtları düşülür.
  /// Dönen değer: yeni eklenen kayıt sayısı.
  Future<int> syncLibrary() async {
    final List<AssetEntity> assets = await _fetchScreenshotAssets();

    _assetCache
      ..clear()
      ..addEntries(assets.map((asset) => MapEntry(asset.id, asset)));

    final Set<String> deviceIds = assets.map((asset) => asset.id).toSet();

    // Cihazdan silinmiş screenshot'ların metadata'sı da temizlenir.
    final List<String> staleKeys = _box.keys
        .cast<String>()
        .where((key) => !deviceIds.contains(key))
        .toList();
    if (staleKeys.isNotEmpty) await _box.deleteAll(staleKeys);

    final Map<String, ScreenshotEntry> newEntries = {
      for (final AssetEntity asset in assets)
        if (!_box.containsKey(asset.id))
          asset.id: ScreenshotEntry(
            assetId: asset.id,
            createdAt: asset.createDateTime,
          ),
    };
    if (newEntries.isNotEmpty) await _box.putAll(newEntries);

    return newEntries.length;
  }

  /// iOS "Screenshots" akıllı albümünden tüm asset'leri çeker.
  Future<List<AssetEntity>> _fetchScreenshotAssets() async {
    final PermissionState permission =
        await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) return const [];

    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );

    // iOS, screenshot'ları sistem tarafında akıllı albümde toplar —
    // subtype filtresi yazmaya gerek yok, albümün kendisi filtredir.
    AssetPathEntity? screenshotAlbum;
    for (final AssetPathEntity path in paths) {
      if (path.albumTypeEx?.darwin?.subtype ==
          PMDarwinAssetCollectionSubtype.smartAlbumScreenshots) {
        screenshotAlbum = path;
        break;
      }
    }
    if (screenshotAlbum != null) {
      final int count = await screenshotAlbum.assetCountAsync;
      if (count > 0) {
        return screenshotAlbum.getAssetListRange(start: 0, end: count);
      }
    }

    // Simülatörde `simctl addmedia` ile eklenen görseller gerçek screenshot
    // olarak sınıflanmadığından Screenshots albümü boş kalır; debug'da tüm
    // görsellere düşülür ki AI akışı test edilebilsin.
    if (kDebugMode && paths.isNotEmpty) {
      debugPrint('ScreenshotRepository: debug fallback — tüm görseller');
      final AssetPathEntity fallback = paths.first;
      final int count = await fallback.assetCountAsync;
      if (count == 0) return const [];
      return fallback.getAssetListRange(start: 0, end: count);
    }

    debugPrint('ScreenshotRepository: Screenshots albümü bulunamadı/boş');
    return const [];
  }

  /// AI analiz sonucunu kaydeder.
  Future<void> saveAnalysis({
    required String assetId,
    required ScreenshotCategory category,
    required List<String> tags,
    String? ocrText,
  }) async {
    final ScreenshotEntry? entry = _box.get(assetId);
    if (entry == null) return;
    entry
      ..category = category
      ..tags = tags
      ..ocrText = ocrText
      ..analyzedAt = DateTime.now();
    await _box.put(assetId, entry);
  }

  /// Kaydı yeniden analize hazır hale getirir: `analyzedAt`'i sıfırlar, böylece
  /// [isPending] tekrar true olur ve analiz kuyruğu onu yeniden işler. Kategori
  /// korunur; yeni sonuç üzerine yazana kadar mevcut grupta görünmeye devam eder.
  Future<void> markPending(String assetId) async {
    final ScreenshotEntry? entry = _box.get(assetId);
    if (entry == null) return;
    entry.analyzedAt = null;
    await _box.put(assetId, entry);
  }

  /// Kaydı kullanıcı board'una taşır ([boardId] null ise board'dan çıkarır).
  Future<void> assignToBoard(String assetId, String? boardId) async {
    final ScreenshotEntry? entry = _box.get(assetId);
    if (entry == null) return;
    entry.boardId = boardId;
    await _box.put(assetId, entry);
  }

  /// Kaydın sistem kategorisini elle değiştirir (kullanıcı düzeltmesi/taşıması).
  /// Özel board'dan da çıkarır ki fotoğraf hedef kategoride görünsün.
  Future<void> setCategory(String assetId, ScreenshotCategory category) async {
    final ScreenshotEntry? entry = _box.get(assetId);
    if (entry == null) return;
    entry
      ..category = category
      ..boardId = null;
    await _box.put(assetId, entry);
  }

  /// Metadata kaydını siler (cihazdan silme photo_manager editor ile ayrıca yapılır).
  Future<void> removeEntry(String assetId) => _box.delete(assetId);

  ScreenshotEntry? entryFor(String assetId) => _box.get(assetId);
}

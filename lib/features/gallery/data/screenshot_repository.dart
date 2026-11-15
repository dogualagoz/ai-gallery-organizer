// Screenshot verisine erişim katmanı: photo_manager (cihaz kütüphanesi)
// ile Hive (local metadata) arasındaki köprü.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/models/screenshot_category.dart';
import '../../../core/models/screenshot_entry.dart';
import '../../../core/services/category_priors_service.dart';
import '../../../core/services/hive_service.dart';
import '../../../core/services/photo_permission_service.dart';
import '../../../core/utils/app_logger.dart';

final screenshotRepositoryProvider = Provider<ScreenshotRepository>((ref) {
  return ScreenshotRepository(
    HiveService.screenshots,
    // Kullanıcı düzeltmesi olduğunda cihaz içi kişiselleşme priors'ına yaz.
    onCorrection: (from, to, tags) => ref
        .read(categoryPriorsProvider.notifier)
        .recordCorrection(from: from, to: to, tags: tags),
  );
});

/// Kullanıcı bir kategoriyi elle değiştirdiğinde çağrılır ([from] AI'ın kararı,
/// [to] kullanıcının seçtiği kategori). Kişiselleşme sinyalini kaydetmek için.
typedef CategoryCorrectionRecorder = Future<void> Function(
  ScreenshotCategory from,
  ScreenshotCategory to,
  List<String> tags,
);

class ScreenshotRepository {
  ScreenshotRepository(this._box, {this.onCorrection});

  final Box<ScreenshotEntry> _box;

  /// Kullanıcı düzeltmelerini öğrenme sinyaline aktaran opsiyonel callback.
  final CategoryCorrectionRecorder? onCorrection;

  /// Thumbnail yüklemek için asset nesneleri bellekte tutulur;
  /// Photos kimliği kalıcı olduğu için oturum boyunca geçerlidir.
  final Map<String, AssetEntity> _assetCache = {};

  /// Metadata kayıtları, en yeni screenshot başta olacak şekilde.
  List<ScreenshotEntry> sortedEntries() {
    final List<ScreenshotEntry> entries = _box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  /// Analiz bekleyen kayıtlar, en yeni başta (yalnız bekleyenler sıralanır).
  List<ScreenshotEntry> pendingEntries() {
    final List<ScreenshotEntry> entries =
        _box.values.where((entry) => entry.isPending).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  /// [boardId] panosuna atanmış kayıtların kimlikleri.
  List<String> assetIdsInBoard(String boardId) => [
    for (final ScreenshotEntry entry in _box.values)
      if (entry.boardId == boardId) entry.assetId,
  ];

  /// Box değişikliklerini dinlemek için (analiz sonuçları vs. yazıldığında).
  Stream<BoxEvent> watchChanges() => _box.watch();

  /// [assetId] için önbellekteki asset (thumbnail/detay görseli yüklemede kullanılır).
  AssetEntity? assetFor(String assetId) => _assetCache[assetId];

  /// Cihazdaki screenshot'ları Hive ile eşitler.
  /// Yeni asset'ler `pending` olarak eklenir, silinmiş asset kayıtları düşülür.
  /// Erişim yoksa [PhotoAccessDeniedException] fırlatır.
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
    // Boş liste dönülmez: erişimsizlik "hiç ekran görüntüsü yok" sanılmasın.
    if (!permission.hasAccess) throw const PhotoAccessDeniedException();

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
      logInfo('ScreenshotRepository: debug fallback — tüm görseller');
      final AssetPathEntity fallback = paths.first;
      final int count = await fallback.assetCountAsync;
      if (count == 0) return const [];
      return fallback.getAssetListRange(start: 0, end: count);
    }

    logInfo('ScreenshotRepository: Screenshots albümü bulunamadı/boş');
    return const [];
  }

  /// AI analiz sonucunu kaydeder. [aiCategory] modelin ham kararıdır; [category]
  /// kişiselleşme uygulandıysa farklı olabilir (bkz. analysis_queue_provider).
  Future<void> saveAnalysis({
    required String assetId,
    required ScreenshotCategory category,
    required ScreenshotCategory aiCategory,
    required List<String> tags,
    String? ocrText,
  }) async {
    final ScreenshotEntry? entry = _box.get(assetId);
    if (entry == null) return;
    entry
      ..category = category
      ..aiCategory = aiCategory
      ..tags = tags
      ..ocrText = ocrText
      ..analyzedAt = DateTime.now();
    await _box.put(assetId, entry);
  }

  /// [assetIds] kayıtlarını tek yazımda yeniden analize hazırlar:
  /// `analyzedAt` sıfırlanır, böylece [ScreenshotEntry.isPending] tekrar true
  /// olur ve analiz kuyruğu onları yeniden işler. Kategori korunur; yeni sonuç
  /// üzerine yazana kadar mevcut grupta görünmeye devam eder. Bulunamayan
  /// kimlikler atlanır.
  Future<void> markManyPending(Iterable<String> assetIds) async {
    final Map<String, ScreenshotEntry> changed = {
      for (final String assetId in assetIds)
        if (_box.get(assetId) case final ScreenshotEntry entry)
          assetId: entry..analyzedAt = null,
    };
    if (changed.isNotEmpty) await _box.putAll(changed);
  }

  /// [assetIds] kayıtlarını tek yazımda [boardId] panosuna taşır (null ise
  /// panodan çıkarır). Bulunamayan kimlikler atlanır.
  Future<void> assignManyToBoard(
    Iterable<String> assetIds,
    String? boardId,
  ) async {
    final Map<String, ScreenshotEntry> changed = {
      for (final String assetId in assetIds)
        if (_box.get(assetId) case final ScreenshotEntry entry)
          assetId: entry..boardId = boardId,
    };
    if (changed.isNotEmpty) await _box.putAll(changed);
  }

  /// Kaydın sistem kategorisini elle değiştirir (kullanıcı düzeltmesi/taşıması).
  /// Özel board'dan da çıkarır ki fotoğraf hedef kategoride görünsün. Kart
  /// henüz analiz edilmemişse (pending) elle kategorize edilince "işlendi"
  /// sayılır — böylece swipe kuyruğundan düşer.
  Future<void> setCategory(String assetId, ScreenshotCategory category) async {
    final ScreenshotEntry? entry = _box.get(assetId);
    if (entry == null) return;
    // AI'ın ilk kararını sabitle: sonraki düzeltmeler orijinali ezmesin.
    final ScreenshotCategory? aiOriginal = entry.aiCategory ?? entry.category;
    entry
      ..aiCategory = aiOriginal
      ..category = category
      ..boardId = null;
    entry.analyzedAt ??= DateTime.now();
    await _box.put(assetId, entry);
    // Kullanıcı gerçekten AI'ın kararını değiştirdiyse öğrenme sinyali kaydet.
    // En iyi çaba: yazım zaten başarılı, sinyal hatası taşımayı bozmamalı.
    if (aiOriginal != null && aiOriginal != category) {
      try {
        await onCorrection?.call(aiOriginal, category, entry.tags);
      } catch (error, stackTrace) {
        logError('Düzeltme sinyali kaydedilemedi', error, stackTrace);
      }
    }
  }

  /// Kaydın taşıma öncesi yerleşimini birebir geri yazar ("Geri al"). Taşıma
  /// sırasında kaydedilen kişiselleşme sinyali geri alınmaz; tek düzeltme
  /// öneri eşiğini tek başına aşamaz.
  Future<void> restorePlacement(ScreenshotPlacement placement) =>
      restorePlacements([placement]);

  /// [restorePlacement]'ın toplu hali: tüm yerleşimler tek yazımda döner.
  Future<void> restorePlacements(
    Iterable<ScreenshotPlacement> placements,
  ) async {
    final Map<String, ScreenshotEntry> changed = {
      for (final ScreenshotPlacement placement in placements)
        if (_box.get(placement.assetId) case final ScreenshotEntry entry)
          placement.assetId: entry
            ..category = placement.category
            ..aiCategory = placement.aiCategory
            ..analyzedAt = placement.analyzedAt
            ..boardId = placement.boardId,
    };
    if (changed.isNotEmpty) await _box.putAll(changed);
  }

  /// Metadata kaydını siler (cihazdan silme photo_manager editor ile ayrıca yapılır).
  Future<void> removeEntry(String assetId) => _box.delete(assetId);

  /// [assetIds] kayıtlarını tek yazımda siler.
  Future<void> removeEntries(Iterable<String> assetIds) async {
    final List<String> keys = assetIds.toList();
    if (keys.isNotEmpty) await _box.deleteAll(keys);
  }

  ScreenshotEntry? entryFor(String assetId) => _box.get(assetId);
}

/// Bir kaydın kategori/pano yerleşiminin anlık görüntüsü; taşımayı geri almak
/// için taşımadan önce alınır.
class ScreenshotPlacement {
  ScreenshotPlacement.of(ScreenshotEntry entry)
    : assetId = entry.assetId,
      category = entry.category,
      aiCategory = entry.aiCategory,
      analyzedAt = entry.analyzedAt,
      boardId = entry.boardId;

  final String assetId;
  final ScreenshotCategory? category;
  final ScreenshotCategory? aiCategory;
  final DateTime? analyzedAt;
  final String? boardId;
}

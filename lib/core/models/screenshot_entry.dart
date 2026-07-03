// Bir screenshot'ın local DB kaydı: asset referansı + AI analiz sonucu.
// Görselin kendisi cihazda (Photos) kalır; burada yalnız metadata tutulur.
import 'screenshot_category.dart';

/// Hive'da saklanan screenshot metadata'sı.
class ScreenshotEntry {
  ScreenshotEntry({
    required this.assetId,
    required this.createdAt,
    this.category,
    this.tags = const [],
    this.ocrText,
    this.analyzedAt,
    this.boardId,
  });

  /// photo_manager `AssetEntity.id` — Photos kütüphanesindeki kalıcı kimlik.
  final String assetId;

  /// Screenshot'ın çekildiği tarih (asset üzerinden).
  final DateTime createdAt;

  /// AI'ın atadığı kategori; analiz edilmediyse null.
  ScreenshotCategory? category;

  /// AI'ın ürettiği en fazla 3 etiket.
  List<String> tags;

  /// Görselden okunan metin (yoksa null).
  String? ocrText;

  /// Analizin tamamlandığı an; null ise analiz bekliyor.
  DateTime? analyzedAt;

  /// Kullanıcının atadığı özel board (yoksa null — sistem kategorisinde görünür).
  String? boardId;

  /// Analiz kuyruğunda bekleyip beklemediği.
  bool get isPending => analyzedAt == null;
}

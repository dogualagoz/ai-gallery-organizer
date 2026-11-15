// Analiz kuyruğunun değişmez durumu: tur durumu, sayaçlar, son tamamlananlar.
import 'package:flutter/foundation.dart';

import '../../../core/models/screenshot_category.dart';

/// Kuyruğun yaşam döngüsü durumları.
enum AnalysisQueueStatus {
  /// Kuyruk boşta; bekleyen varsa banner "analiz et" önerir.
  idle,

  /// Analiz sürüyor; ilerleme [AnalysisQueueState.done]/[AnalysisQueueState.total].
  running,

  /// Tur bitti (ya da iptal edildi); banner özet gösterir.
  completed,

  /// Denenen tüm istekler başarısız oldu (ağ/servis sorunu olasılığı yüksek).
  failed,

  /// Free analiz hakkı doldu; paywall önerilir.
  limitReached,

  /// Ücretsiz katmanın günlük istek tavanına ulaşıldı; yarın devam eder.
  dailyCapReached,
}

/// Başarıyla analiz edilen tek öğe — UI'daki "uçan thumbnail" animasyonunu
/// ve kategori yığın sayaçlarını besler.
class AnalyzedItem {
  const AnalyzedItem({required this.assetId, required this.category});

  final String assetId;
  final ScreenshotCategory category;

  @override
  bool operator ==(Object other) =>
      other is AnalyzedItem &&
      other.assetId == assetId &&
      other.category == category;

  @override
  int get hashCode => Object.hash(assetId, category);
}

/// Kuyruğun anlık görünümü (immutable).
class AnalysisQueueState {
  const AnalysisQueueState({
    this.status = AnalysisQueueStatus.idle,
    this.done = 0,
    this.failed = 0,
    this.total = 0,
    this.recent = const [],
    this.categoryCounts = const {},
    this.freeQuotaExhausted = false,
    this.active = const [],
  });

  /// [recent] listesinde tutulan en fazla öğe sayısı — animasyon için
  /// yalnız son tamamlananlar gerekir, sınırsız büyüme istenmez.
  static const int maxRecentItems = 16;

  final AnalysisQueueStatus status;

  /// Bu turda başarıyla analiz edilen sayı.
  final int done;

  /// Bu turda hata alan sayı.
  final int failed;

  /// Bu turda hedeflenen toplam (free'de kalan hakla sınırlı).
  final int total;

  /// Bu turda son tamamlanan öğeler (en eski → en yeni, en fazla
  /// [maxRecentItems]). UI diff'leyerek yeni tamamlananları animasyonla oynatır.
  final List<AnalyzedItem> recent;

  /// Bu turda kategori başına başarı sayısı (kategori yığınları için).
  final Map<ScreenshotCategory, int> categoryCounts;

  /// Tur [AnalysisQueueStatus.limitReached] ile bittiğinde haftalık free
  /// kotanın gerçekten tükendiğini ayırt eder (trial sınırı / kotasız
  /// başlama durumlarından farklı) — milestone sayfası yalnız bunda açılır.
  final bool freeQuotaExhausted;

  /// Şu an analiz edilen öğeler (başlama sırasıyla). İlerleme kartının
  /// küçük resmi ilkini gösterir: biten öğe oradan karosuna uçar.
  final List<String> active;

  /// [assetId] çıkarılmış [active] listesi.
  List<String> withoutActive(String assetId) => [
    for (final String id in active)
      if (id != assetId) id,
  ];

  bool get isRunning => status == AnalysisQueueStatus.running;

  /// Başarılı bir analiz sonrası yeni state: sayaç, sınırlı [recent] listesi
  /// ve kategori sayacı birlikte güncellenir (saf, test edilebilir).
  AnalysisQueueState afterSuccess(AnalyzedItem item) {
    final List<AnalyzedItem> appended = [...recent, item];
    return copyWith(
      done: done + 1,
      recent: appended.length > maxRecentItems
          ? appended.sublist(appended.length - maxRecentItems)
          : appended,
      categoryCounts: {
        ...categoryCounts,
        item.category: (categoryCounts[item.category] ?? 0) + 1,
      },
      // Uçuş ile küçük resmin değişimi aynı durumda: resim takılı kalmaz.
      active: withoutActive(item.assetId),
    );
  }

  /// Verilen alanları değiştirilmiş kopya.
  AnalysisQueueState copyWith({
    AnalysisQueueStatus? status,
    int? done,
    int? failed,
    int? total,
    List<AnalyzedItem>? recent,
    Map<ScreenshotCategory, int>? categoryCounts,
    bool? freeQuotaExhausted,
    List<String>? active,
  }) {
    return AnalysisQueueState(
      status: status ?? this.status,
      done: done ?? this.done,
      failed: failed ?? this.failed,
      total: total ?? this.total,
      recent: recent ?? this.recent,
      categoryCounts: categoryCounts ?? this.categoryCounts,
      freeQuotaExhausted: freeQuotaExhausted ?? this.freeQuotaExhausted,
      active: active ?? this.active,
    );
  }

  // Aynı değerle yeniden yazılan durum dinleyicileri boşuna yenilemez.
  @override
  bool operator ==(Object other) =>
      other is AnalysisQueueState &&
      other.status == status &&
      other.done == done &&
      other.failed == failed &&
      other.total == total &&
      other.freeQuotaExhausted == freeQuotaExhausted &&
      listEquals(other.recent, recent) &&
      mapEquals(other.categoryCounts, categoryCounts) &&
      listEquals(other.active, active);

  // Koleksiyonlar yalnız uzunluklarıyla katılır: eşitlikle tutarlı ve ucuz.
  @override
  int get hashCode => Object.hash(
    status,
    done,
    failed,
    total,
    freeQuotaExhausted,
    recent.length,
    categoryCounts.length,
    active.length,
  );
}

/// Tekil analiz denemesinin sonucu (detay ekranındaki "şimdi analiz et").
enum SingleAnalysisOutcome { success, limitReached, failed }

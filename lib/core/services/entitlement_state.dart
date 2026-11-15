// Kullanıcının anlık yetki durumu ve ondan türeyen saf kurallar: deneme
// penceresi, kalan haklar, haftalık yenilenme ve özellik kilitleri.
import '../constants/app_constants.dart';

/// Kullanıcının anlık yetki durumu.
class EntitlementState {
  const EntitlementState({
    required this.isPro,
    required this.aiAnalysisUsed,
    required this.swipesUsed,
    required this.weekStartMs,
    this.analysisCredits = 0,
    this.proPurchaseMs,
    this.proProductId,
    this.trialAnalysisUsed = 0,
  });

  /// Pro yetkisi (abonelik, lifetime ya da deneme) açık mı.
  final bool isPro;

  /// Pro satın almasının işlem zamanı (epoch ms) — trial penceresi hesabı için.
  final int? proPurchaseMs;

  /// Pro yetkisini veren ürün kimliği (trial yalnız yıllık planda var).
  final String? proProductId;

  /// Deneme penceresinde kullanılan analiz sayısı. Haftalık free sayaçtan
  /// bilinçli olarak ayrı: trial iptalinde kullanıcının free haftası bozulmaz.
  final int trialAnalysisUsed;

  /// Bu haftalık pencerede kullanılan otomatik AI analizi sayısı.
  final int aiAnalysisUsed;

  /// Aktif haftalık kota penceresinin başlangıcı (epoch ms).
  final int weekStartMs;

  /// Bu haftalık pencerede kullanılan manuel swipe sıralama sayısı.
  final int swipesUsed;

  /// Satın alınan analiz paketlerinden kalan kredi (free kota bitince kullanılır).
  final int analysisCredits;

  /// Deneme penceresi aktif mi: yıllık plan + satın almadan sonraki 7 gün.
  /// Bilinen trade-off: yeniden abone olan (Apple ikinci trial vermez) ilk
  /// 7 gün yine sınıra tabi olur — StoreKit intro-offer sorgusu için ek
  /// platform bağımlılığına değmeyecek kadar nadir bir durum.
  bool get isInTrialWindow {
    if (!isPro || proProductId != ProductIds.yearly) return false;
    final int? purchaseMs = proPurchaseMs;
    if (purchaseMs == null) return false;
    return DateTime.now().millisecondsSinceEpoch - purchaseMs <
        TrialLimits.window.inMilliseconds;
  }

  /// Deneme penceresinde kalan analiz hakkı.
  int get remainingTrialAnalysis => (TrialLimits.aiAnalysis - trialAnalysisUsed)
      .clamp(0, TrialLimits.aiAnalysis);

  /// Şu an en az bir analiz hakkı var mı.
  bool get canAnalyze {
    if (isPro) {
      return !isInTrialWindow || remainingTrialAnalysis + analysisCredits > 0;
    }
    return totalRemainingAnalysis > 0;
  }

  /// Şu an kaydırma hakkı var mı.
  bool get canSwipe => isPro || swipesUsed < FreeLimits.swipeSorts;

  /// Kalan ücretsiz analiz hakkı (Pro'da anlamsız, 0 altına düşmez).
  int get remainingFreeAnalysis =>
      (FreeLimits.aiAnalysis - aiAnalysisUsed).clamp(0, FreeLimits.aiAnalysis);

  /// Haftalık ücretsiz kotanın yenileneceği an.
  DateTime get nextWeeklyReset =>
      DateTime.fromMillisecondsSinceEpoch(weekStartMs)
          .add(FreeLimits.aiAnalysisWindow);

  /// Haftalık kotanın yenilenmesine kalan gün; yukarı yuvarlanır, pencere
  /// içinde en az 1 gösterilir.
  int get daysUntilWeeklyReset =>
      (nextWeeklyReset.difference(DateTime.now()).inHours /
              Duration.hoursPerDay)
          .ceil()
          .clamp(1, FreeLimits.aiAnalysisWindow.inDays);

  /// Free kota + satın alınan kredilerin toplamı.
  int get totalRemainingAnalysis => remainingFreeAnalysis + analysisCredits;

  /// Özel pano oluşturma artık tamamen Pro'ya özel.
  bool get canCreateBoards => isPro;

  /// Arama ve toplu silme yalnız Pro'da açık.
  bool get canSearch => isPro;
  bool get canBulkDelete => isPro;

  EntitlementState copyWith({
    bool? isPro,
    int? aiAnalysisUsed,
    int? swipesUsed,
    int? weekStartMs,
    int? analysisCredits,
    int? proPurchaseMs,
    String? proProductId,
    int? trialAnalysisUsed,
  }) {
    return EntitlementState(
      isPro: isPro ?? this.isPro,
      aiAnalysisUsed: aiAnalysisUsed ?? this.aiAnalysisUsed,
      swipesUsed: swipesUsed ?? this.swipesUsed,
      weekStartMs: weekStartMs ?? this.weekStartMs,
      analysisCredits: analysisCredits ?? this.analysisCredits,
      proPurchaseMs: proPurchaseMs ?? this.proPurchaseMs,
      proProductId: proProductId ?? this.proProductId,
      trialAnalysisUsed: trialAnalysisUsed ?? this.trialAnalysisUsed,
    );
  }

  // Aynı değerle yeniden yazılan durum dinleyicileri boşuna yenilemez.
  @override
  bool operator ==(Object other) =>
      other is EntitlementState &&
      other.isPro == isPro &&
      other.aiAnalysisUsed == aiAnalysisUsed &&
      other.swipesUsed == swipesUsed &&
      other.weekStartMs == weekStartMs &&
      other.analysisCredits == analysisCredits &&
      other.proPurchaseMs == proPurchaseMs &&
      other.proProductId == proProductId &&
      other.trialAnalysisUsed == trialAnalysisUsed;

  @override
  int get hashCode => Object.hash(
    isPro,
    aiAnalysisUsed,
    swipesUsed,
    weekStartMs,
    analysisCredits,
    proPurchaseMs,
    proProductId,
    trialAnalysisUsed,
  );
}

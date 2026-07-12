// Free/Pro yetki durumu ve free limit sayaçları (Bölüm 3 freemium modeli).
// IAP entegrasyonu isPro'yu ve analysisCredits'i buradan günceller.
import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import 'preferences_service.dart';

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

  /// Bugüne dek kullanılan manuel swipe sıralama sayısı.
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
  int get remainingTrialAnalysis =>
      (TrialLimits.aiAnalysis - trialAnalysisUsed).clamp(
        0,
        TrialLimits.aiAnalysis,
      );

  bool get canAnalyze {
    if (isPro) {
      return !isInTrialWindow ||
          remainingTrialAnalysis + analysisCredits > 0;
    }
    return totalRemainingAnalysis > 0;
  }

  bool get canSwipe => isPro || swipesUsed < FreeLimits.swipeSorts;

  /// Kalan ücretsiz analiz hakkı (Pro'da anlamsız, 0 altına düşmez).
  int get remainingFreeAnalysis =>
      (FreeLimits.aiAnalysis - aiAnalysisUsed).clamp(0, FreeLimits.aiAnalysis);

  /// Haftalık ücretsiz kotanın yenileneceği an.
  DateTime get nextWeeklyReset => DateTime.fromMillisecondsSinceEpoch(
    weekStartMs,
  ).add(FreeLimits.aiAnalysisWindow);

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
}

final entitlementProvider =
    NotifierProvider<EntitlementNotifier, EntitlementState>(
      EntitlementNotifier.new,
    );

class EntitlementNotifier extends Notifier<EntitlementState> {
  @override
  EntitlementState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int? storedWeekStart = prefs.getInt(PrefKeys.aiWeekStart);
    int weekStartMs = storedWeekStart ?? nowMs;
    int aiAnalysisUsed = prefs.getInt(PrefKeys.aiAnalysisUsed) ?? 0;

    // Migration (anahtar yok: ilk kurulum ya da ömürlük-kota sürümünden gelen
    // kullanıcı — taze haftalık kota alır) veya pencere süresi dolmuş: sıfırla.
    final bool expired =
        nowMs - weekStartMs >= FreeLimits.aiAnalysisWindow.inMilliseconds;
    if (storedWeekStart == null || expired) {
      weekStartMs = nowMs;
      aiAnalysisUsed = 0;
      unawaited(prefs.setInt(PrefKeys.aiWeekStart, weekStartMs));
      unawaited(prefs.setInt(PrefKeys.aiAnalysisUsed, 0));
    }

    return EntitlementState(
      isPro: prefs.getBool(PrefKeys.isPro) ?? false,
      aiAnalysisUsed: aiAnalysisUsed,
      swipesUsed: prefs.getInt(PrefKeys.swipesUsed) ?? 0,
      weekStartMs: weekStartMs,
      analysisCredits: prefs.getInt(PrefKeys.analysisCredits) ?? 0,
      proPurchaseMs: prefs.getInt(PrefKeys.proPurchaseMs),
      proProductId: prefs.getString(PrefKeys.proProductId),
      trialAnalysisUsed: prefs.getInt(PrefKeys.trialAnalysisUsed) ?? 0,
    );
  }

  /// Haftalık pencere süresi dolduysa free sayacı sıfırlayıp yeni pencere
  /// açar; dolmadıysa hiçbir şey yapmaz (idempotent). Krediler etkilenmez.
  /// [now] yalnız testlerde saat enjeksiyonu için kullanılır.
  void ensureWeeklyWindow({DateTime? now}) {
    final int nowMs = (now ?? DateTime.now()).millisecondsSinceEpoch;
    if (nowMs - state.weekStartMs < FreeLimits.aiAnalysisWindow.inMilliseconds) {
      return;
    }
    state = state.copyWith(weekStartMs: nowMs, aiAnalysisUsed: 0);
    final prefs = ref.read(sharedPreferencesProvider);
    unawaited(prefs.setInt(PrefKeys.aiWeekStart, nowMs));
    unawaited(prefs.setInt(PrefKeys.aiAnalysisUsed, 0));
  }

  /// IAP doğrulaması sonrası çağrılır (satın alma / restore / iptal).
  /// Pro kaldırılırken trial izleri de temizlenir — free haftası etkilenmez.
  Future<void> setPro(bool isPro) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (!isPro) {
      state = EntitlementState(
        isPro: false,
        aiAnalysisUsed: state.aiAnalysisUsed,
        swipesUsed: state.swipesUsed,
        weekStartMs: state.weekStartMs,
        analysisCredits: state.analysisCredits,
      );
      await prefs.remove(PrefKeys.proPurchaseMs);
      await prefs.remove(PrefKeys.proProductId);
      await prefs.remove(PrefKeys.trialAnalysisUsed);
    } else {
      state = state.copyWith(isPro: true);
    }
    await prefs.setBool(PrefKeys.isPro, isPro);
  }

  /// Satın alma/restore olayından Pro yetkisi verir; trial penceresi hesabı
  /// için ürün kimliği ve işlem zamanını saklar. Restore orijinal işlem
  /// tarihini getirdiğinden pencere reinstall sonrası da doğru hesaplanır.
  Future<void> setProFromPurchase({
    required String productId,
    int? purchaseMs,
  }) async {
    final int effectiveMs =
        purchaseMs ?? DateTime.now().millisecondsSinceEpoch;
    state = state.copyWith(
      isPro: true,
      proPurchaseMs: effectiveMs,
      proProductId: productId,
    );
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(PrefKeys.isPro, true);
    await prefs.setInt(PrefKeys.proPurchaseMs, effectiveMs);
    await prefs.setString(PrefKeys.proProductId, productId);
  }

  /// [count] adet analiz hakkı tüketir. Trial penceresinde önce trial
  /// sayacı, değilse önce free kota; taşan kısım her iki yolda kredilerden.
  Future<void> registerAnalysis(int count) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (state.isInTrialWindow) {
      final int trialUsed = min(count, state.remainingTrialAnalysis);
      final int creditUsed = count - trialUsed;
      state = state.copyWith(
        trialAnalysisUsed: state.trialAnalysisUsed + trialUsed,
        analysisCredits: (state.analysisCredits - creditUsed).clamp(
          0,
          state.analysisCredits,
        ),
      );
      await prefs.setInt(PrefKeys.trialAnalysisUsed, state.trialAnalysisUsed);
      await prefs.setInt(PrefKeys.analysisCredits, state.analysisCredits);
      return;
    }
    ensureWeeklyWindow();
    final int freeUsed = min(count, state.remainingFreeAnalysis);
    final int creditUsed = count - freeUsed;
    state = state.copyWith(
      aiAnalysisUsed: state.aiAnalysisUsed + freeUsed,
      analysisCredits: (state.analysisCredits - creditUsed).clamp(
        0,
        state.analysisCredits,
      ),
    );
    await prefs.setInt(PrefKeys.aiAnalysisUsed, state.aiAnalysisUsed);
    await prefs.setInt(PrefKeys.analysisCredits, state.analysisCredits);
  }

  /// Satın alınan analiz paketi teslimatı (Blok 5: consumable IAP).
  Future<void> addCredits(int amount) async {
    state = state.copyWith(analysisCredits: state.analysisCredits + amount);
    await ref
        .read(sharedPreferencesProvider)
        .setInt(PrefKeys.analysisCredits, state.analysisCredits);
  }

  /// Tek swipe hakkı tüketir.
  Future<void> registerSwipe() async {
    state = state.copyWith(swipesUsed: state.swipesUsed + 1);
    await ref
        .read(sharedPreferencesProvider)
        .setInt(PrefKeys.swipesUsed, state.swipesUsed);
  }

  /// Yalnız debug ayarlar ekranından çağrılır: free limit/paywall akışlarını
  /// baştan test edebilmek için kullanım sayaçlarını sıfırlar.
  Future<void> resetUsageForDebug() async {
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    state = state.copyWith(
      aiAnalysisUsed: 0,
      swipesUsed: 0,
      weekStartMs: nowMs,
      analysisCredits: 0,
      trialAnalysisUsed: 0,
    );
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(PrefKeys.aiAnalysisUsed, 0);
    await prefs.setInt(PrefKeys.swipesUsed, 0);
    await prefs.setInt(PrefKeys.aiWeekStart, nowMs);
    await prefs.setInt(PrefKeys.analysisCredits, 0);
    await prefs.setInt(PrefKeys.trialAnalysisUsed, 0);
  }
}

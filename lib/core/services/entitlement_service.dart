// Free/Pro yetki durumu ve free limit sayaçları (Bölüm 3 freemium modeli).
// IAP entegrasyonu isPro'yu ve analysisCredits'i buradan günceller.
import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../constants/redeem_constants.dart';
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
    this.proRedeemExpiryMs,
    this.trialAnalysisUsed = 0,
  });

  final bool isPro;

  /// Pro satın almasının işlem zamanı (epoch ms) — trial penceresi hesabı için.
  final int? proPurchaseMs;

  /// Pro yetkisini veren ürün kimliği (trial yalnız yıllık planda var).
  final String? proProductId;

  /// Redeem koduyla açılan Pro'nun bitiş anı (epoch ms). Yalnız redeem
  /// erişiminde dolu; gerçek satın almalarda null (o yüzden onlar süreye
  /// tabi değil).
  final int? proRedeemExpiryMs;

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

  bool get canAnalyze {
    if (isPro) {
      return !isInTrialWindow || remainingTrialAnalysis + analysisCredits > 0;
    }
    return totalRemainingAnalysis > 0;
  }

  bool get canSwipe => isPro || swipesUsed < FreeLimits.swipeSorts;

  /// Kalan ücretsiz analiz hakkı (Pro'da anlamsız, 0 altına düşmez).
  int get remainingFreeAnalysis =>
      (FreeLimits.aiAnalysis - aiAnalysisUsed).clamp(0, FreeLimits.aiAnalysis);

  /// Haftalık ücretsiz kotanın yenileneceği an.
  DateTime get nextWeeklyReset =>
      DateTime.fromMillisecondsSinceEpoch(weekStartMs)
          .add(FreeLimits.aiAnalysisWindow);

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
    int? proRedeemExpiryMs,
    bool clearRedeemExpiry = false,
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
      // Süre alanı null'a çekilebilmeli (copyWith `??` bunu yapamaz), bu
      // yüzden ayrı bir temizleme bayrağı var.
      proRedeemExpiryMs:
          clearRedeemExpiry ? null : (proRedeemExpiryMs ?? this.proRedeemExpiryMs),
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
    int swipesUsed = prefs.getInt(PrefKeys.swipesUsed) ?? 0;
    final bool expired =
        nowMs - weekStartMs >= FreeLimits.aiAnalysisWindow.inMilliseconds;
    if (storedWeekStart == null || expired) {
      weekStartMs = nowMs;
      aiAnalysisUsed = 0;
      swipesUsed = 0;
      unawaited(prefs.setInt(PrefKeys.aiWeekStart, weekStartMs));
      unawaited(prefs.setInt(PrefKeys.aiAnalysisUsed, 0));
      unawaited(prefs.setInt(PrefKeys.swipesUsed, 0));
    }

    // Redeem süresi dolmuşsa Pro'yu kapat: gerçek satın almalarda expiry
    // null olduğundan onlar etkilenmez. build() içinde state set edilemez;
    // temizliği microtask'e bırakırız (persist + notifier güncellemesi).
    bool isPro = prefs.getBool(PrefKeys.isPro) ?? false;
    int? redeemExpiryMs = prefs.getInt(PrefKeys.proRedeemExpiryMs);
    if (redeemExpiryMs != null && nowMs > redeemExpiryMs) {
      isPro = false;
      redeemExpiryMs = null;
      Future.microtask(_clearExpiredRedeem);
    }

    return EntitlementState(
      isPro: isPro,
      aiAnalysisUsed: aiAnalysisUsed,
      swipesUsed: swipesUsed,
      weekStartMs: weekStartMs,
      analysisCredits: prefs.getInt(PrefKeys.analysisCredits) ?? 0,
      proPurchaseMs: prefs.getInt(PrefKeys.proPurchaseMs),
      proProductId: prefs.getString(PrefKeys.proProductId),
      proRedeemExpiryMs: redeemExpiryMs,
      trialAnalysisUsed: prefs.getInt(PrefKeys.trialAnalysisUsed) ?? 0,
    );
  }

  /// build() sırasında süresi dolmuş bulunan redeem Pro'sunu kalıcılaştırır.
  Future<void> _clearExpiredRedeem() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(PrefKeys.isPro, false);
    await prefs.remove(PrefKeys.proRedeemExpiryMs);
    state = state.copyWith(isPro: false, clearRedeemExpiry: true);
  }

  /// Redeem süresi dolduysa Pro'yu düşürür; dolmadıysa/expiry yoksa hiçbir şey
  /// yapmaz (idempotent). [ensureWeeklyWindow] ile aynı yerlerden çağrılır.
  /// [now] yalnız testlerde saat enjeksiyonu içindir.
  void enforceRedeemWindow({DateTime? now}) {
    final int? expiry = state.proRedeemExpiryMs;
    if (expiry == null) return;
    final int nowMs = (now ?? DateTime.now()).millisecondsSinceEpoch;
    if (nowMs <= expiry) return;
    state = state.copyWith(isPro: false, clearRedeemExpiry: true);
    final prefs = ref.read(sharedPreferencesProvider);
    unawaited(prefs.setBool(PrefKeys.isPro, false));
    unawaited(prefs.remove(PrefKeys.proRedeemExpiryMs));
  }

  /// Yerel redeem kodunu doğrular; geçerliyse Pro'yu [RedeemConfig.duration]
  /// boyunca açar (tekrar geçerli kod girmek süreyi yeniler). Gerçek satın
  /// almayla Pro olan kullanıcıyı süreyle sınırlamaz.
  Future<RedeemOutcome> redeemCode(String raw) async {
    if (!RedeemCodes.isValid(raw)) return RedeemOutcome.invalid;
    if (state.isPro && state.proRedeemExpiryMs == null) {
      return RedeemOutcome.success;
    }
    final int expiryMs =
        DateTime.now().add(RedeemConfig.duration).millisecondsSinceEpoch;
    state = state.copyWith(isPro: true, proRedeemExpiryMs: expiryMs);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(PrefKeys.isPro, true);
    await prefs.setInt(PrefKeys.proRedeemExpiryMs, expiryMs);
    // Trial izleri temizlensin: redeem Pro'su yıllık-trial 250 sınırına düşmesin.
    await prefs.remove(PrefKeys.proProductId);
    await prefs.remove(PrefKeys.proPurchaseMs);
    return RedeemOutcome.success;
  }

  /// Haftalık pencere süresi dolduysa free analiz ve swipe sayaçlarını
  /// sıfırlayıp yeni pencere açar; dolmadıysa hiçbir şey yapmaz (idempotent).
  /// Krediler etkilenmez. [now] yalnız testlerde saat enjeksiyonu içindir.
  void ensureWeeklyWindow({DateTime? now}) {
    final int nowMs = (now ?? DateTime.now()).millisecondsSinceEpoch;
    if (nowMs - state.weekStartMs <
        FreeLimits.aiAnalysisWindow.inMilliseconds) {
      return;
    }
    state = state.copyWith(
      weekStartMs: nowMs,
      aiAnalysisUsed: 0,
      swipesUsed: 0,
    );
    final prefs = ref.read(sharedPreferencesProvider);
    unawaited(prefs.setInt(PrefKeys.aiWeekStart, nowMs));
    unawaited(prefs.setInt(PrefKeys.aiAnalysisUsed, 0));
    unawaited(prefs.setInt(PrefKeys.swipesUsed, 0));
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
      await prefs.remove(PrefKeys.proRedeemExpiryMs);
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
    final int effectiveMs = purchaseMs ?? DateTime.now().millisecondsSinceEpoch;
    // Gerçek satın alma redeem süresini geçersiz kılar: aksi halde 30 gün
    // sonra kalıcı Pro yanlışlıkla düşerdi.
    state = state.copyWith(
      isPro: true,
      proPurchaseMs: effectiveMs,
      proProductId: productId,
      clearRedeemExpiry: true,
    );
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(PrefKeys.isPro, true);
    await prefs.setInt(PrefKeys.proPurchaseMs, effectiveMs);
    await prefs.setString(PrefKeys.proProductId, productId);
    await prefs.remove(PrefKeys.proRedeemExpiryMs);
  }

  /// [count] adet analiz hakkı tüketir. Trial penceresinde önce trial
  /// sayacı, değilse önce free kota; taşan kısım her iki yolda kredilerden.
  /// Kalıcı Pro hiç sayaç düşürmez — abonelik iptal edilirse kullanıcının
  /// dokunulmamış haftalık free kotası ve kredileri aynen durur.
  Future<void> registerAnalysis(int count) async {
    if (state.isPro && !state.isInTrialWindow) return;
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

  /// Tek swipe hakkı tüketir. Pro'da (trial dahil) swipe sınırsızdır —
  /// sayaç düşmez ki iptal sonrası free haftası dokunulmamış kalsın.
  Future<void> registerSwipe() async {
    if (state.isPro) return;
    ensureWeeklyWindow();
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

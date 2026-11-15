// Free/Pro yetki durumu ve free limit sayaçları (Bölüm 3 freemium modeli).
// IAP entegrasyonu isPro'yu ve analysisCredits'i buradan günceller.
import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import 'entitlement_state.dart';
import 'preferences_service.dart';

export 'entitlement_state.dart';

/// Uygulamanın tek yetki kaynağı; sayaçlar SharedPreferences'ta kalıcı.
final entitlementProvider =
    NotifierProvider<EntitlementNotifier, EntitlementState>(
      EntitlementNotifier.new,
    );

/// Yetki durumunu yükler, sayaçları tüketir ve IAP sonuçlarını işler.
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

    return EntitlementState(
      isPro: prefs.getBool(PrefKeys.isPro) ?? false,
      aiAnalysisUsed: aiAnalysisUsed,
      swipesUsed: swipesUsed,
      weekStartMs: weekStartMs,
      analysisCredits: prefs.getInt(PrefKeys.analysisCredits) ?? 0,
      proPurchaseMs: prefs.getInt(PrefKeys.proPurchaseMs),
      proProductId: prefs.getString(PrefKeys.proProductId),
      trialAnalysisUsed: prefs.getInt(PrefKeys.trialAnalysisUsed) ?? 0,
    );
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

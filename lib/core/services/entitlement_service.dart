// Free/Pro yetki durumu ve free limit sayaçları (Bölüm 3 freemium modeli).
// IAP entegrasyonu isPro'yu ve analysisCredits'i buradan günceller.
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
    this.analysisCredits = 0,
  });

  final bool isPro;

  /// Bugüne dek kullanılan otomatik AI analizi sayısı.
  final int aiAnalysisUsed;

  /// Bugüne dek kullanılan manuel swipe sıralama sayısı.
  final int swipesUsed;

  /// Satın alınan analiz paketlerinden kalan kredi (free kota bitince kullanılır).
  final int analysisCredits;

  bool get canAnalyze => isPro || totalRemainingAnalysis > 0;

  bool get canSwipe => isPro || swipesUsed < FreeLimits.swipeSorts;

  /// Kalan ücretsiz analiz hakkı (Pro'da anlamsız, 0 altına düşmez).
  int get remainingFreeAnalysis =>
      (FreeLimits.aiAnalysis - aiAnalysisUsed).clamp(0, FreeLimits.aiAnalysis);

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
    int? analysisCredits,
  }) {
    return EntitlementState(
      isPro: isPro ?? this.isPro,
      aiAnalysisUsed: aiAnalysisUsed ?? this.aiAnalysisUsed,
      swipesUsed: swipesUsed ?? this.swipesUsed,
      analysisCredits: analysisCredits ?? this.analysisCredits,
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
    return EntitlementState(
      isPro: prefs.getBool(PrefKeys.isPro) ?? false,
      aiAnalysisUsed: prefs.getInt(PrefKeys.aiAnalysisUsed) ?? 0,
      swipesUsed: prefs.getInt(PrefKeys.swipesUsed) ?? 0,
      analysisCredits: prefs.getInt(PrefKeys.analysisCredits) ?? 0,
    );
  }

  /// IAP doğrulaması sonrası çağrılır (satın alma / restore / iptal).
  Future<void> setPro(bool isPro) async {
    state = state.copyWith(isPro: isPro);
    await ref.read(sharedPreferencesProvider).setBool(PrefKeys.isPro, isPro);
  }

  /// [count] adet analiz hakkı tüketir — önce free kota, taşan kısım kredilerden.
  Future<void> registerAnalysis(int count) async {
    final int freeUsed = min(count, state.remainingFreeAnalysis);
    final int creditUsed = count - freeUsed;
    state = state.copyWith(
      aiAnalysisUsed: state.aiAnalysisUsed + freeUsed,
      analysisCredits: (state.analysisCredits - creditUsed).clamp(
        0,
        state.analysisCredits,
      ),
    );
    final prefs = ref.read(sharedPreferencesProvider);
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
    state = state.copyWith(
      aiAnalysisUsed: 0,
      swipesUsed: 0,
      analysisCredits: 0,
    );
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(PrefKeys.aiAnalysisUsed, 0);
    await prefs.setInt(PrefKeys.swipesUsed, 0);
    await prefs.setInt(PrefKeys.analysisCredits, 0);
  }
}

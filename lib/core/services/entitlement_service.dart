// Free/Pro yetki durumu ve free limit sayaçları (Bölüm 3 freemium modeli).
// IAP entegrasyonu (Blok 7) isPro'yu buradan günceller.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import 'preferences_service.dart';

/// Kullanıcının anlık yetki durumu.
class EntitlementState {
  const EntitlementState({
    required this.isPro,
    required this.aiAnalysisUsed,
    required this.swipesUsed,
  });

  final bool isPro;

  /// Bugüne dek kullanılan otomatik AI analizi sayısı.
  final int aiAnalysisUsed;

  /// Bugüne dek kullanılan manuel swipe sıralama sayısı.
  final int swipesUsed;

  bool get canAnalyze => isPro || aiAnalysisUsed < FreeLimits.aiAnalysis;

  bool get canSwipe => isPro || swipesUsed < FreeLimits.swipeSorts;

  /// Kalan ücretsiz analiz hakkı (Pro'da anlamsız, 0 altına düşmez).
  int get remainingAnalysis =>
      (FreeLimits.aiAnalysis - aiAnalysisUsed).clamp(0, FreeLimits.aiAnalysis);

  /// [boardCount] mevcut özel board sayısıyken yeni board açılabilir mi?
  bool canCreateBoard(int boardCount) =>
      isPro || boardCount < FreeLimits.customBoards;

  /// Arama ve toplu silme yalnız Pro'da açık.
  bool get canSearch => isPro;
  bool get canBulkDelete => isPro;

  EntitlementState copyWith({
    bool? isPro,
    int? aiAnalysisUsed,
    int? swipesUsed,
  }) {
    return EntitlementState(
      isPro: isPro ?? this.isPro,
      aiAnalysisUsed: aiAnalysisUsed ?? this.aiAnalysisUsed,
      swipesUsed: swipesUsed ?? this.swipesUsed,
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
    );
  }

  /// IAP doğrulaması sonrası çağrılır (satın alma / restore / iptal).
  Future<void> setPro(bool isPro) async {
    state = state.copyWith(isPro: isPro);
    await ref.read(sharedPreferencesProvider).setBool(PrefKeys.isPro, isPro);
  }

  /// [count] adet analiz hakkı tüketir.
  Future<void> registerAnalysis(int count) async {
    state = state.copyWith(aiAnalysisUsed: state.aiAnalysisUsed + count);
    await ref
        .read(sharedPreferencesProvider)
        .setInt(PrefKeys.aiAnalysisUsed, state.aiAnalysisUsed);
  }

  /// Tek swipe hakkı tüketir.
  Future<void> registerSwipe() async {
    state = state.copyWith(swipesUsed: state.swipesUsed + 1);
    await ref
        .read(sharedPreferencesProvider)
        .setInt(PrefKeys.swipesUsed, state.swipesUsed);
  }
}

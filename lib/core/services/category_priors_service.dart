// Cihaz içi kişiselleşme: kullanıcının kategori düzeltmelerinden öğrenilen
// yerel "priors". Backend yok — her şey aynı cihazda kalır. Kullanıcı bir
// screenshot'ı elle başka kategoriye taşıdıkça, o screenshot'ın etiketleri o
// kategoriye oy verir; yeni analizlerde aynı etiketler net biçimde tekrar
// ederse AI'ın kararı bu öğrenilen kategoriyle güncellenir.
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../constants/ai_constants.dart';
import '../models/screenshot_category.dart';
import 'hive_service.dart';

/// Etiket → (kategori index → oy sayısı) eşlemesi.
typedef PriorsMap = Map<String, Map<int, int>>;

/// Priors üzerindeki saf (durumsuz) mantık — Hive'sız test edilebilir.
abstract final class CategoryPriors {
  /// Etiketleri normalize edilmiş, tekrarsız anahtarlara çevirir.
  static Iterable<String> keysFrom(List<String> tags) => tags
      .map((tag) => tag.trim().toLowerCase())
      .where((tag) => tag.isNotEmpty)
      .toSet();

  /// [from] → [to] düzeltmesini işleyip yeni bir priors haritası döndürür.
  /// Düzeltme yoksa ([from] == [to]) harita değişmeden döner.
  static PriorsMap record(
    PriorsMap current,
    ScreenshotCategory? from,
    ScreenshotCategory to,
    List<String> tags,
  ) {
    if (from == to) return current;
    final PriorsMap merged = {
      for (final MapEntry<String, Map<int, int>> e in current.entries)
        e.key: {...e.value},
    };
    for (final String key in keysFrom(tags)) {
      final Map<int, int> counts = merged[key] ?? <int, int>{};
      counts[to.index] = (counts[to.index] ?? 0) + 1;
      merged[key] = counts;
    }
    return merged;
  }

  /// [tags] için öğrenilmiş kategori önerisi; yeterince net sinyal yoksa null.
  /// Eşikler [AiConfig] içinde: toplam oy < minVotes ya da baskın kategori
  /// oranı < minDominance ise güvenli tarafta kalıp null döner (AI kararı
  /// korunur).
  static ScreenshotCategory? suggest(PriorsMap priors, List<String> tags) {
    final Map<int, int> votes = {};
    for (final String key in keysFrom(tags)) {
      final Map<int, int>? counts = priors[key];
      if (counts == null) continue;
      counts.forEach((category, n) {
        votes[category] = (votes[category] ?? 0) + n;
      });
    }
    if (votes.isEmpty) return null;

    final int total = votes.values.fold(0, (a, b) => a + b);
    if (total < AiConfig.personalizationMinVotes) return null;

    final MapEntry<int, int> best = votes.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    if (best.value / total < AiConfig.personalizationMinDominance) return null;
    if (best.key < 0 || best.key >= ScreenshotCategory.values.length) {
      return null;
    }
    return ScreenshotCategory.values[best.key];
  }
}

final categoryPriorsProvider =
    NotifierProvider<CategoryPriorsNotifier, PriorsMap>(
      CategoryPriorsNotifier.new,
    );

/// Priors'ı [HiveService.settings] box'ında JSON olarak kalıcılaştıran Notifier.
/// Yeni box/adapter gerekmez; mevcut şifreli settings box kullanılır.
class CategoryPriorsNotifier extends Notifier<PriorsMap> {
  static const String _key = 'category_priors';

  Box<dynamic> get _box => HiveService.settings;

  @override
  PriorsMap build() => _read();

  /// JSON string'ini çözer; bozuk/eksik veride boş harita döner.
  PriorsMap _read() {
    final dynamic stored = _box.get(_key);
    if (stored is! String || stored.isEmpty) return {};
    try {
      final dynamic decoded = jsonDecode(stored);
      if (decoded is! Map) return {};
      final PriorsMap result = {};
      decoded.forEach((tag, counts) {
        if (tag is! String || counts is! Map) return;
        final Map<int, int> parsed = {};
        counts.forEach((idx, n) {
          final int? index = int.tryParse(idx.toString());
          if (index != null && n is int) parsed[index] = n;
        });
        if (parsed.isNotEmpty) result[tag] = parsed;
      });
      return result;
    } catch (_) {
      return {};
    }
  }

  /// Kullanıcı düzeltmesini kaydeder ([from] AI kararı, [to] kullanıcının seçimi).
  Future<void> recordCorrection({
    required ScreenshotCategory? from,
    required ScreenshotCategory to,
    required List<String> tags,
  }) async {
    final PriorsMap merged = CategoryPriors.record(state, from, to, tags);
    if (identical(merged, state)) return;
    await _persist(merged);
    state = merged;
  }

  /// [tags] için öğrenilmiş kategori önerisi (yoksa null).
  ScreenshotCategory? suggest(List<String> tags) =>
      CategoryPriors.suggest(state, tags);

  Future<void> _persist(PriorsMap map) async {
    final Map<String, Map<String, int>> encodable = {
      for (final MapEntry<String, Map<int, int>> e in map.entries)
        e.key: {
          for (final MapEntry<int, int> c in e.value.entries)
            c.key.toString(): c.value,
        },
    };
    await _box.put(_key, jsonEncode(encodable));
  }
}

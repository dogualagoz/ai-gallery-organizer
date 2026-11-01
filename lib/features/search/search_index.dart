// Arama dizini: her kaydın etiket + OCR metni galeri değiştiğinde bir kez
// normalize edilir; tuş başına yalnız `contains` taraması kalır.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/screenshot_category.dart';
import '../../core/models/screenshot_entry.dart';
import '../../core/utils/text_normalize.dart';
import '../gallery/providers/gallery_provider.dart';

final RegExp _whitespace = RegExp(r'\s+');

/// Analiz edilmiş kayıtların aranabilir hali (bekleyenlerin metni yok).
class SearchIndex {
  SearchIndex(List<ScreenshotEntry> entries)
    : _entries = [
        for (final ScreenshotEntry entry in entries)
          if (!entry.isPending) entry,
      ] {
    for (final ScreenshotEntry entry in _entries) {
      _text[entry.assetId] = normalizeForSearch(
        '${entry.tags.join(' ')} ${entry.ocrText ?? ''}',
      );
    }
  }

  final List<ScreenshotEntry> _entries;
  final Map<String, String> _text = {};

  /// Dizin galeri değişene kadar sabit: öneriler her build'de yeniden
  /// sayılmasın.
  final Map<int, List<String>> _topTags = {};

  /// Aranacak kayıt yok (hiçbiri analiz edilmemiş).
  bool get isEmpty => _entries.isEmpty;

  /// Kayıtlarda geçen kategoriler.
  late final Set<ScreenshotCategory> categories = {
    for (final ScreenshotEntry entry in _entries) ?entry.category,
  };

  /// [query]'nin her kelimesi kaydın etiketlerinde, metninde ya da kategori
  /// adında geçiyorsa eşleşir (sıra fark etmez). [category] verilirse yalnız
  /// o kategori aranır; boş sorgu o kategorinin tamamını döndürür. Sonuçlar
  /// galeri sırasındadır. [nameOf] kategorinin görünen adını verir.
  List<ScreenshotEntry> search(
    String query, {
    ScreenshotCategory? category,
    required String Function(ScreenshotCategory) nameOf,
  }) {
    final List<String> words = normalizeForSearch(query)
        .split(_whitespace)
        .where((word) => word.isNotEmpty)
        .toList();
    final Map<ScreenshotCategory, String> names = {};
    bool matches(ScreenshotEntry entry) {
      final ScreenshotCategory? own = entry.category;
      final String text = _text[entry.assetId] ?? '';
      final String name = own == null
          ? ''
          : names.putIfAbsent(own, () => normalizeForSearch(nameOf(own)));
      return words.every((word) => text.contains(word) || name.contains(word));
    }

    return [
      for (final ScreenshotEntry entry in _entries)
        if ((category == null || entry.category == category) && matches(entry))
          entry,
    ];
  }

  /// En sık geçen [limit] etiket, çoktan aza; eşitlikte önce görülen önce.
  /// Yazımı farklı aynı etiketler tek sayılır, ilk görülen yazım gösterilir.
  List<String> topTags(int limit) =>
      _topTags.putIfAbsent(limit, () => _countTags(limit));

  List<String> _countTags(int limit) {
    final Map<String, String> display = {};
    final Map<String, int> counts = {};
    for (final ScreenshotEntry entry in _entries) {
      for (final String tag in entry.tags) {
        final String trimmed = tag.trim();
        if (trimmed.isEmpty) continue;
        final String key = normalizeForSearch(trimmed);
        display.putIfAbsent(key, () => trimmed);
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    // List.sort kararlı değil: eşitlik ilk görülme sırasıyla açıkça bozulur.
    final List<String> keys = counts.keys.toList();
    final Map<String, int> firstSeen = {
      for (int i = 0; i < keys.length; i++) keys[i]: i,
    };
    keys.sort((a, b) {
      final int byCount = counts[b]!.compareTo(counts[a]!);
      return byCount != 0 ? byCount : firstSeen[a]!.compareTo(firstSeen[b]!);
    });
    return [for (final String key in keys.take(limit)) display[key]!];
  }
}

/// Galeriden kurulan arama dizini (galeri değişince yenilenir).
final searchIndexProvider = Provider<SearchIndex>(
  (ref) => SearchIndex(ref.watch(galleryProvider).value ?? const []),
);

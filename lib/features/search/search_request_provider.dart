// Başka ekrandan gelen arama isteği (ör. görüntüleyicide etikete dokunma):
// Ara sekmesi isteği alıp alanı doldurur.
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tek arama isteği. [serial] aynı sorgunun art arda istenmesini de yeni
/// istek olarak ayırt eder.
class SearchRequest {
  const SearchRequest(this.query, this.serial);

  final String query;
  final int serial;
}

/// Bekleyen arama isteği; Ara sekmesi uygulayınca temizler.
final searchRequestProvider =
    NotifierProvider<SearchRequestNotifier, SearchRequest?>(
      SearchRequestNotifier.new,
    );

/// Arama isteklerini sıra numarasıyla yayınlar.
class SearchRequestNotifier extends Notifier<SearchRequest?> {
  @override
  SearchRequest? build() => null;

  /// Ara sekmesinin [query] ile açılmasını ister (gezinme çağıranda kalır).
  void request(String query) =>
      state = SearchRequest(query, (state?.serial ?? 0) + 1);

  /// İstek uygulandı: sekme yeniden kurulsa da eski sorgu tekrar gelmez.
  void clear() => state = null;
}

// Kullanıcının oluşturduğu özel board (koleksiyon) modeli.

/// Kullanıcı tanımlı board — sistem kategorilerinden ayrıdır.
class Board {
  Board({
    required this.id,
    required this.name,
    required this.createdAt,
    this.sortOrder = 0,
  });

  /// Benzersiz kimlik (uuid).
  final String id;

  /// Kullanıcının verdiği ad.
  String name;

  final DateTime createdAt;

  /// Kullanıcının sürükleyerek belirlediği görüntülenme sırası (küçük = önce).
  /// Eski kayıtlarda 0'dır; ilk yeniden sıralamadan sonra benzersiz değer alır.
  int sortOrder;
}

// Kullanıcının oluşturduğu özel board (koleksiyon) modeli.

/// Kullanıcı tanımlı board — sistem kategorilerinden ayrıdır.
class Board {
  Board({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  /// Benzersiz kimlik (uuid).
  final String id;

  /// Kullanıcının verdiği ad.
  String name;

  final DateTime createdAt;
}

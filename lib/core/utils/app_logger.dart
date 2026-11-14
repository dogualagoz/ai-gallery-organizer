// Ortak log noktası: hatalar ve bilgi mesajları tek yerden geçer.
import 'package:flutter/foundation.dart';

/// Yakalanan bir hatayı bağlamıyla loglar. Crash raporlama ileride yalnız
/// burada bağlanır.
void logError(String context, Object error, [StackTrace? stackTrace]) {
  debugPrint(
    stackTrace == null ? '$context: $error' : '$context: $error\n$stackTrace',
  );
}

/// Hata olmayan, teşhis için yararlı durum mesajı.
void logInfo(String message) => debugPrint(message);

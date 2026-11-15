// Olay patlamalarını tek yenilemeye indiren, provider ömrüne bağlı dinleyici.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';

/// [changes] akışını dinler; olaylar [delay] boyunca kesilince [onSettled]'ı
/// bir kez çağırır (son olaydan sonra). Abonelik ve bekleyen zamanlayıcı
/// [ref] dispose olunca kapanır.
void listenDebounced(
  Ref ref,
  Stream<Object?> changes,
  VoidCallback onSettled, {
  Duration delay = StorageTimings.reloadDebounce,
}) {
  Timer? debounce;
  final StreamSubscription<Object?> subscription = changes.listen((_) {
    debounce?.cancel();
    debounce = Timer(delay, onSettled);
  });
  ref.onDispose(() {
    unawaited(subscription.cancel());
    debounce?.cancel();
  });
}

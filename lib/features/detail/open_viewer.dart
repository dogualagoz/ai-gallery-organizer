// Görüntüleyiciyi açmanın tek yolu: açıldığı koleksiyon (kaydırma kapsamı)
// rotaya iliştirilir, böylece görüntüleyici aynı sırayla sağa/sola kayar.
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';

/// Görüntüleyicide kaydırılabilen sıralı koleksiyon. Rota ekiyle (extra)
/// taşınır; deep link'te bulunmaz, görüntüleyici tek görselle açılır.
class ViewerScope {
  const ViewerScope(this.assetIds);

  final List<String> assetIds;
}

/// [assetId]'yi görüntüleyicide açar. [scope] verilirse görüntüleyici bu
/// sıradaki komşulara kaydırılabilir.
void openViewer(BuildContext context, String assetId, {List<String>? scope}) {
  context.push(
    AppRoutes.detail(assetId),
    extra: scope == null ? null : ViewerScope(scope),
  );
}

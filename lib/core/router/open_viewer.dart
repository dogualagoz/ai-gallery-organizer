// Görüntüleyiciyi açmanın tek yolu: açıldığı koleksiyon (kaydırma kapsamı)
// rotaya iliştirilir, böylece görüntüleyici aynı sırayla sağa/sola kayar.
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

/// [assetId]'yi görüntüleyicide açar. [scope] verilirse görüntüleyici bu
/// sıradaki komşulara kaydırılabilir.
void openViewer(BuildContext context, String assetId, {List<String>? scope}) {
  context.push(
    AppRoutes.detail(assetId),
    extra: scope == null ? null : ViewerScope(scope),
  );
}

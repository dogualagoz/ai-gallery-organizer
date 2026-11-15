// Galeri yüklenemediğinde ekranların ortak hata görünümü.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/services/photo_permission_service.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../providers/gallery_provider.dart';

/// [error] fotoğraf izni reddiyse Ayarlar'a yönlendiren görünüm, değilse
/// "Yeniden dene" ile galeriyi yeniden yükleyen hata durumu.
class GalleryErrorView extends ConsumerWidget {
  const GalleryErrorView({super.key, required this.error});

  /// `galleryProvider`'ın hata değeri.
  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (error is PhotoAccessDeniedException) {
      return const PermissionDeniedView();
    }
    final l10n = context.l10n;
    return EmptyStateView(
      icon: AppIcons.error,
      title: l10n.galleryLoadFailedTitle,
      message: l10n.galleryLoadFailedBody,
      actionLabel: l10n.retryAction,
      onAction: () => ref.invalidate(galleryProvider),
    );
  }
}

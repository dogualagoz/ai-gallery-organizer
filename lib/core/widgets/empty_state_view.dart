// Tek boş durum bileşeni (iOS ContentUnavailableView karşılığı) + fotoğraf
// izni reddedildiğinde Ayarlar'a götüren varyant.
import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../constants/ui_constants.dart';
import '../l10n/l10n_extension.dart';
import '../services/photo_permission_service.dart';

/// Ortalanmış ikon + başlık + açıklama + en fazla iki aksiyon. Kaydırılabilir
/// sayfada `SliverFillRemaining(hasScrollBody: false)` içine konur.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final IconData icon;
  final String title;
  final String? message;

  /// Birincil aksiyon (dolgulu buton).
  final String? actionLabel;
  final VoidCallback? onAction;

  /// İkincil aksiyon (metin buton, ör. "Şimdilik geç").
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final String? body = message;
    final String? primary = actionLabel;
    final String? secondary = secondaryActionLabel;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppEmptyState.maxTextWidth,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: AppEmptyState.iconSize,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: text.headlineSmall,
              ),
              if (body != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (primary != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.lg),
                FilledButton(onPressed: onAction, child: Text(primary)),
              ],
              if (secondary != null && onSecondaryAction != null) ...[
                const SizedBox(height: AppSpacing.xs),
                TextButton(
                  onPressed: onSecondaryAction,
                  child: Text(secondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Fotoğraf erişimi yok/iptal edildi: boş galeriyle karışmasın diye ayrı
/// anlatılır ve tek dokunuşla sistem Ayarları açılır.
class PermissionDeniedView extends StatelessWidget {
  const PermissionDeniedView({super.key, this.skipLabel, this.onSkip});

  /// Opsiyonel "Şimdilik geç" (onboarding'de kullanılır).
  final String? skipLabel;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return EmptyStateView(
      icon: AppIcons.privacy,
      title: l10n.permissionDeniedTitle,
      message: l10n.permissionDeniedBody,
      actionLabel: l10n.openSettings,
      onAction: PhotoPermissionService.openSystemSettings,
      secondaryActionLabel: skipLabel,
      onSecondaryAction: onSkip,
    );
  }
}

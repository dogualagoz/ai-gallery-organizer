// Kütüphane bölümleri: kategoriler ve panolar (başlıkta görünür Düzenle/Bitti),
// "Son eklenenler" önizlemesi (başlıkta "Tümü") ve sınırlı erişim bandı.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/models/board.dart';
import '../../../core/models/screenshot_category.dart';
import '../../../core/models/screenshot_entry.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/category_names_service.dart';
import '../../../core/services/category_order_service.dart';
import '../../../core/services/entitlement_service.dart';
import '../../../core/services/photo_permission_service.dart';
import '../../../core/widgets/status_toast.dart';
import '../../../core/widgets/surface_card.dart';
import '../../boards/providers/board_provider.dart';
import '../../boards/widgets/custom_boards_grid.dart';
import '../../boards/widgets/system_boards_grid.dart';
import '../../gallery/data/screenshot_repository.dart';
import '../../gallery/providers/gallery_provider.dart';
import '../../gallery/widgets/screenshot_grid.dart';

/// Bölüm başlığı: Title 3 metin + sağda opsiyonel metin eylemi.
class LibrarySectionHeader extends StatelessWidget {
  const LibrarySectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final String? label = actionLabel;
    return SizedBox(
      height: kMinInteractiveDimensionCupertino,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (label != null)
            CupertinoButton(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              minimumSize: const Size.square(kMinInteractiveDimensionCupertino),
              onPressed: onAction,
              child: Text(label),
            ),
        ],
      ),
    );
  }
}

/// Kategoriler ve panolar başlıklarının paylaştığı Düzenle/Bitti eylemi.
class _EditToggle {
  const _EditToggle(this.ref, this.editing);

  final WidgetRef ref;
  final bool editing;

  String label(BuildContext context) =>
      editing ? context.l10n.boardsEditDone : context.l10n.boardsEditAction;

  void toggle() {
    final BoardsEditModeNotifier mode = ref.read(
      boardsEditModeProvider.notifier,
    );
    editing ? mode.disable() : mode.enable();
  }
}

/// İçeriği olan sistem kategorileri, kayıtlı kullanıcı sırasıyla.
class LibraryCategoriesSection extends ConsumerWidget {
  const LibraryCategoriesSection({super.key, required this.entries});

  final List<ScreenshotEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final _EditToggle edit = _EditToggle(
      ref,
      ref.watch(boardsEditModeProvider),
    );
    final List<ScreenshotCategory> nonEmpty = [
      for (final ScreenshotCategory category in ScreenshotCategory.values)
        if (entries.any((entry) => entry.category == category)) category,
    ];
    ref.watch(categoryOrderProvider);
    final List<ScreenshotCategory> sorted = ref
        .read(categoryOrderProvider.notifier)
        .sortVisible(nonEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LibrarySectionHeader(
          title: l10n.boardsSystemSection,
          actionLabel: sorted.isEmpty ? null : edit.label(context),
          onAction: edit.toggle,
        ),
        const SizedBox(height: AppSpacing.xs),
        if (sorted.isEmpty)
          Text(
            l10n.boardsEmptyHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        else
          SystemBoardsGrid(
            categories: sorted,
            entries: entries,
            repo: ref.watch(screenshotRepositoryProvider),
            categoryNames: ref.watch(categoryNamesProvider),
          ),
      ],
    );
  }
}

/// Kullanıcı panoları + "Yeni pano".
class LibraryBoardsSection extends ConsumerWidget {
  const LibraryBoardsSection({super.key, required this.entries});

  final List<ScreenshotEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _EditToggle edit = _EditToggle(
      ref,
      ref.watch(boardsEditModeProvider),
    );
    final List<Board> boards = ref.watch(boardsProvider).value ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LibrarySectionHeader(
          title: context.l10n.boardsCustomSection,
          actionLabel: boards.isEmpty ? null : edit.label(context),
          onAction: edit.toggle,
        ),
        const SizedBox(height: AppSpacing.xs),
        CustomBoardsGrid(
          boards: boards,
          entries: entries,
          repo: ref.watch(screenshotRepositoryProvider),
          canCreate: ref.watch(entitlementProvider).canCreateBoards,
        ),
      ],
    );
  }
}

/// "Son eklenenler" başlığı; önizlemeden fazlası varsa "Tümü" ile tam liste.
class LibraryRecentsHeader extends StatelessWidget {
  const LibraryRecentsHeader({super.key, required this.hasMore});

  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    return LibrarySectionHeader(
      title: context.l10n.homeRecentsSection,
      actionLabel: hasMore ? context.l10n.librarySeeAll : null,
      onAction: () => context.push(AppRoutes.recents),
    );
  }
}

/// Son eklenenlerin iki satırlık önizleme ızgarası (kart içi stil).
class LibraryRecentsGrid extends StatelessWidget {
  const LibraryRecentsGrid({super.key, required this.entries});

  final List<ScreenshotEntry> entries;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      sliver: ScreenshotGrid(
        entries: entries.take(kLibraryRecentsLimit).toList(),
        inset: true,
      ),
    );
  }
}

/// Sınırlı fotoğraf erişiminde: neden bazı ekran görüntülerinin görünmediği
/// + sistemin seçicisini açan "Daha fazla seç".
class LimitedAccessBanner extends ConsumerWidget {
  const LimitedAccessBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool limited =
        ref.watch(photoAccessProvider).value == PhotoAccess.limited;
    if (!limited) return const SizedBox.shrink();

    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SurfaceCard(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(
              AppIcons.info,
              size: AppSizes.statusIcon,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
            Expanded(
              child: Text(
                l10n.limitedAccessBody,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              minimumSize: const Size.square(kMinInteractiveDimensionCupertino),
              onPressed: () => _selectMore(context, ref),
              child: Text(l10n.limitedAccessAction),
            ),
          ],
        ),
      ),
    );
  }

  /// Seçici kapanınca yeni seçilenler eşitlenir.
  Future<void> _selectMore(BuildContext context, WidgetRef ref) async {
    final String failure = context.l10n.gallerySyncFailed;
    try {
      await PhotoPermissionService.presentLimitedPicker();
      if (!context.mounted) return;
      await ref.read(galleryProvider.notifier).sync();
    } catch (error, stackTrace) {
      debugPrint('Sınırlı erişim seçimi eşitlenemedi: $error\n$stackTrace');
      if (!context.mounted) return;
      showStatusToast(context, failure, tone: StatusToastTone.error);
    }
  }
}

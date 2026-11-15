// Kütüphane bölümleri: kategoriler ve panolar (başlıkta görünür Düzenle/Bitti),
// "Son eklenenler" önizlemesi (başlıkta "Tümü") ve sınırlı erişim bandı.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/models/board.dart';
import '../../../core/models/screenshot_category.dart';
import '../../../core/models/screenshot_entry.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/category_names_service.dart';
import '../../../core/services/entitlement_service.dart';
import '../../../core/services/photo_permission_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/widgets/inline_text_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_card.dart';
import '../../../core/widgets/status_toast.dart';
import '../../boards/providers/board_provider.dart';
import '../../boards/widgets/custom_boards_grid.dart';
import '../../boards/widgets/system_boards_grid.dart';
import '../../gallery/data/screenshot_repository.dart';
import '../../gallery/providers/gallery_derived_providers.dart';
import '../../gallery/providers/gallery_provider.dart';
import '../../gallery/widgets/screenshot_grid.dart';

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
  const LibraryCategoriesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final _EditToggle edit = _EditToggle(
      ref,
      ref.watch(boardsEditModeProvider),
    );
    final List<ScreenshotCategory> sorted = ref.watch(
      visibleCategoriesProvider,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
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
            repo: ref.watch(screenshotRepositoryProvider),
            categoryNames: ref.watch(categoryNamesProvider),
          ),
      ],
    );
  }
}

/// Kullanıcı panoları + "Yeni pano".
class LibraryBoardsSection extends ConsumerWidget {
  const LibraryBoardsSection({super.key});

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
        SectionHeader(
          title: context.l10n.boardsCustomSection,
          actionLabel: boards.isEmpty ? null : edit.label(context),
          onAction: edit.toggle,
        ),
        const SizedBox(height: AppSpacing.xs),
        CustomBoardsGrid(
          boards: boards,
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
    return SectionHeader(
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: StatusCard(
        icon: AppIcons.info,
        muted: true,
        subtitle: l10n.limitedAccessBody,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.xs,
        ),
        trailing: InlineTextButton(
          label: l10n.limitedAccessAction,
          onPressed: () => _selectMore(context, ref),
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
      logError('Sınırlı erişim seçimi eşitlenemedi', error, stackTrace);
      if (!context.mounted) return;
      showStatusToast(context, failure, tone: StatusToastTone.error);
    }
  }
}

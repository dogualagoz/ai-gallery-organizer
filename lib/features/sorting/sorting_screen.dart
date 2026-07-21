// Swipe sıralama ekranı: analiz edilmemiş/"diğer" screenshot'lar için
// sola sil / sağa panoya ata / yukarı atla kart akışı.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/constants/ui_constants.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/board.dart';
import '../../core/models/screenshot_category.dart';
import '../../core/models/screenshot_entry.dart';
import '../../core/router/app_router.dart';
import '../../core/services/entitlement_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/review_service.dart';
import '../boards/providers/board_provider.dart';
import '../boards/widgets/board_name_dialog.dart';
import '../gallery/data/screenshot_repository.dart';
import '../gallery/providers/gallery_provider.dart';
import 'widgets/swipe_card.dart';

/// Board seçici sheet'inde "yeni pano oluştur" satırını işaretleyen sentinel.
const String _createNewBoardSentinel = '__create_new_board__';

class SortingScreen extends ConsumerStatefulWidget {
  const SortingScreen({super.key});

  @override
  ConsumerState<SortingScreen> createState() => _SortingScreenState();
}

/// Bu oturumdaki tek swipe hareketi — "Geri al" için kaydedilir.
enum _SwipeType { delete, skip, assign }

class _SwipeAction {
  const _SwipeAction(this.type, this.assetId);

  final _SwipeType type;
  final String assetId;
}

class _SortingScreenState extends ConsumerState<SortingScreen> {
  /// Bu oturumda "atla" denen kartlar — kalıcı değil, ekran kapanınca sıfırlanır.
  final Set<String> _skippedIds = {};

  /// Sola kaydırılıp silmeye kuyruklanan (henüz silinMEmiş) kartlar. Tek iOS
  /// onayıyla toplu silinmek üzere biriktirilir.
  final Set<String> _pendingDeletes = {};

  /// Son swipe'ları geri almak için hareket geçmişi.
  final List<_SwipeAction> _history = [];

  /// Toplu silme sürerken tekrar tetiklenmeyi önler.
  bool _finishing = false;

  /// Alttaki aksiyon butonlarının üstteki karta jest gönderebilmesi için.
  final SwipeCardController _cardController = SwipeCardController();

  @override
  void initState() {
    super.initState();
    // 7 gün boşta kalan kullanıcı ekrana taze haftalık swipe kotasıyla girsin.
    ref.read(entitlementProvider.notifier).ensureWeeklyWindow();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final EntitlementState entitlement = ref.watch(entitlementProvider);
    final List<ScreenshotEntry> entries =
        ref.watch(galleryProvider).value ?? const [];
    final ScreenshotRepository repo = ref.watch(screenshotRepositoryProvider);

    final List<ScreenshotEntry> queue = entries
        .where(
          (entry) =>
              entry.boardId == null &&
              (entry.isPending || entry.category == ScreenshotCategory.other) &&
              !_skippedIds.contains(entry.assetId) &&
              !_pendingDeletes.contains(entry.assetId),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sortingTitle),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              tooltip: l10n.sortingUndo,
              icon: const Icon(Icons.undo),
              onPressed: _undo,
            ),
          if (_pendingDeletes.isNotEmpty)
            TextButton.icon(
              onPressed: _finishing ? null : _finishDeletes,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(l10n.sortingFinishAction(_pendingDeletes.length)),
            ),
        ],
      ),
      body: !entitlement.canSwipe
          ? const _SortingLimit()
          : queue.isEmpty
          ? (_pendingDeletes.isEmpty
                ? const _SortingEmpty()
                : _SortingFinishPrompt(
                    count: _pendingDeletes.length,
                    deleting: _finishing,
                    onFinish: _finishDeletes,
                  ))
          : _SortingDeck(
              top: queue.first,
              next: queue.length > 1 ? queue[1] : null,
              remaining: queue.length,
              pendingDeleteCount: _pendingDeletes.length,
              asset: repo.assetFor(queue.first.assetId),
              controller: _cardController,
              onDelete: () => _queueDelete(queue.first.assetId),
              onSkip: () => _skipCard(queue.first.assetId),
              onAssign: () => _handleAssign(queue.first.assetId),
            ),
    );
  }

  /// Sola kaydırma: hemen silmez, silinecekler kümesine ekler (tek onay için).
  Future<bool> _queueDelete(String assetId) async {
    Haptics.confirm();
    setState(() {
      _pendingDeletes.add(assetId);
      _history.add(_SwipeAction(_SwipeType.delete, assetId));
    });
    await ref.read(entitlementProvider.notifier).registerSwipe();
    return true; // kart uçup gitsin; gerçek silme "Bitir"de yapılır
  }

  void _skipCard(String assetId) {
    Haptics.tap();
    setState(() {
      _skippedIds.add(assetId);
      _history.add(_SwipeAction(_SwipeType.skip, assetId));
    });
  }

  /// Son hareketi geri alır: silme/atlama kuyruğundan çıkarır, atamayı bozar.
  Future<void> _undo() async {
    if (_history.isEmpty) return;
    Haptics.tap();
    final _SwipeAction action = _history.removeLast();
    switch (action.type) {
      case _SwipeType.delete:
        setState(() => _pendingDeletes.remove(action.assetId));
      case _SwipeType.skip:
        setState(() => _skippedIds.remove(action.assetId));
      case _SwipeType.assign:
        // Atama öncesi kart kuyrukta (boardId == null) olduğundan geri alınca
        // board'dan çıkarılır ve deste başına yeniden düşer.
        await ref
            .read(screenshotRepositoryProvider)
            .assignToBoard(action.assetId, null);
        if (mounted) setState(() {});
    }
  }

  /// Biriken silme kuyruğunu tek deleteWithIds çağrısıyla (tek iOS onayı) siler.
  Future<void> _finishDeletes() async {
    if (_pendingDeletes.isEmpty || _finishing) return;
    final l10n = context.l10n;
    final int count = _pendingDeletes.length;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.sortingFinishConfirmTitle(count)),
        content: Text(l10n.sortingFinishConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.sortingFinishKeep),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.sortingFinishAction(count)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _finishing = true);
    final List<String> ids = _pendingDeletes.toList();
    List<String> deleted;
    try {
      deleted = await PhotoManager.editor.deleteWithIds(ids);
    } catch (error, stackTrace) {
      debugPrint('Toplu swipe sil hatası: $error\n$stackTrace');
      if (mounted) {
        setState(() => _finishing = false);
        _showSnack(l10n.sortingDeleteFailed);
      }
      return;
    }
    final ScreenshotRepository repo = ref.read(screenshotRepositoryProvider);
    for (final String assetId in deleted) {
      await repo.removeEntry(assetId);
    }
    if (!mounted) return;
    setState(() {
      _finishing = false;
      _pendingDeletes.removeAll(deleted);
      _history.removeWhere(
        (a) => a.type == _SwipeType.delete && deleted.contains(a.assetId),
      );
    });
    // Temizlik sonrası olumlu an: değerlendirme iste (cooldown'lı).
    if (deleted.isNotEmpty) {
      ref.read(reviewServiceProvider).requestIfAppropriate();
    }
  }

  Future<void> _handleAssign(String assetId) async {
    final List<Board> boards = ref.read(boardsProvider).value ?? const [];
    final String? choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _BoardPickerSheet(boards: boards),
    );
    if (choice == null || !mounted) return;

    if (choice == _createNewBoardSentinel) {
      await _createBoardAndAssign(assetId);
      return;
    }
    Haptics.tick();
    await ref.read(screenshotRepositoryProvider).assignToBoard(assetId, choice);
    await ref.read(entitlementProvider.notifier).registerSwipe();
    if (mounted) {
      setState(() => _history.add(_SwipeAction(_SwipeType.assign, assetId)));
    }
  }

  Future<void> _createBoardAndAssign(String assetId) async {
    final l10n = context.l10n;
    if (!ref.read(entitlementProvider).canCreateBoards) {
      if (mounted) context.push(AppRoutes.paywall);
      return;
    }
    final String? name = await showDialog<String>(
      context: context,
      builder: (_) => BoardNameDialog(
        title: l10n.boardsNewBoardDialogTitle,
        confirmLabel: l10n.boardsCreateAction,
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;
    final Board created = await ref.read(boardsProvider.notifier).create(name);
    await ref
        .read(screenshotRepositoryProvider)
        .assignToBoard(assetId, created.id);
    await ref.read(entitlementProvider.notifier).registerSwipe();
    if (mounted) {
      setState(() => _history.add(_SwipeAction(_SwipeType.assign, assetId)));
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Üstteki (etkileşimli) kart + arkada beliren bir sonraki kartın önizlemesi
/// + altta her zaman görünen, jestin anlamını açıklayan aksiyon butonları.
class _SortingDeck extends StatelessWidget {
  const _SortingDeck({
    required this.top,
    required this.next,
    required this.remaining,
    required this.pendingDeleteCount,
    required this.asset,
    required this.controller,
    required this.onDelete,
    required this.onSkip,
    required this.onAssign,
  });

  final ScreenshotEntry top;
  final ScreenshotEntry? next;
  final int remaining;
  final int pendingDeleteCount;
  final AssetEntity? asset;
  final SwipeCardController controller;
  final Future<bool> Function() onDelete;
  final VoidCallback onSkip;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    // _MainShell'deki navbar boşluğunun BİREBİR aynısı: sm(üst) + pil + alt
    // boşluk. Fazla pay bırakmak kartı yukarı kaydırıp altta boş alan
    // bırakıyor, azı ise kartın altını pilin arkasında saklıyordu.
    final double navBarClearance =
        AppSpacing.sm +
        AppSizes.navBarHeight +
        (bottomInset > AppSpacing.md ? bottomInset : AppSpacing.md);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        navBarClearance,
      ),
      child: Column(
        children: [
          // Kalan sayısı ortada; sola kaydırılıp silmeye giden sayısı solda.
          SizedBox(
            height: 28,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: Text(
                    context.l10n.sortingRemainingCount(remaining),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (pendingDeleteCount > 0)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _PendingDeleteChip(count: pendingDeleteCount),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 9:16 kartın sığdığı en büyük dikdörtgen — Center yerine
                // kesin genişlik/yükseklik vererek Stack'in kendi boyutuna
                // göre içeriği kısıp kartı sola yaslamasının önüne geçer.
                double cardHeight = constraints.maxHeight;
                double cardWidth = cardHeight * 9 / 16;
                if (cardWidth > constraints.maxWidth) {
                  cardWidth = constraints.maxWidth;
                  cardHeight = cardWidth * 16 / 9;
                }
                return Center(
                  child: SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (next != null)
                          Transform.scale(
                            scale: 0.94,
                            child: Opacity(
                              opacity: 0.6,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
                                child: ColoredBox(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                ),
                              ),
                            ),
                          ),
                        SwipeCard(
                          key: ValueKey(top.assetId),
                          asset: asset,
                          controller: controller,
                          onDelete: onDelete,
                          onSkip: onSkip,
                          onAssign: onAssign,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SortingActionRow(
            onDelete: controller.triggerDelete,
            onSkip: controller.triggerSkip,
            onAssign: controller.triggerAssign,
          ),
        ],
      ),
    );
  }
}

/// Her zaman görünen aksiyon satırı: sol/orta/sağ konumu ilgili jest yönüyle
/// eşleşir (sil-sol, atla-yukarı, panoya ekle-sağ), böylece kullanıcı jesti
/// denemeden önce ne işe yaradığını görür; dokunarak da tetiklenebilir.
class _SortingActionRow extends StatelessWidget {
  const _SortingActionRow({
    required this.onDelete,
    required this.onSkip,
    required this.onAssign,
  });

  final VoidCallback onDelete;
  final VoidCallback onSkip;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _SortingActionButton(
          icon: Icons.delete_outline,
          label: l10n.sortingHintDelete,
          color: Colors.red,
          onTap: onDelete,
        ),
        _SortingActionButton(
          icon: Icons.arrow_upward,
          label: l10n.sortingHintSkip,
          color: Colors.blueGrey,
          onTap: onSkip,
        ),
        _SortingActionButton(
          icon: Icons.bookmark_add_outlined,
          label: l10n.sortingHintAssign,
          color: Colors.green,
          onTap: onAssign,
        ),
      ],
    );
  }
}

class _SortingActionButton extends StatelessWidget {
  const _SortingActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color.withValues(alpha: 0.12),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Icon(icon, color: color, size: 26),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _BoardPickerSheet extends StatelessWidget {
  const _BoardPickerSheet({required this.boards});

  final List<Board> boards;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.sortingAssignSheetTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final Board board in boards)
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(board.name),
                onTap: () => Navigator.of(context).pop(board.id),
              ),
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(l10n.boardsNewBoardAction),
              onTap: () => Navigator.of(context).pop(_createNewBoardSentinel),
            ),
          ],
        ),
      ),
    );
  }
}

/// Silmeye kuyruklanan kart sayısını gösteren küçük kırmızı hap.
class _PendingDeleteChip extends StatelessWidget {
  const _PendingDeleteChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline, size: 14, color: scheme.onErrorContainer),
          const SizedBox(width: AppSpacing.xs),
          Text(
            context.l10n.sortingPendingDeleteCount(count),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Deste bitince, bekleyen silmeleri tek onayla tamamlamaya davet eden ekran.
class _SortingFinishPrompt extends StatelessWidget {
  const _SortingFinishPrompt({
    required this.count,
    required this.deleting,
    required this.onFinish,
  });

  final int count;
  final bool deleting;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_sweep_outlined,
                size: 40,
                color: scheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.sortingPendingDeleteCount(count),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.sortingFinishConfirmBody,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: deleting ? null : onFinish,
              icon: deleting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              label: Text(l10n.sortingFinishAction(count)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortingEmpty extends StatelessWidget {
  const _SortingEmpty();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.checklist_rtl_outlined,
                size: 40,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.sortingEmptyTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.sortingEmptyBody,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SortingLimit extends StatelessWidget {
  const _SortingLimit();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.workspace_premium_outlined,
                size: 40,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.sortingLimitTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.sortingLimitBody,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => context.push(AppRoutes.paywall),
              child: Text(l10n.paywallTitle),
            ),
          ],
        ),
      ),
    );
  }
}

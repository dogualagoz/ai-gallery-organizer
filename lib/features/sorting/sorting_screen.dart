// Swipe sıralama ekranı: analiz edilmemiş/"diğer" screenshot'lar için
// sola sil / sağa atla / yukarı seçili kategoriye ata kart akışı.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/constants/ui_constants.dart';
import '../../core/l10n/category_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/screenshot_category.dart';
import '../../core/models/screenshot_entry.dart';
import '../../core/router/app_router.dart';
import '../../core/services/category_names_service.dart';
import '../../core/services/entitlement_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/review_service.dart';
import '../gallery/data/screenshot_repository.dart';
import '../gallery/providers/gallery_provider.dart';
import 'widgets/category_picker_sheet.dart';
import 'widgets/swipe_card.dart';

class SortingScreen extends ConsumerStatefulWidget {
  const SortingScreen({super.key});

  @override
  ConsumerState<SortingScreen> createState() => _SortingScreenState();
}

/// Bu oturumdaki tek swipe hareketi — "Geri al" için kaydedilir.
enum _SwipeType { delete, skip, assign }

class _SwipeAction {
  const _SwipeAction(
    this.type,
    this.assetId, {
    this.prevCategory,
    this.prevAnalyzedAt,
  });

  final _SwipeType type;
  final String assetId;

  /// Kategori-atama öncesi durum (yalnız [_SwipeType.assign] için) — geri
  /// alınınca kartı birebir eski haline döndürmek için saklanır.
  final ScreenshotCategory? prevCategory;
  final DateTime? prevAnalyzedAt;
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

  /// Sort sekmesi bir önceki karede aktif miydi — çıkışı (aktif→pasif) yakalar.
  bool _wasTabActive = true;

  /// Yukarı kaydırmanın hedef kategorisi; üstteki chip'ten değiştirilir.
  ScreenshotCategory _selectedCategory = ScreenshotCategory.social;

  /// Alttaki aksiyon butonlarının üstteki karta jest gönderebilmesi için.
  final SwipeCardController _cardController = SwipeCardController();

  @override
  void initState() {
    super.initState();
    // 7 gün boşta kalan kullanıcı ekrana taze haftalık swipe kotasıyla girsin.
    ref.read(entitlementProvider.notifier).ensureWeeklyWindow();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // go_router sekme dallarını `TickerMode` ile sarar: Sort sekmesinden
    // çıkınca aktiflik false'a döner. O an biriken silmeleri iOS'un kendi
    // onayıyla işleriz. `didChangeDependencies` içinde setState çağırmamak
    // için işlemi kare sonrasına erteleriz.
    final bool active = TickerMode.valuesOf(context).enabled;
    if (_wasTabActive && !active && _pendingDeletes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _commitDeletes());
    }
    _wasTabActive = active;
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

    final Map<int, String> categoryNames = ref.watch(categoryNamesProvider);
    final String categoryLabel = _selectedCategory.displayName(
      l10n,
      categoryNames,
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _SortHeader(
              categoryIcon: _selectedCategory.icon,
              categoryLabel: categoryLabel,
              remaining: queue.length,
              pendingDeleteCount: _pendingDeletes.length,
              canUndo: _history.isNotEmpty,
              onUndo: _undo,
              onPickCategory: _pickCategory,
            ),
            Expanded(
              child: !entitlement.canSwipe
                  ? const _SortingLimit()
                  : queue.isEmpty
                  ? (_pendingDeletes.isEmpty
                        ? const _SortingEmpty()
                        : _SortingFinishPrompt(
                            count: _pendingDeletes.length,
                            deleting: _finishing,
                            onFinish: _commitDeletes,
                          ))
                  : _SortingDeck(
                      top: queue.first,
                      next: queue.length > 1 ? queue[1] : null,
                      asset: repo.assetFor(queue.first.assetId),
                      controller: _cardController,
                      categoryIcon: _selectedCategory.icon,
                      categoryLabel: categoryLabel,
                      onDelete: () => _queueDelete(queue.first.assetId),
                      onSkip: () => _skipCard(queue.first.assetId),
                      onAssign: () => _assignToCategory(queue.first),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Yukarı-atama hedef kategorisini seçtirir.
  Future<void> _pickCategory() async {
    Haptics.tap();
    final ScreenshotCategory? selected = await showCategoryPickerSheet(
      context,
      selected: _selectedCategory,
    );
    if (selected != null && mounted) {
      setState(() => _selectedCategory = selected);
    }
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
        // Atama öncesi kategori/analiz durumuna geri dön → kart deste başına düşer.
        await ref
            .read(screenshotRepositoryProvider)
            .restoreCategoryState(
              action.assetId,
              category: action.prevCategory,
              analyzedAt: action.prevAnalyzedAt,
            );
        if (mounted) setState(() {});
    }
  }

  /// Biriken silme kuyruğunu tek `deleteWithIds` çağrısıyla siler. Onay olarak
  /// iOS'un kendi "N fotoğrafı sil?" sorusu gösterilir — ayrıca Flutter dialogu
  /// açılmaz. Sort sekmesinden çıkışta ve deste bitiş ekranındaki butonda
  /// çağrılır. Kullanıcı iOS onayını iptal ederse kuyruk olduğu gibi kalır.
  Future<void> _commitDeletes() async {
    if (_pendingDeletes.isEmpty || _finishing || !mounted) return;
    final l10n = context.l10n;
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

  /// Yukarı kaydırma: kartı üstte seçili kategoriye atar. Atama öncesi durum
  /// geri-al için saklanır; setCategory pending kartı "işlendi" yapıp kuyruktan
  /// düşürür.
  Future<void> _assignToCategory(ScreenshotEntry entry) async {
    Haptics.tick();
    await ref
        .read(screenshotRepositoryProvider)
        .setCategory(entry.assetId, _selectedCategory);
    await ref.read(entitlementProvider.notifier).registerSwipe();
    if (mounted) {
      setState(
        () => _history.add(
          _SwipeAction(
            _SwipeType.assign,
            entry.assetId,
            prevCategory: entry.category,
            prevAnalyzedAt: entry.analyzedAt,
          ),
        ),
      );
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
    required this.asset,
    required this.controller,
    required this.categoryIcon,
    required this.categoryLabel,
    required this.onDelete,
    required this.onSkip,
    required this.onAssign,
  });

  final ScreenshotEntry top;
  final ScreenshotEntry? next;
  final AssetEntity? asset;
  final SwipeCardController controller;
  final IconData categoryIcon;
  final String categoryLabel;
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
                          assignIcon: categoryIcon,
                          assignLabel: categoryLabel,
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
            categoryIcon: categoryIcon,
            categoryLabel: categoryLabel,
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
/// eşleşir (sil-sol, kategori-yukarı, atla-sağ), böylece kullanıcı jesti
/// denemeden önce ne işe yaradığını görür; dokunarak da tetiklenebilir.
class _SortingActionRow extends StatelessWidget {
  const _SortingActionRow({
    required this.categoryIcon,
    required this.categoryLabel,
    required this.onDelete,
    required this.onSkip,
    required this.onAssign,
  });

  final IconData categoryIcon;
  final String categoryLabel;
  final VoidCallback onDelete;
  final VoidCallback onSkip;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
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
          icon: categoryIcon,
          label: categoryLabel,
          color: scheme.primary,
          onTap: onAssign,
        ),
        _SortingActionButton(
          icon: Icons.arrow_forward,
          label: l10n.sortingHintSkip,
          color: Colors.blueGrey,
          onTap: onSkip,
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

/// Sort ekranının üst başlığı (AppBar yerine): solda geri-al, ortada seçili
/// kategori chip'i (dokununca değiştirir), sağda silme sayacı; altında kalan
/// kart sayısı ince bir gösterge olarak. Üstte belirgin düz başlık yoktur.
class _SortHeader extends StatelessWidget {
  const _SortHeader({
    required this.categoryIcon,
    required this.categoryLabel,
    required this.remaining,
    required this.pendingDeleteCount,
    required this.canUndo,
    required this.onUndo,
    required this.onPickCategory,
  });

  final IconData categoryIcon;
  final String categoryLabel;
  final int remaining;
  final int pendingDeleteCount;
  final bool canUndo;
  final VoidCallback onUndo;
  final VoidCallback onPickCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        0,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: _CategoryChip(
                    icon: categoryIcon,
                    label: categoryLabel,
                    onTap: onPickCategory,
                  ),
                ),
                if (canUndo)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: l10n.sortingUndo,
                      icon: const Icon(Icons.undo),
                      onPressed: onUndo,
                    ),
                  ),
                if (pendingDeleteCount > 0)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: _PendingDeleteCounter(count: pendingDeleteCount),
                    ),
                  ),
              ],
            ),
          ),
          if (remaining > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                l10n.sortingRemainingCount(remaining),
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

/// Seçili yukarı-atama kategorisini gösteren, dokununca değiştiren pill.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          // Uzun özel adlar undo/sayaç ile çakışmasın diye ekranın %60'ıyla sınırla.
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.6,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: scheme.onPrimaryContainer),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.expand_more,
                  size: 18,
                  color: scheme.onPrimaryContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// App bar'da silmeye kuyruklanan kart sayısını gösteren sayaç (silme ikonu +
/// adet). Etkileşimsiz — gerçek silme sekmeden çıkışta iOS onayıyla yapılır.
class _PendingDeleteCounter extends StatelessWidget {
  const _PendingDeleteCounter({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: context.l10n.sortingPendingDeleteCount(count),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline, size: 20, color: scheme.error),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$count',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: scheme.error,
              fontWeight: FontWeight.w700,
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

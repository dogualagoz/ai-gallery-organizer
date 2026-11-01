// Tüm koleksiyon ekranlarının ortak ekran görüntüsü ızgarası (sliver):
// Fotoğraflar gibi sıkı aralık. Normalde dokunuş görüntüleyiciyi bu ızgaranın
// sırasıyla açar ve uzun basış bağlam menüsü getirir; seçim modunda dokunuş
// seçimi değiştirir.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/models/screenshot_entry.dart';
import '../../detail/open_viewer.dart';
import '../data/screenshot_repository.dart';
import 'screenshot_context_menu.dart';
import 'screenshot_grid_tile.dart';

/// [entries] için 3 sütunlu ekran görüntüsü ızgarası (sliver).
class ScreenshotGrid extends ConsumerWidget {
  const ScreenshotGrid({
    super.key,
    required this.entries,
    this.inset = false,
    this.selectedIds,
    this.onToggle,
    this.onOpen,
  });

  final List<ScreenshotEntry> entries;

  /// true: kart içi önizleme (kenar boşluklu, köşeli, daha geniş aralık);
  /// false: kenardan kenara tam ekran ızgara.
  final bool inset;

  /// null değilse seçim modu: karolar işaret gösterir, bağlam menüsü kapalı.
  final Set<String>? selectedIds;

  /// Seçim modunda dokunulan karonun kimliği.
  final ValueChanged<String>? onToggle;

  /// Görüntüleyici açılmadan hemen önce (ör. arama sorgusunu geçmişe yazmak).
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ScreenshotRepository repo = ref.watch(screenshotRepositoryProvider);
    final Set<String>? selection = selectedIds;
    final double gap = inset ? AppSpacing.xs : AppGridTile.gap;
    // Silme/taşıma sonrası liste kayınca karolar kendi öğesini izler.
    final Map<String, int> indexOf = {
      for (int i = 0; i < entries.length; i++) entries[i].assetId: i,
    };

    return SliverPadding(
      padding: inset
          ? const EdgeInsets.symmetric(horizontal: AppSpacing.md)
          : EdgeInsets.zero,
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: kScreenshotGridColumns,
          mainAxisSpacing: gap,
          crossAxisSpacing: gap,
          childAspectRatio: kScreenshotTileAspect,
        ),
        itemCount: entries.length,
        findChildIndexCallback: (key) =>
            key is ValueKey<String> ? indexOf[key.value] : null,
        itemBuilder: (context, index) {
          final ScreenshotEntry entry = entries[index];
          final Key key = ValueKey<String>(entry.assetId);
          final Widget tile = ScreenshotGridTile(
            key: selection != null ? key : null,
            entry: entry,
            asset: repo.assetFor(entry.assetId),
            radius: inset ? AppRadius.sm : 0,
            selected: selection?.contains(entry.assetId),
            onPressed: selection != null
                ? () => onToggle?.call(entry.assetId)
                : () {
                    onOpen?.call();
                    openViewer(
                      context,
                      entry.assetId,
                      scope: [for (final item in entries) item.assetId],
                    );
                  },
          );
          if (selection != null) return tile;
          return ScreenshotContextMenu(key: key, entry: entry, child: tile);
        },
      ),
    );
  }
}

/// Izgarada analiz bekleyen varken üstte duran dipnot: karo köşesindeki
/// noktanın ne anlama geldiğini açıklar.
class ScreenshotPendingLegend extends StatelessWidget {
  const ScreenshotPendingLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          const ExcludeSemantics(child: PendingDot()),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.pendingDotLegend,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

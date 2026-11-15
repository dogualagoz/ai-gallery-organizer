// Tüm koleksiyon ekranlarının ortak ekran görüntüsü ızgarası (sliver):
// Fotoğraflar gibi sıkı aralık. Normalde dokunuş görüntüleyiciyi bu ızgaranın
// sırasıyla açar ve uzun basış bağlam menüsü getirir; seçim modunda dokunuş
// seçimi değiştirir.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/models/screenshot_entry.dart';
import '../../../core/router/open_viewer.dart';
import '../data/screenshot_repository.dart';
import 'screenshot_context_menu.dart';
import 'screenshot_grid_tile.dart';

/// [entries] için 3 sütunlu ekran görüntüsü ızgarası (sliver).
class ScreenshotGrid extends ConsumerWidget {
  const ScreenshotGrid({
    super.key,
    required this.entries,
    this.inset = false,
    this.selection,
    this.onToggle,
    this.onOpen,
  });

  final List<ScreenshotEntry> entries;

  /// true: kart içi önizleme (kenar boşluklu, köşeli, daha geniş aralık);
  /// false: kenardan kenara tam ekran ızgara.
  final bool inset;

  /// null değilse seçim modu: karolar işaret gösterir, bağlam menüsü kapalı.
  /// Seçim değişince yalnız durumu değişen karolar yeniden kurulur.
  final ValueListenable<Set<String>>? selection;

  /// Seçim modunda dokunulan karonun kimliği.
  final ValueChanged<String>? onToggle;

  /// Görüntüleyici açılmadan hemen önce (ör. arama sorgusunu geçmişe yazmak).
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ScreenshotRepository repo = ref.watch(screenshotRepositoryProvider);
    final ValueListenable<Set<String>>? selection = this.selection;
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
          if (selection != null) {
            return _SelectableTile(
              key: key,
              selection: selection,
              assetId: entry.assetId,
              builder: (selected) => ScreenshotGridTile(
                entry: entry,
                asset: repo.assetFor(entry.assetId),
                radius: inset ? AppRadius.sm : 0,
                selected: selected,
                onPressed: () => onToggle?.call(entry.assetId),
              ),
            );
          }
          return ScreenshotContextMenu(
            key: key,
            entry: entry,
            child: ScreenshotGridTile(
              entry: entry,
              asset: repo.assetFor(entry.assetId),
              radius: inset ? AppRadius.sm : 0,
              onPressed: () {
                onOpen?.call();
                openViewer(
                  context,
                  entry.assetId,
                  scope: [for (final item in entries) item.assetId],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Seçim modundaki karo: ortak seçimi dinler ama yalnız kendi üyeliği
/// değişince yeniden kurulur (bir karoya dokunmak ızgarayı yenilemez).
class _SelectableTile extends StatefulWidget {
  const _SelectableTile({
    super.key,
    required this.selection,
    required this.assetId,
    required this.builder,
  });

  final ValueListenable<Set<String>> selection;
  final String assetId;
  final Widget Function(bool selected) builder;

  @override
  State<_SelectableTile> createState() => _SelectableTileState();
}

class _SelectableTileState extends State<_SelectableTile> {
  late bool _selected = _isSelected();

  bool _isSelected() => widget.selection.value.contains(widget.assetId);

  @override
  void initState() {
    super.initState();
    widget.selection.addListener(_onSelection);
  }

  @override
  void didUpdateWidget(_SelectableTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selection != widget.selection) {
      oldWidget.selection.removeListener(_onSelection);
      widget.selection.addListener(_onSelection);
    }
    _selected = _isSelected();
  }

  @override
  void dispose() {
    widget.selection.removeListener(_onSelection);
    super.dispose();
  }

  void _onSelection() {
    final bool selected = _isSelected();
    if (selected != _selected) setState(() => _selected = selected);
  }

  @override
  Widget build(BuildContext context) => widget.builder(_selected);
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

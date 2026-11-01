// Görüntüleyicinin bilgi paneli: tarih, kategori/pano (dokununca taşı),
// aramaya götüren etiketler, kopyalanabilir metin; bekliyorsa "Analiz et".
import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/category_labels.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/models/board.dart';
import '../../../core/models/screenshot_category.dart';
import '../../../core/models/screenshot_entry.dart';
import '../../../core/services/category_names_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/widgets/grouped_section.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/status_toast.dart';
import '../../../core/widgets/surface_card.dart';
import '../../analysis/providers/analysis_queue_provider.dart';
import '../../boards/providers/board_provider.dart';
import '../../paywall/open_paywall.dart';
import 'viewer_top_bar.dart';

/// [entry]'nin bilgileri. Üstteki başlık alanı sürükleme tutamağıdır
/// (sürüklemeyi görüntüleyici yönetir); içerik ayrıca kaydırılır.
class ViewerInfoPanel extends StatelessWidget {
  const ViewerInfoPanel({
    super.key,
    required this.entry,
    required this.bottomInset,
    required this.onMove,
    required this.onTag,
  });

  final ScreenshotEntry entry;

  /// İçeriğin altında bırakılan pay (yüzen araç çubuğu son satırı örtmesin).
  final double bottomInset;

  /// Kategori/pano satırına dokunulunca: taşıma hedefi seçtirilir.
  final VoidCallback onMove;

  /// Etikete dokunulunca: o etiketle arama.
  final ValueChanged<String> onTag;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String? ocr = entry.ocrText;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: AppGlass.shadowAlpha),
            blurRadius: AppGlass.shadowBlur,
          ),
        ],
      ),
      child: Column(
        children: [
          _PanelHeader(time: entry.createdAt),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(bottom: bottomInset),
              children: [
                if (entry.isPending) _PendingCard(assetId: entry.assetId),
                _PlacementSection(entry: entry, onMove: onMove),
                if (entry.tags.isNotEmpty)
                  _TagsSection(tags: entry.tags, onTag: onTag),
                if (ocr != null && ocr.isNotEmpty) _TextSection(text: ocr),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tutamak + tarih/saat; panelin sürüklenen bölgesi.
class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.time});

  final DateTime time;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          Container(
            width: AppSizes.grabberWidth,
            height: AppSizes.grabberHeight,
            decoration: BoxDecoration(
              color: scheme.outline,
              borderRadius: BorderRadius.circular(AppSizes.grabberHeight),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(viewerDate(context, time), style: text.headlineSmall),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              viewerTime(context, time),
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// Analiz edilmemiş görüntü için açıklama + tek seferlik analiz.
class _PendingCard extends ConsumerStatefulWidget {
  const _PendingCard({required this.assetId});

  final String assetId;

  @override
  ConsumerState<_PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends ConsumerState<_PendingCard> {
  bool _analyzing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: SurfaceCard(
        tinted: true,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.detailNotAnalyzed, style: text.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.viewerPendingBody,
              style: text.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: _analyzing ? null : _analyze,
              icon: _analyzing
                  ? const CupertinoActivityIndicator()
                  : const Icon(AppIcons.analyze),
              label: Text(l10n.detailAnalyzeNow),
            ),
          ],
        ),
      ),
    );
  }

  /// Tek görüntü analizi; kota bittiyse paywall paket bölümünde açılır.
  Future<void> _analyze() async {
    setState(() => _analyzing = true);
    final SingleAnalysisOutcome outcome = await ref
        .read(analysisQueueProvider.notifier)
        .analyzeSingle(widget.assetId);
    if (!mounted) return;
    setState(() => _analyzing = false);
    switch (outcome) {
      case SingleAnalysisOutcome.success:
        // Kayıt güncellenince panel kendiliğinden kategoriyi gösterir.
        Haptics.confirm();
      case SingleAnalysisOutcome.limitReached:
        openPaywall(context, packs: true);
      case SingleAnalysisOutcome.failed:
        showStatusToast(
          context,
          context.l10n.analysisFailedBanner,
          tone: StatusToastTone.error,
        );
    }
  }
}

/// Kategori ve pano satırları; dokununca taşıma hedefi seçilir.
class _PlacementSection extends ConsumerWidget {
  const _PlacementSection({required this.entry, required this.onMove});

  final ScreenshotEntry entry;
  final VoidCallback onMove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ScreenshotCategory? category = entry.category;
    final String? boardId = entry.boardId;
    final Board? board = boardId == null
        ? null
        : (ref.watch(boardsProvider).value ?? const <Board>[])
              .where((candidate) => candidate.id == boardId)
              .firstOrNull;
    if (category == null && board == null) return const SizedBox.shrink();

    return GroupedSection(
      children: [
        if (category != null)
          GroupedRow(
            icon: category.icon,
            title: l10n.infoCategoryLabel,
            value: category.displayName(l10n, ref.watch(categoryNamesProvider)),
            onTap: onMove,
          ),
        if (board != null)
          GroupedRow(
            icon: AppIcons.board,
            title: l10n.infoBoardLabel,
            value: board.name,
            onTap: onMove,
          ),
      ],
    );
  }
}

/// Etiket kapsülleri; her biri o etiketle aramayı açar.
class _TagsSection extends StatelessWidget {
  const _TagsSection({required this.tags, required this.onTag});

  final List<String> tags;
  final ValueChanged<String> onTag;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return GroupedSection(
      header: l10n.detailTagsTitle,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final String tag in tags)
                Pressable(
                  onPressed: () => onTag(tag),
                  semanticLabel: l10n.searchTagLabel(tag),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.chipPaddingH,
                        vertical: AppSizes.chipPaddingV,
                      ),
                      child: Text(
                        tag,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Görseldeki metin: seçilebilir, tek dokunuşla tamamı kopyalanır.
class _TextSection extends StatelessWidget {
  const _TextSection({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GroupedSection(
      header: l10n.detailOcrTitle,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SelectableText(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        GroupedRow(
          icon: AppIcons.copy,
          title: l10n.copyTextAction,
          showChevron: false,
          onTap: () => _copy(context),
        ),
      ],
    );
  }

  Future<void> _copy(BuildContext context) async {
    final l10n = context.l10n;
    final StatusToaster toaster = StatusToaster.of(context);
    try {
      await Clipboard.setData(ClipboardData(text: text));
      Haptics.tap();
      toaster.show(
        l10n.textCopiedToast,
        tone: StatusToastTone.success,
        icon: AppIcons.copy,
      );
    } catch (error, stackTrace) {
      debugPrint('Metin kopyalanamadı: $error\n$stackTrace');
      toaster.show(l10n.textCopyFailed, tone: StatusToastTone.error);
    }
  }
}

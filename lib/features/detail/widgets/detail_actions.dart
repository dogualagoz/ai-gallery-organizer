// Detay ekranı aksiyonları: şimdi analiz et, paylaş, sil.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/models/screenshot_entry.dart';
import '../../../core/router/app_router.dart';
import '../../analysis/providers/analysis_queue_provider.dart';
import '../../gallery/data/screenshot_repository.dart';

class DetailActions extends ConsumerStatefulWidget {
  const DetailActions({super.key, required this.entry, required this.asset});

  final ScreenshotEntry entry;
  final AssetEntity? asset;

  @override
  ConsumerState<DetailActions> createState() => _DetailActionsState();
}

class _DetailActionsState extends ConsumerState<DetailActions> {
  /// Analiz/paylaşım sürerken butonlar kilitlenir (çift tetiklemeyi önler).
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.entry.isPending) ...[
          FilledButton.icon(
            onPressed: _busy ? null : _analyzeNow,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_outlined),
            label: Text(l10n.detailAnalyzeNow),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _share,
                icon: const Icon(Icons.ios_share),
                label: Text(l10n.detailShare),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _delete,
                style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
                icon: const Icon(Icons.delete_outline),
                label: Text(l10n.detailDelete),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Tek screenshot analizi; limit dolmuşsa paywall'a yönlendirir.
  Future<void> _analyzeNow() async {
    setState(() => _busy = true);
    final SingleAnalysisOutcome outcome = await ref
        .read(analysisQueueProvider.notifier)
        .analyzeSingle(widget.entry.assetId);
    if (!mounted) return;
    setState(() => _busy = false);

    switch (outcome) {
      case SingleAnalysisOutcome.success:
        break; // Box değişimi galeri/detayı zaten tazeler.
      case SingleAnalysisOutcome.limitReached:
        context.push(AppRoutes.paywall);
      case SingleAnalysisOutcome.failed:
        _showSnack(context.l10n.analysisFailedBanner);
    }
  }

  /// Orijinal dosyayı iOS paylaşım sayfasıyla paylaşır.
  Future<void> _share() async {
    final String failureMessage = context.l10n.detailShareFailed;
    setState(() => _busy = true);
    final File? file = await widget.asset?.file;
    if (!mounted) return;
    setState(() => _busy = false);
    if (file == null) {
      _showSnack(failureMessage);
      return;
    }
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }

  /// Cihazdan siler (iOS sistem onayı çıkar); onaylanırsa metadata da düşülür.
  Future<void> _delete() async {
    final String failureMessage = context.l10n.detailDeleteFailed;
    List<String> deleted;
    try {
      deleted = await PhotoManager.editor.deleteWithIds([widget.entry.assetId]);
    } catch (error, stackTrace) {
      debugPrint('Silme hatası (${widget.entry.assetId}): $error\n$stackTrace');
      if (mounted) _showSnack(failureMessage);
      return;
    }
    // Boş liste = kullanıcı sistem onayını reddetti; sessiz geçilir.
    if (deleted.isEmpty || !mounted) return;
    await ref
        .read(screenshotRepositoryProvider)
        .removeEntry(widget.entry.assetId);
    if (mounted) context.pop();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

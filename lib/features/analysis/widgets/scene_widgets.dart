// Analiz animasyonunun paylaşılan sunum bileşenleri: kaynak fotoğraf yığını
// ve tek kare thumbnail. Orkestrasyon (uçuş/particle) analyze_card.dart'ta.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../../../core/constants/ui_constants.dart';
import '../../gallery/data/screenshot_repository.dart';

/// Merkez-üstteki kaynak yığın: bekleyenlerden birkaç fanlı thumbnail +
/// üzerinden geçen ince tarama parıltısı + kalan sayaç rozeti. Uçuşların
/// başlangıç noktası [sourceKey] ile işaretlenir.
class SourceCluster extends ConsumerStatefulWidget {
  const SourceCluster({
    super.key,
    required this.sourceKey,
    required this.remaining,
  });

  final GlobalKey sourceKey;
  final int remaining;

  @override
  ConsumerState<SourceCluster> createState() => _SourceClusterState();
}

class _SourceClusterState extends ConsumerState<SourceCluster>
    with SingleTickerProviderStateMixin {
  /// Kart destesi üzerinde soldan sağa süzülen parıltı.
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  static const Size _card = Size(84, 128);

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final ScreenshotRepository repo = ref.watch(screenshotRepositoryProvider);
    final List<String> ids = repo
        .sortedEntries()
        .where((entry) => entry.isPending)
        .take(3)
        .map((entry) => entry.assetId)
        .toList();

    return SizedBox(
      key: widget.sourceKey,
      width: _card.width + AppSpacing.xl,
      height: _card.height + AppSpacing.md,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Arkadan öne hafif yelpazelenen deste (boşsa nötr kart gösterir).
          for (int i = (ids.isEmpty ? 0 : ids.length) - 1; i >= 0; i--)
            Transform.rotate(
              angle: (i - 1) * 0.08,
              child: _ClusterCard(size: _card, assetId: ids[i]),
            ),
          if (ids.isEmpty) _ClusterCard(size: _card, assetId: null),
          _SweepGlow(sweep: _sweep, size: _card, color: scheme.secondary),
          if (widget.remaining > 0)
            Positioned(
              right: 0,
              top: 0,
              child: _RemainingBadge(count: widget.remaining),
            ),
        ],
      ),
    );
  }
}

/// Destedeki tek kart görseli.
class _ClusterCard extends StatelessWidget {
  const _ClusterCard({required this.size, required this.assetId});

  final Size size;
  final String? assetId;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        color: scheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: assetId == null
          ? Icon(Icons.image_outlined, color: scheme.onSurfaceVariant)
          : SceneThumb(assetId: assetId!),
    );
  }
}

/// Deste üzerinde soldan sağa geçen yumuşak ışık bandı (tarama hissi).
class _SweepGlow extends StatelessWidget {
  const _SweepGlow({
    required this.sweep,
    required this.size,
    required this.color,
  });

  final Animation<double> sweep;
  final Size size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: sweep,
      builder: (context, _) {
        final double x = -1 + 2 * sweep.value; // -1..1 arası kayar
        return IgnorePointer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              width: size.width,
              height: size.height,
              alignment: Alignment(x, 0),
              child: Container(
                width: size.width * 0.4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0),
                      color.withValues(alpha: 0.22),
                      color.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Kalan (henüz yerleşmemiş) screenshot sayısını gösteren rozet.
class _RemainingBadge extends StatelessWidget {
  const _RemainingBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Kare, kırpılmış tek asset thumbnail'ı — animasyon boyunca birden çok yerde
/// (kaynak deste, şerit yığını) kullanılır.
class SceneThumb extends ConsumerWidget {
  const SceneThumb({super.key, required this.assetId});

  final String assetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AssetEntity? asset = ref
        .watch(screenshotRepositoryProvider)
        .assetFor(assetId);
    if (asset == null) {
      return ColoredBox(color: scheme.surfaceContainerHighest);
    }
    return AssetEntityImage(
      asset,
      isOriginal: false,
      thumbnailSize: const ThumbnailSize.square(150),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          ColoredBox(color: scheme.surfaceContainerHighest),
    );
  }
}

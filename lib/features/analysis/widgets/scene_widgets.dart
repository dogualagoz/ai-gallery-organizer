// Analiz animasyonunun paylaşılan sunum bileşenleri: kaynak yığın, kategori
// şeritleri ve tek thumbnail. Orkestrasyon (uçuş/particle) analyze_card.dart'ta.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/category_labels.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/models/screenshot_category.dart';
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
          _SweepGlow(sweep: _sweep, size: _card, color: scheme.onSurface),
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

/// Kategori şeritleri alanı: yalnız bu turda öğe alan kategoriler, görünme
/// sırasıyla iki sütunlu bir sarmalda belirir.
class LanesArea extends StatelessWidget {
  const LanesArea({
    super.key,
    required this.lanes,
    required this.landed,
    required this.laneKeyFor,
  });

  final List<ScreenshotCategory> lanes;
  final Map<ScreenshotCategory, int> landed;
  final GlobalKey Function(ScreenshotCategory) laneKeyFor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double laneWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final ScreenshotCategory category in lanes)
                SizedBox(
                  width: laneWidth,
                  child: LaneCard(
                    key: ValueKey<ScreenshotCategory>(category),
                    category: category,
                    landedCount: landed[category] ?? 0,
                    anchorKey: laneKeyFor(category),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Tek kategori şeridi: ikon + etiket + inen kartların mini yığını + sayaç.
/// İlk belirişte hafif ölçek/opaklık girişi yapar. [anchorKey] uçuşların
/// hedef noktasını (mini yığın) işaretler.
class LaneCard extends ConsumerWidget {
  const LaneCard({
    super.key,
    required this.category,
    required this.landedCount,
    required this.anchorKey,
  });

  final ScreenshotCategory category;
  final int landedCount;
  final GlobalKey anchorKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final ScreenshotRepository repo = ref.watch(screenshotRepositoryProvider);
    final List<String> covers = repo
        .sortedEntries()
        .where((entry) => entry.category == category)
        .take(3)
        .map((entry) => entry.assetId)
        .toList();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppDurations.medium,
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0, 1),
        child: Transform.scale(scale: 0.85 + 0.15 * value, child: child),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(category.icon, size: 20, color: scheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                category.label(l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            _LaneStack(
              anchorKey: anchorKey,
              covers: covers,
              count: landedCount,
            ),
          ],
        ),
      ),
    );
  }
}

/// Şeride inen kartları temsil eden mini yığın + toplam sayaç. Uçuş hedefi
/// olarak [anchorKey] taşır.
class _LaneStack extends StatelessWidget {
  const _LaneStack({
    required this.anchorKey,
    required this.covers,
    required this.count,
  });

  final GlobalKey anchorKey;
  final List<String> covers;
  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    const double tile = 26;
    const double overlap = 12;
    final int shown = covers.length.clamp(0, 3);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          key: anchorKey,
          width: shown == 0 ? tile : tile + overlap * (shown - 1),
          height: tile,
          child: Stack(
            children: [
              for (int i = 0; i < shown; i++)
                Positioned(
                  left: overlap * i,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: SizedBox(
                      width: tile,
                      height: tile,
                      child: SceneThumb(assetId: covers[i]),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$count',
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
        ),
      ],
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

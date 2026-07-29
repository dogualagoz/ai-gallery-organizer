// Board görünümündeki tek kart: kapak thumbnail şeridi + ikon, ad ve sayaç.
// Dokununca standart iOS push (sağdan kayma) ile hedef ekrana geçer.
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../analysis/widgets/scene_particles.dart';

/// Kapakta gösterilecek en fazla thumbnail sayısı.
const int kBoardCoverCount = 3;

/// Karoyu, aldığı yeni içerik sayısına göre vurgular: yeni içerik alan karo
/// doğrudan marka moruna (ikincil renk; koyu temada zaten daha açık) döner.
/// [count] 0 ise varsayılan (nötr) yüzey döner.
Color _tileSurface(ColorScheme scheme, int count) =>
    count > 0 ? scheme.secondary : scheme.surface;

/// Vurgulu karo kenarlıksız durur; nötr karo ince outline kenarlığı taşır.
BorderSide _tileBorder(ColorScheme scheme, int count) =>
    count > 0 ? BorderSide.none : BorderSide(color: scheme.outlineVariant);

class BoardTile extends StatelessWidget {
  const BoardTile({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.covers,
    required this.openBuilder,
    this.newCount = 0,
  });

  final IconData icon;
  final String label;
  final int count;

  /// Board içeriğinden örnek thumbnail'lar (en fazla [kBoardCoverCount]).
  final List<AssetEntity> covers;

  /// Kartın büyüyerek açılacağı hedef ekranı üretir.
  final WidgetBuilder openBuilder;

  /// Son analizde bu karoya dağıtılan, henüz görülmemiş yeni screenshot sayısı;
  /// >0 ise karo mor tonda vurgulanır, yıldız tozu ve "+N" rozeti gösterilir.
  final int newCount;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    final Widget body = BoardTileBody(
      icon: icon,
      label: label,
      count: count,
      covers: covers,
      newCount: newCount,
    );
    // Nötr karo: sade gövde. Vurgulu karo: düz mor yerine üstüne beyaz parlak
    // gloss katmanı bindirilir (mat/pastel görünmesin).
    final Widget content = newCount == 0
        ? body
        : Stack(fit: StackFit.expand, children: [const _TileGloss(), body]);

    // Standart iOS geçişi: dokununca hedef ekran sağdan kayarak açılır.
    final Widget tile = Material(
      color: _tileSurface(scheme, newCount),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: _tileBorder(scheme, newCount),
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: openBuilder),
        ),
        child: content,
      ),
    );

    // Yeni içerik alan karonun arkasına ışıma: içte beyaz bloom + dışta mor hale.
    if (newCount == 0) return tile;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.55),
            blurRadius: 20,
            spreadRadius: -6,
          ),
          BoxShadow(
            color: scheme.secondary.withValues(alpha: 0.5),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: tile,
    );
  }
}

/// Vurgulu karonun mor yüzeyine bindirilerek onu parlatan beyaz gloss: sol
/// üstten gelen güçlü ışık köşegen boyunca söner; kapak görselleri opak olduğu
/// için yalnız görünen mor alanları (boşluklar + etiket bandı) parlar.
class _TileGloss extends StatelessWidget {
  const _TileGloss();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.32),
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.45, 0.8],
        ),
      ),
    );
  }
}

/// Düzenleme modunda kullanılan, açılmayan sabit kart: [BoardTile]'ın kapalı
/// görünümünü (yüzey + kenarlık) OpenContainer olmadan birebir taklit eder.
class BoardTileStatic extends StatelessWidget {
  const BoardTileStatic({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.covers,
  });

  final IconData icon;
  final String label;
  final int count;
  final List<AssetEntity> covers;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: BoardTileBody(
        icon: icon,
        label: label,
        count: count,
        covers: covers,
      ),
    );
  }
}

/// Karo iç gövdesi: kapak şeridi + ikon, ad ve sayaç. Hem açılan [BoardTile]
/// hem sabit [BoardTileStatic] tarafından paylaşılır.
class BoardTileBody extends StatelessWidget {
  const BoardTileBody({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.covers,
    this.newCount = 0,
  });

  final IconData icon;
  final String label;
  final int count;
  final List<AssetEntity> covers;

  /// >0 ise kapak üzerinde yıldız tozu ve köşede "+N" rozeti gösterilir.
  final int newCount;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool highlighted = newCount > 0;
    // Mor yüzeyde ikon/metin kontrastı için onSecondary; nötr karoda varsayılan.
    final Color iconColor = highlighted ? scheme.onSecondary : scheme.primary;
    final Color labelColor = highlighted
        ? scheme.onSecondary
        : scheme.onSurface;
    final Color countColor = highlighted
        ? scheme.onSecondary.withValues(alpha: 0.75)
        : scheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _CoverStrip(covers: covers, icon: icon),
                  // Yeni içerik vurgusu: kapak üzerinde parıldayan yıldız tozu.
                  if (highlighted) const IgnorePointer(child: BoardStardust()),
                  if (highlighted)
                    Positioned(
                      top: AppSpacing.xs,
                      right: AppSpacing.xs,
                      child: _NewBadge(count: newCount),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: AppSpacing.xs + 2),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            context.l10n.galleryCount(count),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: countColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kapak köşesindeki "+N" rozeti: ikincil (mor) dolgu, üstünde okunur metin.
class _NewBadge extends StatelessWidget {
  const _NewBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      // Mor karonun üstünde okunması için ters renk: açık dolgu + mor metin.
      decoration: BoxDecoration(
        color: scheme.onSecondary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        context.l10n.boardsNewBadge(count),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.secondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Kapak alanı: içerik varsa yan yana mini thumbnail'lar, yoksa ikonlu dolgu.
class _CoverStrip extends StatelessWidget {
  const _CoverStrip({required this.covers, required this.icon});

  final List<AssetEntity> covers;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color tint = scheme.primary.withValues(alpha: 0.06);

    if (covers.isEmpty) {
      return Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: AppSizes.boardCoverMin),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(
          icon,
          color: scheme.primary.withValues(alpha: 0.45),
          size: 28,
        ),
      );
    }

    return Row(
      children: [
        for (int i = 0; i < kBoardCoverCount; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: SizedBox.expand(
                child: i < covers.length
                    ? AssetEntityImage(
                        covers[i],
                        isOriginal: false,
                        // Mini kapak için düşük çözünürlük yeterli.
                        thumbnailSize: const ThumbnailSize.square(200),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            ColoredBox(color: tint),
                      )
                    : ColoredBox(color: tint),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Yeni içerik alan karoyu periyodik olarak minik bir zıplama (hop) ile
/// vurgular: çoğunlukla sabit durur, aralıklarla kısaca yukarı sekip yumuşak
/// yaylanmayla iner. [active] false ise çocuk aynen (animasyonsuz) döner.
class NewTileBounce extends StatefulWidget {
  const NewTileBounce({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<NewTileBounce> createState() => _NewTileBounceState();
}

class _NewTileBounceState extends State<NewTileBounce>
    with SingleTickerProviderStateMixin {
  /// Zıplama yüksekliği (px) — dikkat çeker ama abartısız kalır.
  static const double _hop = 6;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );

  // Döngü: uzun dinlenme → hızlı yukarı sıçrama → yaylanarak iniş → kısa bekle.
  late final Animation<double> _dy = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween<double>(0), weight: 58),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 0,
        end: -_hop,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 8,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: -_hop,
        end: 0,
      ).chain(CurveTween(curve: Curves.bounceOut)),
      weight: 16,
    ),
    TweenSequenceItem(tween: ConstantTween<double>(0), weight: 18),
  ]).animate(_controller);

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(NewTileBounce oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _dy,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _dy.value),
        child: child,
      ),
    );
  }
}

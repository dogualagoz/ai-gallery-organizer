// Görüntüleyicinin tek sayfası: kıstırarak ve çift dokunuşla yakınlaştırılan
// görsel. Izgara karosuyla Hero bağı burada kurulur (köşe yarıçapı uçuşta
// yumuşakça açılır, bekliyor noktası uçmaz).
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/motion_constants.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/utils/motion_physics.dart';
import '../../gallery/widgets/screenshot_grid_tile.dart';

/// Hero uçuşunun eğrisi: geçiş süresine yayılmış sekmesiz yay. Kapanışta
/// Hero bunu tersine çevirip uygular; görsel iki yönde de yay gibi yavaşlar.
final Curve _flightCurve = SpringCurve(
  AppSprings.standard,
  AppViewer.transition,
);

/// Görüntüleyicide [asset]'in tek sayfası.
class PhotoPage extends StatefulWidget {
  const PhotoPage({
    super.key,
    required this.asset,
    required this.heroTag,
    required this.isCurrent,
    required this.heroEnabled,
    required this.fitRequested,
    required this.onTap,
    required this.onZoomChanged,
  });

  /// Görsel kaynağı; kütüphane henüz eşitlenmediyse null olabilir.
  final AssetEntity? asset;

  /// Izgara karosuyla eşleşen Hero etiketi ([screenshotHeroTag]).
  final String heroTag;

  /// Görüntüleyicide şu an görünen sayfa mı; değilse yakınlaştırma bırakılır.
  final bool isCurrent;

  /// Yalnız görünen sayfa uçar; komşu sayfaların eşleşen karoları yerinde
  /// kalmalı.
  final bool heroEnabled;

  /// true'ya dönünce yakınlaştırma sıfırlanır (ör. bilgi paneli açıldı).
  final bool fitRequested;

  /// Tek dokunuş (çift dokunuş ayırt edildikten sonra).
  final VoidCallback onTap;

  /// Sayfa yakınlaştırılmış hale girince/çıkınca bildirilir.
  final ValueChanged<bool> onZoomChanged;

  @override
  State<PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage>
    with SingleTickerProviderStateMixin {
  final TransformationController _transform = TransformationController();

  /// Çift dokunuş yakınlaştırmasının ilerlemesi (0 → 1); kıstırma başlarsa
  /// yarıda durur, kullanıcı o anki matristen devam eder.
  late final AnimationController _zoom = AnimationController.unbounded(
    vsync: this,
  );
  Matrix4Tween? _zoomTween;
  Offset _doubleTapAt = Offset.zero;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _zoom
      ..addListener(_applyZoom)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _syncZoomed();
      });
  }

  @override
  void didUpdateWidget(PhotoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCurrent && !widget.isCurrent) {
      // Kaydırma yarıda dönerse sayfa yakınlaştırılmış geri gelmesin:
      // görüntüleyici onu sığdırılmış sayıyor.
      _zoom.stop();
      _transform.value = Matrix4.identity();
      _zoomed = false;
      return;
    }
    if (widget.fitRequested && !oldWidget.fitRequested && _isZoomed) {
      _animateTo(Matrix4.identity());
    }
  }

  @override
  void dispose() {
    _zoom.dispose();
    _transform.dispose();
    super.dispose();
  }

  bool get _isZoomed =>
      _transform.value.getMaxScaleOnAxis() > AppViewer.zoomedThreshold;

  void _applyZoom() {
    final Matrix4Tween? tween = _zoomTween;
    if (tween != null) {
      _transform.value = tween.transform(_zoom.value.clamp(0.0, 1.0));
    }
  }

  void _syncZoomed() {
    final bool zoomed = _isZoomed;
    if (zoomed == _zoomed) return;
    _zoomed = zoomed;
    widget.onZoomChanged(zoomed);
  }

  /// Yakınlaştırılmışsa sığdırır; değilse dokunulan noktayı sabit tutarak
  /// yakınlaştırır (nokta ekranda yerinde kalır, çevresi büyür).
  void _toggleZoom() {
    if (_isZoomed) {
      _animateTo(Matrix4.identity());
      return;
    }
    const double scale = AppViewer.doubleTapZoom;
    final Offset focus = _doubleTapAt;
    _animateTo(
      Matrix4.identity()
        ..translateByDouble(
          focus.dx * (1 - scale),
          focus.dy * (1 - scale),
          0,
          1,
        )
        ..scaleByDouble(scale, scale, 1, 1),
    );
  }

  void _animateTo(Matrix4 target) {
    _zoomTween = Matrix4Tween(begin: _transform.value.clone(), end: target);
    _zoom.value = 0;
    if (context.reduceMotion) {
      _zoom.animateTo(1, duration: AppMotion.reducedCrossfade);
      return;
    }
    _zoom.animateWith(SpringSimulation(AppSprings.standard, 0, 1, 0));
  }

  @override
  Widget build(BuildContext context) {
    final AssetEntity? asset = widget.asset;
    final double aspect = asset == null || asset.width <= 0 || asset.height <= 0
        ? kScreenshotTileAspect
        : asset.width / asset.height;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onDoubleTapDown: (details) => _doubleTapAt = details.localPosition,
      onDoubleTap: _toggleZoom,
      child: InteractiveViewer(
        transformationController: _transform,
        minScale: 1,
        maxScale: AppViewer.maxZoom,
        onInteractionStart: (_) => _zoom.stop(),
        onInteractionEnd: (_) => _syncZoomed(),
        child: Center(
          child: AspectRatio(
            aspectRatio: aspect,
            child: HeroMode(
              enabled: widget.heroEnabled,
              child: Hero(
                tag: widget.heroTag,
                curve: _flightCurve,
                // Düz yol (Material'ın kavisli varsayılanı yerine).
                createRectTween: (begin, end) =>
                    RectTween(begin: begin, end: end),
                flightShuttleBuilder: _flightShuttle,
                child: ViewerImage(asset: asset),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Uçan görsel: köşe yarıçapı karonunkiyle 0 arasında, yolla aynı eğride
  /// değişir ([animation] Hero eğrisinden geçmiş gelir). Açılışta karonun önbellekteki küçük resmi uçar (tam çözünürlük
  /// uçuş sırasında çözülmez); kapanışta ekrandaki keskin görsel.
  Widget _flightShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final bool push = direction == HeroFlightDirection.push;
    final double tileRadius = ScreenshotGridTile.radiusOf(
      push ? fromHeroContext : toHeroContext,
    );
    final AssetEntity? asset = widget.asset;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double t = animation.value;
        final double radius = push
            ? lerpDouble(tileRadius, 0, t)!
            : lerpDouble(0, tileRadius, t)!;
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: child,
        );
      },
      child: push ? ViewerThumbnail(asset: asset) : ViewerImage(asset: asset),
    );
  }
}

/// Izgara karosunun kullandığı küçük resim; önbellekte olduğundan anında
/// görünür.
class ViewerThumbnail extends StatelessWidget {
  const ViewerThumbnail({super.key, required this.asset});

  final AssetEntity? asset;

  @override
  Widget build(BuildContext context) {
    final AssetEntity? image = asset;
    if (image == null) return const _MissingImage();
    return AssetEntityImage(
      image,
      isOriginal: false,
      thumbnailSize: const ThumbnailSize.square(AppGridTile.thumbnailPx),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const _MissingImage(),
    );
  }
}

/// Görüntüleyici görseli: önce küçük resim, tam çözünürlük çözülünce
/// üstüne biner (aynı içerik olduğundan geçiş fark edilmez, yalnız keskinleşir).
class ViewerImage extends StatelessWidget {
  const ViewerImage({
    super.key,
    required this.asset,
    this.maxPx = AppViewer.fullImageMaxPx,
  });

  final AssetEntity? asset;

  /// Keskin görselin uzun kenar sınırı (px); küçük yüzeyler daha azını ister.
  final int maxPx;

  @override
  Widget build(BuildContext context) {
    final AssetEntity? image = asset;
    if (image == null) return const _MissingImage();
    return Stack(
      fit: StackFit.expand,
      children: [
        ViewerThumbnail(asset: image),
        AssetEntityImage(
          image,
          isOriginal: false,
          thumbnailSize: viewerFullSize(image, maxPx: maxPx),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
              wasSynchronouslyLoaded || frame != null
              ? child
              : const SizedBox.shrink(),
          errorBuilder: (context, error, stackTrace) {
            // Küçük resim altta kaldığı için kullanıcıya ayrı hata gösterilmez.
            debugPrint('Tam çözünürlük yüklenemedi (${image.id}): $error');
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

/// Görüntüleyicide istenen tam çözünürlük: varlığın kendi ölçüsü, uzun kenarı
/// [maxPx] ile sınırlı. Ön yükleme de aynı ölçüyü kullanır (önbellek anahtarı
/// eşleşsin).
ThumbnailSize viewerFullSize(
  AssetEntity asset, {
  int maxPx = AppViewer.fullImageMaxPx,
}) {
  final int longest = math.max(asset.width, asset.height);
  if (longest <= 0) {
    return ThumbnailSize(
      AppViewer.fallbackFullSize.width.round(),
      AppViewer.fallbackFullSize.height.round(),
    );
  }
  final double scale = math.min(1, maxPx / longest);
  return ThumbnailSize(
    (asset.width * scale).round(),
    (asset.height * scale).round(),
  );
}

/// Görsel yoksa ya da yüklenemediyse dolgunun ortasındaki fotoğraf glifi.
class _MissingImage extends StatelessWidget {
  const _MissingImage();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHigh,
      child: Center(child: Icon(AppIcons.photo, color: scheme.outline)),
    );
  }
}

// Görüntüleyicinin katmanları: zemin, sayfalar, bilgi paneli ve arayüz
// solması. Her katman yalnız dinlediği değer değişince yeniden kurulur.
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/cupertino.dart' show kMinInteractiveDimensionCupertino;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/constants/motion_constants.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/models/screenshot_entry.dart';
import '../../../core/utils/motion_physics.dart';
import '../../gallery/widgets/screenshot_grid_tile.dart';
import '../logic/viewer_motion.dart';
import 'info_panel.dart';
import 'photo_page.dart';

/// Arayüz açıkken sistem zemini, gizliyken siyah; aşağı çekişte solar ve
/// arkadaki ızgara görünür.
class ViewerBackdrop extends StatelessWidget {
  const ViewerBackdrop({
    super.key,
    required this.chrome,
    required this.motion,
    required this.changes,
    required this.height,
  });

  /// Arayüz görünürlüğü: 1 görünür, 0 gizli.
  final Animation<double> chrome;

  /// Aşağı çekiş ofseti buradan okunur (kapanırken zemin solar).
  final ViewerMotion motion;

  /// [chrome] ile sürükleme ofsetinin birleşimi (State'te bir kez kurulur).
  final Listenable changes;

  /// Görüntüleyicinin yüksekliği (kapanma ilerlemesinin ölçeği).
  final double height;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: changes,
      builder: (context, _) {
        final Color color = Color.lerp(
          scheme.scrim,
          scheme.surfaceContainerLowest,
          chrome.value.clamp(0.0, 1.0),
        )!;
        return ColoredBox(
          color: color.withValues(alpha: 1 - motion.dismissProgress(height)),
        );
      },
    );
  }
}

/// Sayfalar: panel açıldıkça üst çubukla panel arasına sığar; aşağı
/// çekişte parmağı izleyip küçülür. Yakınlaştırılmışken aşağı çekiş kapalı.
class ViewerPagesLayer extends StatelessWidget {
  const ViewerPagesLayer({
    super.key,
    required this.motion,
    required this.height,
    required this.zoomed,
    required this.pages,
  });

  /// Aşağı çekiş jesti ve panel açıklığı.
  final ViewerMotion motion;

  /// Görüntüleyicinin yüksekliği (panel ve kapanma ölçeği).
  final double height;

  /// true iken aşağı çekiş kapalı (sayfa yakınlaştırılmış).
  final ValueListenable<bool> zoomed;

  /// Sayfa görünümü; yalnız yakınlaştırma durumu değişince yeniden kurulur.
  final Widget Function(BuildContext context, bool zoomed) pages;

  @override
  Widget build(BuildContext context) {
    final double panel = ViewerMotion.panelHeight(height);
    final double barBottom =
        MediaQuery.paddingOf(context).top +
        kMinInteractiveDimensionCupertino +
        AppSpacing.sm;

    return AnimatedBuilder(
      animation: motion.info,
      builder: (context, child) {
        final double open = math.max(0, motion.info.value);
        return Positioned(
          left: 0,
          right: 0,
          top: barBottom * math.min(open, 1),
          bottom: panel * open,
          child: child!,
        );
      },
      child: ValueListenableBuilder<bool>(
        valueListenable: zoomed,
        builder: (context, zoomed, _) => _dragSurface(context, zoomed),
      ),
    );
  }

  Widget _dragSurface(BuildContext context, bool zoomed) {
    final bool canDrag = !zoomed;
    return GestureDetector(
      onVerticalDragStart: canDrag ? motion.dragStart : null,
      onVerticalDragUpdate: canDrag
          ? (details) => motion.dragUpdate(details, height)
          : null,
      onVerticalDragEnd: canDrag
          ? (details) => motion.dragEnd(details, height)
          : null,
      onVerticalDragCancel: canDrag ? () => motion.dragCancel(height) : null,
      child: ValueListenableBuilder<Offset>(
        valueListenable: motion.drag,
        builder: (context, offset, child) => Transform.translate(
          offset: offset,
          child: Transform.scale(
            scale: lerpDouble(
              1,
              AppViewer.dismissMinScale,
              motion.dismissProgress(height),
            ),
            child: child,
          ),
        ),
        child: pages(context, zoomed),
      ),
    );
  }
}

/// Kaydırılabilen sayfalar. Görünen sayfa ve panel hedefi değişince yalnız
/// sayfalar kendini tazeler; sayfa görünümü liste (ya da yakınlaştırma)
/// değişmedikçe yeniden kurulmaz.
class ViewerPageView extends StatelessWidget {
  const ViewerPageView({
    super.key,
    required this.controller,
    required this.ids,
    required this.assetFor,
    required this.current,
    required this.infoTarget,
    required this.pageState,
    required this.zoomed,
    required this.onPageChanged,
    required this.onTap,
    required this.onZoomChanged,
  });

  final PageController controller;

  /// Sayfaların kimlikleri, kapsam sırasıyla.
  final List<String> ids;

  /// Kimliğin görseli; kütüphane henüz eşitlenmediyse null.
  final AssetEntity? Function(String id) assetFor;

  /// Görünen sayfanın kimliği.
  final ValueListenable<String> current;

  /// Bilgi panelinin hedefi (açılırken yakınlaştırılmış sayfa sığdırılır).
  final ValueListenable<bool> infoTarget;

  /// [current] ile [infoTarget]'ın birleşimi (State'te bir kez kurulur).
  final Listenable pageState;

  /// true iken yatay kaydırma kilitli.
  final bool zoomed;
  final ValueChanged<int> onPageChanged;

  /// Sayfaya tek dokunuş (arayüzü gizle/göster).
  final VoidCallback onTap;

  /// [id] sayfasının yakınlaştırma durumu değişti.
  final void Function(String id, bool zoomed) onZoomChanged;

  @override
  Widget build(BuildContext context) {
    final Map<String, int> indexOf = {
      for (int i = 0; i < ids.length; i++) ids[i]: i,
    };
    return PageView.builder(
      controller: controller,
      physics: zoomed ? const NeverScrollableScrollPhysics() : null,
      itemCount: ids.length,
      findChildIndexCallback: (key) =>
          key is ValueKey<String> ? indexOf[key.value] : null,
      onPageChanged: onPageChanged,
      itemBuilder: (context, index) {
        final String id = ids[index];
        return ListenableBuilder(
          key: ValueKey<String>(id),
          listenable: pageState,
          builder: (context, _) {
            final bool isCurrent = id == current.value;
            return PhotoPage(
              asset: assetFor(id),
              heroTag: screenshotHeroTag(id),
              isCurrent: isCurrent,
              heroEnabled: isCurrent && !context.reduceMotion,
              fitRequested: infoTarget.value,
              onTap: onTap,
              onZoomChanged: (zoomed) => onZoomChanged(id, zoomed),
            );
          },
        );
      },
    );
  }
}

/// Bilgi paneli alttan yükselir; başlığından sürüklenebilir, içeriği
/// ayrıca kaydırılır.
class ViewerInfoLayer extends StatelessWidget {
  const ViewerInfoLayer({
    super.key,
    required this.motion,
    required this.height,
    required this.entry,
    required this.bottomInset,
    required this.onMove,
    required this.onTag,
  });

  /// Panel açıklığı ve başlıktan sürükleme jesti.
  final ViewerMotion motion;

  /// Görüntüleyicinin yüksekliği (panel yüksekliğinin ölçeği).
  final double height;

  /// Görünen kayıt.
  final ScreenshotEntry entry;

  /// Panel içeriğinin altta araç çubuğuna bıraktığı boşluk.
  final double bottomInset;
  final VoidCallback onMove;
  final ValueChanged<String> onTag;

  @override
  Widget build(BuildContext context) {
    final double panel = ViewerMotion.panelHeight(height);
    return AnimatedBuilder(
      animation: motion.info,
      builder: (context, child) {
        final double open = math.max(0, motion.info.value);
        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          // Yay 1'i aşarsa panel uzar; altında boşluk açılmaz.
          height: panel * math.max(1, open),
          child: Offstage(
            offstage: open <= 0,
            child: Transform.translate(
              offset: Offset(0, panel * (1 - math.min(open, 1))),
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        onVerticalDragStart: motion.dragStart,
        onVerticalDragUpdate: (details) => motion.dragUpdate(details, height),
        onVerticalDragEnd: (details) => motion.dragEnd(details, height),
        onVerticalDragCancel: () => motion.dragCancel(height),
        child: ViewerInfoPanel(
          key: ValueKey<String>(entry.assetId),
          entry: entry,
          bottomInset: bottomInset,
          onMove: onMove,
          onTag: onTag,
        ),
      ),
    );
  }
}

/// Üst çubuk ve araç çubuğu: arayüzle birlikte söner, aşağı çekişte solar.
/// Gizliyken dokunuş ve erişilebilirlik ağacından da çıkar.
class ViewerChromeFade extends StatelessWidget {
  const ViewerChromeFade({
    super.key,
    required this.visible,
    required this.chrome,
    required this.motion,
    required this.changes,
    required this.height,
    required this.child,
  });

  /// Arayüzün hedef görünürlüğü (dokunuş ve erişilebilirlik).
  final ValueListenable<bool> visible;

  /// Arayüz görünürlüğü animasyonu: 1 görünür, 0 gizli.
  final Animation<double> chrome;

  /// Aşağı çekiş ofseti buradan okunur.
  final ViewerMotion motion;

  /// [chrome] ile sürükleme ofsetinin birleşimi (State'te bir kez kurulur).
  final Listenable changes;

  /// Görüntüleyicinin yüksekliği (kapanma ilerlemesinin ölçeği).
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: visible,
      child: AnimatedBuilder(
        animation: changes,
        child: child,
        builder: (context, child) => Opacity(
          opacity:
              chrome.value.clamp(0.0, 1.0) *
              (1 - motion.dismissProgress(height)),
          child: child,
        ),
      ),
      builder: (context, visible, child) => IgnorePointer(
        ignoring: !visible,
        child: ExcludeSemantics(excluding: !visible, child: child),
      ),
    );
  }
}

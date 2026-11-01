// Yüzen buzlu-cam yüzey: arkasını bulanıklaştırıp renklerini canlandırır,
// üst kenarda ışık yakalayan parlak çizgi + yumuşak gölgeyle havada durur.
import 'dart:ui';

import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';

/// Glassmorphism zemin (navbar pili, ayrık Arama butonu, toast). [borderRadius]
/// şekli belirler: pil için `yükseklik/2`, daire için `çap/2`. [child] camın
/// ÜSTÜNDE çizilir — bulanıklığa girmez, okunur kalır. Arkadan akan içeriği
/// örnekleyebilmesi için içerik altına uzanan bir katmanda kullanılmalı
/// (ör. `Scaffold(extendBody: true)` ya da Overlay).
///
/// Yüksek kontrast açıkken cam yerine düz dolgu + belirgin kenarlık çizilir
/// (Apple "Reduce Transparency / Increase Contrast" karşılığı).
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.borderRadius,
    required this.child,
  });

  final BorderRadius borderRadius;
  final Widget child;

  /// Blur'dan sonra uygulanan doygunluk matrisi (Rec. 709 luma ağırlıkları).
  static final ColorFilter _saturate = _saturationMatrix(AppGlass.saturation);

  static ColorFilter _saturationMatrix(double s) {
    const double r = 0.2126;
    const double g = 0.7152;
    const double b = 0.0722;
    final double inv = 1 - s;
    return ColorFilter.matrix(<double>[
      r * inv + s, g * inv, b * inv, 0, 0, //
      r * inv, g * inv + s, b * inv, 0, 0, //
      r * inv, g * inv, b * inv + s, 0, 0, //
      0, 0, 0, 1, 0, //
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = scheme.brightness == Brightness.dark;
    final bool highContrast = MediaQuery.highContrastOf(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(
              alpha: isDark ? AppGlass.shadowAlphaDark : AppGlass.shadowAlpha,
            ),
            blurRadius: AppGlass.shadowBlur,
            offset: const Offset(0, AppGlass.shadowOffsetY),
          ),
        ],
      ),
      child: highContrast
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: borderRadius,
                border: Border.all(color: scheme.outline),
              ),
              child: child,
            )
          : _glass(context, scheme, isDark),
    );
  }

  Widget _glass(BuildContext context, ColorScheme scheme, bool isDark) {
    // "Işık" iki temada da beyazdır: açıkta surface, koyuda onSurface.
    final Color light = isDark ? scheme.onSurface : scheme.surface;
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        // Ata bir BackdropGroup varsa (ör. sekme çubuğu) yan yana camlar tek
        // arka plan örneğini paylaşır; motor bulanıklığı bir kez hesaplar.
        backdropGroupKey: BackdropGroup.of(context)?.backdropKey,
        filter: ImageFilter.compose(
          outer: _saturate,
          inner: ImageFilter.blur(
            sigmaX: AppGlass.blurSigma,
            sigmaY: AppGlass.blurSigma,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface.withValues(
              alpha: isDark ? AppGlass.fillAlphaDark : AppGlass.fillAlpha,
            ),
            borderRadius: borderRadius,
            border: Border.all(
              color: scheme.onSurface.withValues(
                alpha: isDark ? AppGlass.borderAlphaDark : AppGlass.borderAlpha,
              ),
            ),
          ),
          child: CustomPaint(
            foregroundPainter: _RimPainter(
              borderRadius: borderRadius,
              top: light.withValues(
                alpha: isDark ? AppGlass.rimAlphaTopDark : AppGlass.rimAlphaTop,
              ),
              bottom: light.withValues(alpha: AppGlass.rimAlphaBottom),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Üstten aşağı sönen ince parlak kenar — ışığın malzemenin üst kenarına
/// vurması. Kenarlık yalnız tek renk alabildiği için gradient boyanır.
class _RimPainter extends CustomPainter {
  const _RimPainter({
    required this.borderRadius,
    required this.top,
    required this.bottom,
  });

  final BorderRadius borderRadius;
  final Color top;
  final Color bottom;

  @override
  void paint(Canvas canvas, Size size) {
    const double inset = AppGlass.rimWidth / 2;
    final Rect rect = (Offset.zero & size).deflate(inset);
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppGlass.rimWidth
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [top, bottom],
      ).createShader(rect);
    canvas.drawRRect(borderRadius.toRRect(rect), paint);
  }

  @override
  bool shouldRepaint(_RimPainter oldDelegate) =>
      oldDelegate.top != top ||
      oldDelegate.bottom != bottom ||
      oldDelegate.borderRadius != borderRadius;
}

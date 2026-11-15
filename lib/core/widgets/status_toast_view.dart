// Durum toast'unun görünümü ve hareketi: üstten yayla iner, geldiği yoldan
// çıkar, yukarı fırlatılarak kapatılabilir. Gösterim API'si status_toast.dart'ta.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart';

import '../constants/app_icons.dart';
import '../constants/motion_constants.dart';
import '../constants/ui_constants.dart';
import '../utils/motion_physics.dart';
import 'glass_panel.dart';
import 'pressable.dart';

/// Bildirimin anlamı: ikon ve rengini belirler.
enum StatusToastTone { neutral, success, error }

/// Kök Overlay'de çizilen tek toast; süresi dolunca ya da fırlatılınca
/// çıkar ve [onDismissed]'i çağırır. Doğrudan değil, `StatusToaster`
/// üzerinden kullanılır.
class StatusToastView extends StatefulWidget {
  const StatusToastView({
    super.key,
    required this.message,
    required this.tone,
    required this.onDismissed,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final StatusToastTone tone;

  /// Tonun varsayılan ikonunun yerine geçer.
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Çıkış hareketi bitince (ya da kesilince) çağrılır.
  final VoidCallback onDismissed;

  @override
  State<StatusToastView> createState() => _StatusToastViewState();
}

class _StatusToastViewState extends State<StatusToastView>
    with TickerProviderStateMixin {
  /// Dinlenme konumuna göre dikey ofset (px); negatif = yukarıda.
  late final AnimationController _offset = AnimationController.unbounded(
    vsync: this,
  );

  /// Reduce Motion'da kayma yerine kullanılan çapraz geçiş.
  late final AnimationController _opacity = AnimationController(
    vsync: this,
    duration: AppMotion.reducedCrossfade,
  );

  /// Ofset ve opaklığın birleşimi; her build'de yeniden kurulmaz.
  late final Listenable _changes = Listenable.merge([_offset, _opacity]);

  Timer? _timer;
  bool _started = false;
  bool _dismissing = false;
  bool _reduceMotion = false;

  /// Gizli konuma uzaklık: status bar + kapsül + pay; ekran dışında kalır.
  double _travel = AppToast.minHeight * 2;

  /// Sürüklemede parmağın ham yer değiştirmesi (lastik bant öncesi).
  double _dragRaw = 0;

  bool get _hasAction => widget.actionLabel != null && widget.onAction != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = context.reduceMotion;
    _travel = MediaQuery.paddingOf(context).top + AppToast.minHeight * 2;
    if (_started) return;
    _started = true;
    _enter();
    SemanticsService.sendAnnouncement(
      View.of(context),
      widget.message,
      Directionality.of(context),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _offset.dispose();
    _opacity.dispose();
    super.dispose();
  }

  void _enter() {
    if (_reduceMotion) {
      _opacity.forward();
    } else {
      _opacity.value = 1;
      _offset.value = -_travel;
      _springTo(0, AppSprings.standard);
    }
    _scheduleDismiss();
  }

  void _scheduleDismiss() {
    _timer?.cancel();
    _timer = Timer(
      _hasAction ? AppToast.durationWithAction : AppToast.duration,
      _dismiss,
    );
  }

  TickerFuture _springTo(
    double target,
    SpringDescription spring, [
    double velocity = 0,
  ]) {
    return _offset.animateWith(
      SpringSimulation(spring, _offset.value, target, velocity),
    );
  }

  /// Geldiği yoldan çıkar; [velocity] fırlatmadan devralınan hızdır.
  void _dismiss({double velocity = 0}) {
    if (_dismissing) return;
    _dismissing = true;
    _timer?.cancel();
    final TickerFuture exit = _reduceMotion && velocity == 0
        ? _opacity.reverse()
        : _springTo(-_travel, AppSprings.standard, velocity);
    exit.whenCompleteOrCancel(widget.onDismissed);
  }

  void _onDragStart(DragStartDetails _) {
    if (_dismissing) return;
    _timer?.cancel();
    _offset.stop();
    _dragRaw = _offset.value;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_dismissing) return;
    _dragRaw += details.delta.dy;
    // Yukarı 1:1 takip; aşağı (anlamsız yön) artan dirençle esner.
    _offset.value = _dragRaw <= 0 ? _dragRaw : rubberband(_dragRaw, _travel);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dismissing) return;
    final double velocity = details.velocity.pixelsPerSecond.dy;
    final double projected =
        _offset.value +
        project(velocity, decelerationRate: AppMotion.decelerationFast);
    if (projected < -AppToast.minHeight / 2) {
      _dismiss(velocity: velocity);
    } else {
      _springTo(0, AppSprings.momentum, velocity);
      _scheduleDismiss();
    }
  }

  /// Sürükleme sistem jestine/başka tanıyıcıya kaptırılırsa: yerine dön ve
  /// süreyi yeniden kur (aksi halde toast yarım kayık asılı kalırdı).
  void _onDragCancel() {
    if (_dismissing) return;
    _springTo(0, AppSprings.standard);
    _scheduleDismiss();
  }

  void _onAction() {
    widget.onAction?.call();
    _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
      left: AppSpacing.md,
      right: AppSpacing.md,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppToast.maxWidth),
          child: AnimatedBuilder(
            animation: _changes,
            builder: (context, child) => Opacity(
              opacity: _opacity.value,
              child: Transform.translate(
                offset: Offset(0, _offset.value),
                child: child,
              ),
            ),
            child: GestureDetector(
              onVerticalDragStart: _onDragStart,
              onVerticalDragUpdate: _onDragUpdate,
              onVerticalDragEnd: _onDragEnd,
              onVerticalDragCancel: _onDragCancel,
              child: Material(
                type: MaterialType.transparency,
                child: GlassPanel(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: _ToastContent(
                    message: widget.message,
                    tone: widget.tone,
                    icon: widget.icon,
                    actionLabel: _hasAction ? widget.actionLabel : null,
                    onAction: _onAction,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kapsülün içi: ton ikonu, mesaj ve opsiyonel eylem.
class _ToastContent extends StatelessWidget {
  const _ToastContent({
    required this.message,
    required this.tone,
    required this.icon,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final StatusToastTone tone;
  final IconData? icon;

  /// Eylem yoksa null.
  final String? actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final String? label = actionLabel;
    final (IconData?, Color) glyph = switch (tone) {
      StatusToastTone.success => (
        icon ?? AppIcons.checkCircleFill,
        scheme.primary,
      ),
      StatusToastTone.error => (icon ?? AppIcons.errorFill, scheme.error),
      StatusToastTone.neutral => (icon, scheme.onSurfaceVariant),
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppToast.minHeight),
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: label != null ? AppSpacing.xs : AppSpacing.md,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (glyph.$1 != null) ...[
              Icon(glyph.$1, size: AppToast.iconSize, color: glyph.$2),
              const SizedBox(width: AppSpacing.sm),
            ],
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  // Cam üstünde okunurluk için bir kademe kalın (vibrancy).
                  style: text.titleSmall?.copyWith(color: scheme.onSurface),
                ),
              ),
            ),
            if (label != null)
              _ToastActionButton(label: label, onPressed: onAction),
          ],
        ),
      ),
    );
  }
}

/// Toast'un sağındaki metin aksiyonu (ör. "Geri al"); 44pt+ dokunma alanı.
class _ToastActionButton extends StatelessWidget {
  const _ToastActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Pressable(
      onPressed: onPressed,
      haptic: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: AppToast.minHeight,
          minHeight: AppToast.minHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: scheme.primary),
            ),
          ),
        ),
      ),
    );
  }
}

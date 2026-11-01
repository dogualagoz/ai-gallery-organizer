// Üstten yaylı kayan cam durum kapsülü: SnackBar'ın iOS karşılığı. Geldiği
// yoldan (yukarı) çıkar; parmakla yukarı fırlatılarak da kapatılabilir.
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart';

import '../constants/motion_constants.dart';
import '../constants/ui_constants.dart';
import '../utils/motion_physics.dart';
import 'glass_panel.dart';
import 'pressable.dart';

/// Bildirimin anlamı: ikon ve rengini belirler.
enum StatusToastTone { neutral, success, error }

/// Kök Overlay'e toast basan gösterici. `await` sonrası context geçersiz
/// kalabilecekse ([State.mounted] kontrolü gibi) await ÖNCESİ yakalanır:
/// `final toaster = StatusToaster.of(context);` → `toaster.show(...)`.
///
/// Toast kök Overlay'de yaşar, açan ekran kapansa da durur: ekran State'ine
/// dokunan `onAction` kendi içinde `mounted` kontrolü yapmalıdır.
class StatusToaster {
  StatusToaster.of(BuildContext context)
    : _overlay = Overlay.of(context, rootOverlay: true);

  final OverlayState _overlay;

  /// Aynı anda tek toast: yenisi gelince eskisi anında kalkar (üst üste
  /// iki cam kapsül okunmaz).
  static OverlayEntry? _current;

  /// [message]'ı gösterir. [actionLabel] + [onAction] verilirse sağda metin
  /// butonu çıkar (ör. "Geri al") ve süre uzar.
  void show(
    String message, {
    StatusToastTone tone = StatusToastTone.neutral,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    // Önce boşaltılır: eskisinin kapanış geri çağrısı kendini "güncel" sanıp
    // ikinci kez remove etmesin.
    final OverlayEntry? previous = _current;
    _current = null;
    previous?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _StatusToastView(
        message: message,
        tone: tone,
        icon: icon,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismissed: () {
          if (_current != entry) return;
          _current = null;
          entry.remove();
        },
      ),
    );
    _current = entry;
    _overlay.insert(entry);
  }
}

/// Tek seferlik kısayol: context hâlâ geçerliyken çağrılır.
void showStatusToast(
  BuildContext context,
  String message, {
  StatusToastTone tone = StatusToastTone.neutral,
  IconData? icon,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  StatusToaster.of(context).show(
    message,
    tone: tone,
    icon: icon,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}

class _StatusToastView extends StatefulWidget {
  const _StatusToastView({
    required this.message,
    required this.tone,
    required this.onDismissed,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final StatusToastTone tone;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismissed;

  @override
  State<_StatusToastView> createState() => _StatusToastViewState();
}

class _StatusToastViewState extends State<_StatusToastView>
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
            animation: Listenable.merge([_offset, _opacity]),
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
                  child: _content(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final (IconData?, Color) glyph = switch (widget.tone) {
      StatusToastTone.success => (
        widget.icon ?? CupertinoIcons.checkmark_circle_fill,
        scheme.primary,
      ),
      StatusToastTone.error => (
        widget.icon ?? CupertinoIcons.exclamationmark_circle_fill,
        scheme.error,
      ),
      StatusToastTone.neutral => (widget.icon, scheme.onSurfaceVariant),
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppToast.minHeight),
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: _hasAction ? AppSpacing.xs : AppSpacing.md,
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
                  widget.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  // Cam üstünde okunurluk için bir kademe kalın (vibrancy).
                  style: text.titleSmall?.copyWith(color: scheme.onSurface),
                ),
              ),
            ),
            if (_hasAction)
              _ToastActionButton(
                label: widget.actionLabel!,
                onPressed: _onAction,
              ),
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

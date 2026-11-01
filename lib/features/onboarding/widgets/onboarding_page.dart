// Tek onboarding sayfası: üstte illüstrasyon, altta yayla beliren başlık,
// açıklama ve isteğe bağlı dipnot.
import 'package:flutter/material.dart';

import '../../../core/constants/motion_constants.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/utils/motion_physics.dart';

/// Onboarding sayfası. Metin değişince (ör. izin reddi) çapraz geçişle
/// yenilenir; illüstrasyon kendi katmanında çizilir ki döngüsü metni
/// yeniden boyatmasın.
class OnboardingPage extends StatelessWidget {
  /// Gövde ve dipnotun başlığa göre kademeli başlama oranları.
  static const double _bodyDelay = 0.25;
  static const double _noteDelay = 0.4;

  const OnboardingPage({
    super.key,
    required this.illustration,
    required this.title,
    required this.body,
    this.note,
  });

  final Widget illustration;
  final String title;
  final String body;

  /// Gövdenin altındaki küçük açıklama (ör. sınırlı erişim).
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              // Dekoratif: VoiceOver metne odaklansın.
              child: ExcludeSemantics(
                child: RepaintBoundary(child: illustration),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: AppMotion.reducedCrossfade,
            child: KeyedSubtree(
              key: ValueKey('$title\n$body'),
              child: _texts(context),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _texts(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color secondary = Theme.of(context).colorScheme.onSurfaceVariant;
    final String? noteText = note;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FadeSlideIn(
          child: Text(
            title,
            style: textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _FadeSlideIn(
          delayFraction: _bodyDelay,
          child: Text(
            body,
            style: textTheme.bodyLarge?.copyWith(color: secondary),
            textAlign: TextAlign.center,
          ),
        ),
        if (noteText != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _FadeSlideIn(
            delayFraction: _noteDelay,
            child: Text(
              noteText,
              style: textTheme.bodySmall?.copyWith(color: secondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}

/// Sayfa ilk kurulduğunda metni aşağıdan sekmesiz bir yayla getirir;
/// [delayFraction] ile sonraki satırlar kademeli başlar. Hareket
/// azaltıldığında yalnız kısa bir solma kalır.
class _FadeSlideIn extends StatelessWidget {
  const _FadeSlideIn({required this.child, this.delayFraction = 0});

  final Widget child;
  final double delayFraction;

  static final Curve _spring = SpringCurve(
    AppSprings.standard,
    AppDurations.slow,
  );

  @override
  Widget build(BuildContext context) {
    final bool reduce = context.reduceMotion;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduce ? AppMotion.reducedCrossfade : AppDurations.slow,
      curve: reduce
          ? Curves.linear
          : Interval(delayFraction, 1, curve: _spring),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, reduce ? 0 : (1 - t) * AppSpacing.md),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

// Açılış ekranı: logo elastik ölçekle "zıplar", altında uygulama adı belirir,
// eş zamanlı neşeli bir çınlama + haptik oynar (Duolingo tarzı). Animasyon
// bitince onboarding/galeriye yönlendirir. Her soğuk açılışta gösterilir.
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/ui_constants.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/router/app_router.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/preferences_service.dart';
import '../../core/widgets/brand_mark.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _total = Duration(milliseconds: 1900);
  static const double _markSize = 116;

  /// Açılış sesi asset yolu (audioplayers `assets/` önekini kendi ekler).
  static const String _chimeAsset = 'audio/snaply_chime.wav';

  late final AnimationController _controller;
  late final Animation<double> _markScale;
  late final Animation<double> _markOpacity;
  late final Animation<double> _nameOpacity;
  late final Animation<double> _nameShift;

  final AudioPlayer _player = AudioPlayer();
  bool _landed = false; // iniş haptiği tek sefer

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _total);

    // Logo: elastik "zıplama" ile büyür; hızla görünür.
    _markScale = Tween<double>(begin: 0.35, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.62, curve: Curves.elasticOut)),
    );
    _markOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.18, curve: Curves.easeOut),
    );

    // Uygulama adı: logonun altından yukarı kayarak belirir.
    _nameOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.42, 0.72, curve: Curves.easeOut),
    );
    _nameShift = Tween<double>(begin: AppSpacing.md, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.42, 0.78, curve: Curves.easeOutCubic)),
    );

    // Zıplama tepe noktasına gelince tek bir hafif iniş haptiği.
    _controller.addListener(_maybeLandHaptic);
    _controller.addStatusListener(_onStatus);

    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  /// Animasyonu başlatır ve çınlamayı çalar. Erişilebilirlik için hareket
  /// azaltma açıksa animasyonu atlayıp doğrudan sona gider.
  Future<void> _play() async {
    if (!mounted) return;
    Haptics.tap();
    _playChime();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1;
      await Future<void>.delayed(AppDurations.slow);
      _goNext();
    } else {
      _controller.forward();
    }
  }

  Future<void> _playChime() async {
    try {
      await _player.play(AssetSource(_chimeAsset), volume: 0.85);
    } catch (error) {
      // Ses açılışı engellememeli; sessiz mod/izin durumlarında yut.
      debugPrint('Açılış sesi çalınamadı: $error');
    }
  }

  void _maybeLandHaptic() {
    if (!_landed && _controller.value >= 0.45) {
      _landed = true;
      Haptics.tick();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _goNext();
  }

  /// Onboarding tamamlandıysa galeriye, değilse onboarding'e geçer.
  void _goNext() {
    if (!mounted) return;
    final bool onboarded = ref.read(onboardingCompleteProvider);
    context.go(onboarded ? AppRoutes.gallery : AppRoutes.onboarding);
  }

  @override
  void dispose() {
    _controller.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextStyle? nameStyle = Theme.of(context).textTheme.headlineMedium
        ?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface);

    return Scaffold(
      body: DecoratedBox(
        // Logonun arkasında incelikli iris parıltısı.
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.2),
            radius: 0.9,
            colors: [
              scheme.primary.withValues(alpha: 0.10),
              scheme.surface,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _markOpacity,
                child: ScaleTransition(
                  scale: _markScale,
                  child: const BrandMark(size: _markSize),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => Opacity(
                  opacity: _nameOpacity.value,
                  child: Transform.translate(
                    offset: Offset(0, _nameShift.value),
                    child: child,
                  ),
                ),
                child: Text(context.l10n.appTitle, style: nameStyle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

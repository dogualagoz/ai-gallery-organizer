// 4 sayfalık animasyonlu onboarding: değer önerisi, gizlilik, haftalık
// ücretsiz kota ve izin isteme. İzin verilince onboarding bayrağı
// işaretlenir; router otomatik galeriye alır.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/ui_constants.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/photo_permission_service.dart';
import '../../core/services/preferences_service.dart';
import 'widgets/access_illustration.dart';
import 'widgets/privacy_illustration.dart';
import 'widgets/quota_illustration.dart';
import 'widgets/sort_illustration.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const int _pageCount = 4;

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _requestingPermission = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  Haptics.tap();
                  setState(() => _currentPage = page);
                },
                children: [
                  _OnboardingPage(
                    illustration: const SortIllustration(),
                    title: l10n.onboardingTitle1,
                    body: l10n.onboardingBody1,
                  ),
                  _OnboardingPage(
                    illustration: const PrivacyIllustration(),
                    title: l10n.onboardingTitle2,
                    body: l10n.onboardingBody2,
                  ),
                  _OnboardingPage(
                    illustration: const QuotaIllustration(),
                    title: l10n.onboardingTitleQuota(FreeLimits.aiAnalysis),
                    body: l10n.onboardingBodyQuota(FreeLimits.aiAnalysis),
                  ),
                  _OnboardingPage(
                    illustration: const AccessIllustration(),
                    title: l10n.onboardingTitle3,
                    body: l10n.onboardingBody3,
                  ),
                ],
              ),
            ),
            _PageDots(count: _pageCount, current: _currentPage),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: FilledButton(
                onPressed: _requestingPermission ? null : _onButtonPressed,
                child: Text(
                  _currentPage == _pageCount - 1
                      ? l10n.onboardingStart
                      : l10n.onboardingContinue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onButtonPressed() async {
    if (_currentPage < _pageCount - 1) {
      await _pageController.nextPage(
        duration: AppDurations.medium,
        curve: Curves.easeOutCubic,
      );
      return;
    }
    await _requestPermission();
  }

  Future<void> _requestPermission() async {
    setState(() => _requestingPermission = true);
    try {
      final PhotoPermissionResult result =
          await PhotoPermissionService.request();
      if (!mounted) return;

      if (result == PhotoPermissionResult.granted) {
        // Bayrak işaretlenince router redirect'i galeriye yönlendirir.
        await ref.read(onboardingCompleteProvider.notifier).markComplete();
      } else {
        await _showDeniedDialog();
      }
    } finally {
      if (mounted) setState(() => _requestingPermission = false);
    }
  }

  Future<void> _showDeniedDialog() {
    final l10n = context.l10n;
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.permissionDeniedTitle),
        content: Text(l10n.permissionDeniedBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.notNow),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              PhotoPermissionService.openSystemSettings();
            },
            child: Text(l10n.openSettings),
          ),
        ],
      ),
    );
  }
}

/// Tek onboarding sayfası: üstte illüstrasyon, altta başlık + açıklama.
class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.illustration,
    required this.title,
    required this.body,
  });

  final Widget illustration;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: illustration,
            ),
          ),
          _FadeSlideIn(
            child: Text(
              title,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _FadeSlideIn(
            delayFraction: 0.25,
            child: Text(
              body,
              style: textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

/// Sayfa ilk kurulduğunda başlık/gövdeyi aşağıdan yumuşakça getirir.
/// [delayFraction] ile ikinci satır kademeli (staggered) başlar.
class _FadeSlideIn extends StatelessWidget {
  const _FadeSlideIn({required this.child, this.delayFraction = 0});

  final Widget child;
  final double delayFraction;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppDurations.slow,
      curve: Interval(delayFraction, 1, curve: Curves.easeOutCubic),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * AppSpacing.md),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Aktif sayfası genişleyen nokta göstergesi.
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: AppDurations.medium,
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            width: i == current ? AppSpacing.lg : AppSpacing.sm,
            height: AppSpacing.sm,
            decoration: BoxDecoration(
              color: i == current
                  ? scheme.primary
                  : scheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
      ],
    );
  }
}

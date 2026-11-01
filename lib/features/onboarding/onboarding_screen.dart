// 4 sayfalık onboarding: değer önerisi, gizlilik, haftalık ücretsiz kota ve
// izin isteme. İzin verilince bayrak işaretlenir, router Kütüphane'ye alır;
// reddedilirse aynı sayfada "Ayarları Aç" / "Şimdilik geç" çıkar.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/motion_constants.dart';
import '../../core/constants/ui_constants.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/services/photo_permission_service.dart';
import '../../core/services/preferences_service.dart';
import '../../core/utils/motion_physics.dart';
import 'widgets/access_illustration.dart';
import 'widgets/onboarding_page.dart';
import 'widgets/page_dots.dart';
import 'widgets/privacy_illustration.dart';
import 'widgets/quota_illustration.dart';
import 'widgets/sort_illustration.dart';

/// İlk açılış akışı; tamamlanınca bir daha gösterilmez.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const int _pageCount = 4;
  static const int _accessPage = _pageCount - 1;

  /// "Devam" ile sayfa geçişi: sekmesiz yay; kullanıcı sürüklerse kesilir.
  static final Curve _pageCurve = SpringCurve(
    AppSprings.standard,
    AppDurations.slow,
  );

  final PageController _pageController = PageController();
  late final AppLifecycleListener _lifecycle;
  int _currentPage = 0;
  bool _requesting = false;

  /// İzin reddedildi: erişim sayfası Ayarlar'a yönlendiren hale geçer.
  bool _denied = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _recheckAccess);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bool deniedHere = _denied && _currentPage == _accessPage;
    final List<Widget> pages = _pages(l10n);
    assert(pages.length == _pageCount, 'Sayfa sayısı _pageCount ile eşleşmeli');
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: pages,
              ),
            ),
            OnboardingPageDots(controller: _pageController, count: _pageCount),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: deniedHere
                  ? _deniedActions(l10n)
                  // Son sayfada da "Devam": izin öncesi ekranda "İzin ver"
                  // gibi bir etiket App Store 5.1.1(iv) reddi getirdi.
                  : FilledButton(
                      onPressed: _requesting ? null : _next,
                      child: Text(l10n.onboardingContinue),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _pages(AppLocalizations l10n) => [
    OnboardingPage(
      illustration: const SortIllustration(),
      title: l10n.onboardingTitle1,
      body: l10n.onboardingBody1,
    ),
    OnboardingPage(
      illustration: const PrivacyIllustration(),
      title: l10n.onboardingTitle2,
      body: l10n.onboardingBody2,
    ),
    OnboardingPage(
      illustration: const QuotaIllustration(),
      title: l10n.onboardingTitleQuota(FreeLimits.aiAnalysis),
      body: l10n.onboardingBodyQuota(FreeLimits.aiAnalysis),
    ),
    OnboardingPage(
      illustration: const AccessIllustration(),
      title: _denied ? l10n.permissionDeniedTitle : l10n.onboardingTitle3,
      body: _denied ? l10n.permissionDeniedBody : l10n.onboardingBody3,
      note: _denied ? null : l10n.onboardingLimitedNote,
    ),
  ];

  Widget _deniedActions(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: PhotoPermissionService.openSystemSettings,
          child: Text(l10n.openSettings),
        ),
        CupertinoButton(
          onPressed: _complete,
          child: Text(l10n.onboardingSkipForNow),
        ),
      ],
    );
  }

  Future<void> _next() async {
    if (_currentPage < _accessPage) {
      final int target = _currentPage + 1;
      if (context.reduceMotion) {
        _pageController.jumpToPage(target);
        return;
      }
      await _pageController.animateToPage(
        target,
        duration: AppDurations.slow,
        curve: _pageCurve,
      );
      return;
    }
    await _requestPermission();
  }

  Future<void> _requestPermission() async {
    setState(() => _requesting = true);
    try {
      final PhotoPermissionResult result =
          await PhotoPermissionService.request();
      if (!mounted) return;
      if (result == PhotoPermissionResult.granted) {
        await _complete();
      } else {
        setState(() => _denied = true);
      }
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  /// Bayrak işaretlenince router redirect'i Kütüphane'ye yönlendirir. "Şimdilik
  /// geç" de buraya gelir: Kütüphane izin eksikliğini kendi ekranında anlatır.
  Future<void> _complete() =>
      ref.read(onboardingCompleteProvider.notifier).markComplete();

  /// Ayarlar'dan dönüşte: izin verildiyse kullanıcı beklemeden devam eder.
  Future<void> _recheckAccess() async {
    if (!_denied) return;
    final PhotoAccess access = await PhotoPermissionService.currentAccess();
    if (!mounted || access == PhotoAccess.denied) return;
    await _complete();
  }
}

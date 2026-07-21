// go_router tanımı: onboarding kapısı + 3 sekmeli ana kabuk + tam ekran rotalar.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../features/analysis/milestone_screen.dart';
import '../../features/detail/detail_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/recents_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/paywall/paywall_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/sorting/sorting_screen.dart';
import '../constants/ui_constants.dart';
import '../l10n/l10n_extension.dart';
import '../services/preferences_service.dart';
import '../widgets/glass_action_button.dart';
import '../widgets/glass_nav_bar.dart';

/// Rota yolları — string tekrarını önlemek için tek yerde.
abstract final class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String gallery = '/gallery';
  static const String settings = '/settings';
  static const String search = '/search';
  static const String sorting = '/sorting';
  static const String recents = '/recents';
  static const String paywall = '/paywall';
  static const String analysisMilestone = '/analysis-milestone';

  /// Paywall query parametresi: açılışta paket bölümüne kaydır.
  static const String paywallFocusQuery = 'focus';
  static const String paywallFocusPacks = 'packs';

  /// Analiz limiti akışları için: paywall'ı paket bölümünde açar.
  static const String paywallPacks =
      '$paywall?$paywallFocusQuery=$paywallFocusPacks';

  /// Detay rotası assetId parametresi alır. iOS asset ID'leri slash içerir
  /// (`UUID/L0/001`) — encode edilmezse rota fazladan segmentlere bölünüp
  /// eşleşmez; go_router parametreyi okurken kendisi decode eder.
  static String detail(String assetId) =>
      '/detail/${Uri.encodeComponent(assetId)}';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // Onboarding bayrağını izle: tamamlanınca redirect otomatik güncellenir.
  final bool onboardingComplete = ref.watch(onboardingCompleteProvider);

  return GoRouter(
    initialLocation: AppRoutes.gallery,
    redirect: (context, state) {
      final bool onOnboarding = state.matchedLocation == AppRoutes.onboarding;
      if (!onboardingComplete && !onOnboarding) return AppRoutes.onboarding;
      if (onboardingComplete && onOnboarding) return AppRoutes.gallery;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      // Ana kabuk: alt sekme çubuğu, her sekme kendi navigation stack'inde.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.gallery,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.sorting,
                builder: (context, state) => const SortingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/detail/:assetId',
        builder: (context, state) =>
            DetailScreen(assetId: state.pathParameters['assetId']!),
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.recents,
        builder: (context, state) => const RecentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.analysisMilestone,
        // Kutlama sayfası da paywall gibi alttan tam sayfa modal.
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: MilestoneScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.paywall,
        // Paywall alttan tam sayfa modal olarak açılır (iOS alışkanlığı).
        pageBuilder: (context, state) => MaterialPage(
          fullscreenDialog: true,
          child: PaywallScreen(
            scrollToPacks:
                state.uri.queryParameters[AppRoutes.paywallFocusQuery] ==
                AppRoutes.paywallFocusPacks,
          ),
        ),
      ),
    ],
  );
});

/// Alt sekme çubuğunu barındıran ana kabuk: yüzen pil (3 sekme) + sağında
/// ayrık dairesel Arama butonu, iOS 26 tarzı gezinme deseni.
class _MainShell extends StatelessWidget {
  const _MainShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      // İçerik camın arkasından aksın diye gövde navbar'ın altına uzatılır.
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: Padding(
        // Home indicator varsa onun üstünde, yoksa kenardan sabit boşlukla yüzer.
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          bottomInset > 0 ? bottomInset : AppSpacing.md,
        ),
        // Pil ve ayrık aksiyon butonu tek bir LiquidGlassLayer + BlendGroup
        // içinde: aynı ışık/renk ayarlarını paylaşırlar ve birbirine
        // yaklaşınca gerçek iOS 26 liquid glass gibi kaynaşabilirler.
        child: LiquidGlassLayer(
          settings: LiquidGlassSettings(
            thickness: AppGlass.thickness,
            blur: AppGlass.blur,
            // `surfaceBright`: açık temada neredeyse beyaz, koyu temada da
            // en parlak yüzey tonu — gerçek Liquid Glass'ın nötr, parlak
            // dolgusuna en yakın tema-uyumlu renk (düz `surface` mat kalıyordu).
            glassColor: scheme.surfaceBright.withValues(
              alpha: AppGlass.tintAlpha,
            ),
            lightIntensity: AppGlass.lightIntensity,
            refractiveIndex: AppGlass.refractiveIndex,
            saturation: AppGlass.saturation,
            ambientStrength: AppGlass.ambientStrength,
          ),
          child: LiquidGlassBlendGroup(
            blend: AppGlass.blend,
            child: Row(
              children: [
                Expanded(
                  child: GlassNavBar(
                    selectedIndex: navigationShell.currentIndex,
                    onSelected: (index) => navigationShell.goBranch(
                      index,
                      // Aynı sekmeye tekrar basınca kök ekrana döner (iOS davranışı).
                      initialLocation: index == navigationShell.currentIndex,
                    ),
                    destinations: [
                      GlassNavDestination(
                        icon: Icons.home_outlined,
                        selectedIcon: Icons.home_rounded,
                        label: context.l10n.tabHome,
                      ),
                      GlassNavDestination(
                        icon: Icons.swipe_outlined,
                        selectedIcon: Icons.swipe,
                        label: context.l10n.tabSort,
                      ),
                      GlassNavDestination(
                        icon: Icons.settings_outlined,
                        selectedIcon: Icons.settings_rounded,
                        label: context.l10n.tabSettings,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                GlassActionButton(
                  icon: Icons.search,
                  tooltip: context.l10n.searchTitle,
                  onPressed: () => context.push(AppRoutes.search),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

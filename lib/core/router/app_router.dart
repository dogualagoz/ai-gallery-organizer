// go_router tanımı: onboarding kapısı + 3 sekmeli ana kabuk + tam ekran rotalar.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/boards/boards_screen.dart';
import '../../features/detail/detail_screen.dart';
import '../../features/gallery/gallery_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/paywall/paywall_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/sorting/sorting_screen.dart';
import '../l10n/l10n_extension.dart';
import '../services/preferences_service.dart';

/// Rota yolları — string tekrarını önlemek için tek yerde.
abstract final class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String gallery = '/gallery';
  static const String boards = '/boards';
  static const String settings = '/settings';
  static const String search = '/search';
  static const String sorting = '/sorting';
  static const String paywall = '/paywall';

  /// Detay rotası assetId parametresi alır.
  static String detail(String assetId) => '/detail/$assetId';
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
                builder: (context, state) => const GalleryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.boards,
                builder: (context, state) => const BoardsScreen(),
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
        path: AppRoutes.sorting,
        builder: (context, state) => const SortingScreen(),
      ),
      GoRoute(
        path: AppRoutes.paywall,
        // Paywall alttan tam sayfa modal olarak açılır (iOS alışkanlığı).
        pageBuilder: (context, state) =>
            const MaterialPage(fullscreenDialog: true, child: PaywallScreen()),
      ),
    ],
  );
});

/// Alt sekme çubuğunu barındıran ana kabuk.
class _MainShell extends StatelessWidget {
  const _MainShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Aynı sekmeye tekrar basınca kök ekrana döner (iOS davranışı).
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.grid_view_outlined),
            selectedIcon: const Icon(Icons.grid_view_rounded),
            label: context.l10n.tabGallery,
          ),
          NavigationDestination(
            icon: const Icon(Icons.folder_outlined),
            selectedIcon: const Icon(Icons.folder_rounded),
            label: context.l10n.tabBoards,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: context.l10n.tabSettings,
          ),
        ],
      ),
    );
  }
}

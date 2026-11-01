// go_router tanımı: onboarding kapısı + Kütüphane/Temizle/Ara sekmeli kabuk +
// kök navigator'daki tam ekran görüntüleyici ve sheet rotaları.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/analysis/milestone_screen.dart';
import '../../features/boards/board_detail_screen.dart';
import '../../features/detail/detail_screen.dart';
import '../../features/detail/open_viewer.dart';
import '../../features/detail/viewer_page.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/recents_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/paywall/paywall_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/sorting/providers/clean_session_provider.dart';
import '../../features/sorting/sorting_screen.dart';
import '../constants/app_icons.dart';
import '../constants/ui_constants.dart';
import '../l10n/l10n_extension.dart';
import '../models/screenshot_category.dart';
import '../services/preferences_service.dart';
import '../widgets/app_sheet.dart';
import '../widgets/glass_action_button.dart';
import '../widgets/glass_nav_bar.dart';
import '../widgets/spring_visibility.dart';
import 'tab_bar_visibility.dart';

/// Ana kabuğun sekmeleri. Sıra, [StatefulShellRoute] dal sırasıyla aynıdır.
enum AppTab { library, clean, search }

/// Rota yolları — string tekrarını önlemek için tek yerde.
abstract final class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String library = '/library';
  static const String clean = '/clean';
  static const String search = '/search';
  static const String settings = '/settings';
  static const String paywall = '/paywall';
  static const String analysisMilestone = '/analysis-milestone';
  static const String detailBase = '/detail';

  /// Kütüphane dalının alt rota parçaları; bu ekranlarda sekme çubuğu kalır.
  static const String recentsSegment = 'recents';
  static const String categorySegment = 'category';
  static const String boardSegment = 'board';

  static const String recents = '$library/$recentsSegment';

  /// Pano/kategori detayını doğrudan seçim modunda açan query parametresi.
  static const String selectQuery = 'select';
  static const String selectQueryOn = '1';

  /// Paywall query parametresi: açılışta paket bölümüne kaydır.
  static const String paywallFocusQuery = 'focus';
  static const String paywallFocusPacks = 'packs';

  /// Analiz limiti akışları için: paywall'ı paket bölümünde açar.
  static const String paywallPacks =
      '$paywall?$paywallFocusQuery=$paywallFocusPacks';

  /// Sistem kategorisi panosu (enum index'i ile adreslenir).
  static String category(ScreenshotCategory category, {bool select = false}) =>
      _selectable('$library/$categorySegment/${category.index}', select);

  /// Kullanıcı panosu. Kimlik, slash içerse de tek segment kalsın diye encode
  /// edilir.
  static String board(String boardId, {bool select = false}) => _selectable(
    '$library/$boardSegment/${Uri.encodeComponent(boardId)}',
    select,
  );

  /// Detay rotası assetId parametresi alır. iOS asset ID'leri slash içerir
  /// (`UUID/L0/001`) — encode edilmezse rota fazladan segmentlere bölünüp
  /// eşleşmez; go_router parametreyi okurken kendisi decode eder.
  static String detail(String assetId) =>
      '$detailBase/${Uri.encodeComponent(assetId)}';

  static String _selectable(String path, bool select) =>
      select ? '$path?$selectQuery=$selectQueryOn' : path;
}

const String _assetIdParam = 'assetId';
const String _categoryParam = 'index';
const String _boardIdParam = 'boardId';

/// Rota adresindeki kategori index'ini çözer; geçersizse null.
ScreenshotCategory? _categoryOf(GoRouterState state) {
  final int? index = int.tryParse(state.pathParameters[_categoryParam] ?? '');
  return index == null
      ? null
      : ScreenshotCategory.values.elementAtOrNull(index);
}

bool _startsInSelection(GoRouterState state) =>
    state.uri.queryParameters[AppRoutes.selectQuery] == AppRoutes.selectQueryOn;

final appRouterProvider = Provider<GoRouter>((ref) {
  // Onboarding bayrağını izle: tamamlanınca redirect otomatik güncellenir.
  final bool onboardingComplete = ref.watch(onboardingCompleteProvider);

  return GoRouter(
    initialLocation: AppRoutes.library,
    redirect: (context, state) {
      final bool onOnboarding = state.matchedLocation == AppRoutes.onboarding;
      if (!onboardingComplete && !onOnboarding) return AppRoutes.onboarding;
      if (onboardingComplete && onOnboarding) return AppRoutes.library;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      // Ana kabuk: yüzen sekme çubuğu, her sekme kendi navigation stack'inde.
      StatefulShellRoute(
        builder: (context, state, navigationShell) =>
            _MainShell(navigationShell: navigationShell),
        navigatorContainerBuilder: (context, navigationShell, children) =>
            _BranchStack(
              currentIndex: navigationShell.currentIndex,
              children: children,
            ),
        branches: [
          StatefulShellBranch(routes: [_libraryRoute()]),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.clean,
                builder: (context, state) => const SortingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
        ],
      ),
      // Görüntüleyici kök navigator'da: sekme çubuğunu örter (Fotoğraflar gibi).
      GoRoute(
        path: '${AppRoutes.detailBase}/:$_assetIdParam',
        pageBuilder: (context, state) => ViewerPage<void>(
          key: state.pageKey,
          child: DetailScreen(
            assetId: state.pathParameters[_assetIdParam]!,
            scope: switch (state.extra) {
              ViewerScope(:final assetIds) => assetIds,
              _ => null,
            },
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) => CupertinoSheetPage<void>(
          key: state.pageKey,
          builder: (context, controller) =>
              SettingsScreen(scrollController: controller),
        ),
      ),
      GoRoute(
        path: AppRoutes.analysisMilestone,
        pageBuilder: (context, state) => CupertinoSheetPage<void>(
          key: state.pageKey,
          builder: (context, _) => const MilestoneScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.paywall,
        pageBuilder: (context, state) => CupertinoSheetPage<void>(
          key: state.pageKey,
          builder: (context, controller) => PaywallScreen(
            scrollController: controller,
            scrollToPacks:
                state.uri.queryParameters[AppRoutes.paywallFocusQuery] ==
                AppRoutes.paywallFocusPacks,
          ),
        ),
      ),
    ],
  );
});

/// Kütüphane sekmesi ve sekme çubuğu görünürken açılan alt ekranları.
GoRoute _libraryRoute() {
  return GoRoute(
    path: AppRoutes.library,
    builder: (context, state) => const HomeScreen(),
    routes: [
      GoRoute(
        path: AppRoutes.recentsSegment,
        builder: (context, state) => const RecentsScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.categorySegment}/:$_categoryParam',
        redirect: (context, state) =>
            _categoryOf(state) == null ? AppRoutes.library : null,
        builder: (context, state) => BoardDetailScreen.category(
          category: _categoryOf(state)!,
          startInSelection: _startsInSelection(state),
        ),
      ),
      GoRoute(
        path: '${AppRoutes.boardSegment}/:$_boardIdParam',
        builder: (context, state) => BoardDetailScreen.custom(
          boardId: state.pathParameters[_boardIdParam]!,
          startInSelection: _startsInSelection(state),
        ),
      ),
    ],
  );
}

/// Sekme çubuğunu barındıran ana kabuk: 2 sekmeli yüzen cam pil + sağında
/// ayrık dairesel Ara sekmesi (iOS 26 tab bar + arama sekmesi deseni).
class _MainShell extends StatelessWidget {
  const _MainShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Pil ve Ara dairesinin cam bulanıklığını paylaştığı sabit anahtar.
  static final BackdropKey _backdropKey = BackdropKey();

  void _goTab(int index) => navigationShell.goBranch(
    index,
    // Aynı sekmeye tekrar basınca kök ekrana döner (iOS davranışı).
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // İçerik camın arkasından aksın diye gövde navbar'ın altına uzatılır.
      extendBody: true,
      body: navigationShell,
      // Seçim modu gibi ekranlar çubuğu kendi araç çubuğuyla yer değiştirir;
      // yerleşim korunur ki gövdenin alt boşluğu değişmesin.
      bottomNavigationBar: Consumer(
        builder: (context, ref, bar) => SpringVisibility(
          visible: !ref.watch(tabBarHiddenProvider),
          child: bar!,
        ),
        child: _tabBar(context),
      ),
    );
  }

  Widget _tabBar(BuildContext context) {
    final l10n = context.l10n;
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    final int current = navigationShell.currentIndex;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: AppSizes.navBarMaxTextScale,
      child: BackdropGroup(
        backdropKey: _backdropKey,
        child: Padding(
          // Home indicator varsa onun üstünde, yoksa kenardan sabit boşlukla.
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSizes.navBarTopGap,
            AppSpacing.lg,
            AppSizes.navBarBottomGap(bottomInset),
          ),
          child: Row(
            children: [
              Expanded(
                // Temizle rozeti: sekmeden çıkınca da bekleyen silmeler
                // unutulmasın (onay sürpriz diyalogla değil, buradan hatırlanır).
                child: Consumer(
                  builder: (context, ref, _) {
                    final int pending = ref
                        .watch(pendingDeleteIdsProvider)
                        .length;
                    return GlassNavBar(
                      selectedIndex: current,
                      onSelected: _goTab,
                      destinations: [
                        GlassNavDestination(
                          icon: AppIcons.library,
                          selectedIcon: AppIcons.libraryFill,
                          label: l10n.tabLibrary,
                        ),
                        GlassNavDestination(
                          icon: AppIcons.clean,
                          selectedIcon: AppIcons.cleanFill,
                          label: l10n.tabClean,
                          badgeCount: pending,
                          badgeLabel: l10n.sortingPendingDeleteCount(pending),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GlassActionButton(
                icon: AppIcons.search,
                label: l10n.searchTitle,
                selected: current == AppTab.search.index,
                onPressed: () => _goTab(AppTab.search.index),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sekme dallarının kabı: etkin olmayan dallar ekran dışı, ticker'sız ve
/// Hero'suz tutulur. Hero kapatılmazsa iki dalda aynı ekran görüntüsü varken
/// (ör. Kütüphane ve Ara) kök rotaya geçişte etiketler çakışır.
class _BranchStack extends StatelessWidget {
  const _BranchStack({required this.currentIndex, required this.children});

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: currentIndex,
      children: [
        for (int i = 0; i < children.length; i++)
          Offstage(
            offstage: i != currentIndex,
            child: TickerMode(
              enabled: i == currentIndex,
              child: HeroMode(enabled: i == currentIndex, child: children[i]),
            ),
          ),
      ],
    );
  }
}

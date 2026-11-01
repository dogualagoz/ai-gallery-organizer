// Kütüphane sekmesi: büyük başlık + analiz durum modülü + kategoriler,
// panolar ve son eklenenler. Aşağı çekince kütüphane eşitlenir; izin yoksa
// ya da kütüphane okunamazsa durum boş galeriden ayrı anlatılır.
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/ui_constants.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/screenshot_entry.dart';
import '../../core/router/app_router.dart';
import '../../core/services/entitlement_service.dart';
import '../../core/services/photo_permission_service.dart';
import '../../core/services/review_service.dart';
import '../../core/widgets/app_nav_scaffold.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/pro_badge.dart';
import '../../core/widgets/status_toast.dart';
import '../analysis/providers/analysis_summary_provider.dart';
import '../analysis/providers/auto_sort_provider.dart';
import '../analysis/widgets/analysis_flights.dart';
import '../analysis/widgets/analysis_status_module.dart';
import '../analysis/widgets/auto_sort_hint.dart';
import '../boards/providers/board_provider.dart';
import '../gallery/providers/gallery_provider.dart';
import 'widgets/library_sections.dart';

/// Uygulama açılış sayacının bu oturumda bir kez işlendiğini işaretler.
bool _appOpenCounted = false;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// Ayarlar'dan dönüşte fotoğraf izni yeniden okunur (verildi/kaldırıldı).
  late final AppLifecycleListener _lifecycle;

  bool _tabActive = true;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.read(photoAccessProvider.notifier).recheck(),
    );
    if (!_appOpenCounted) {
      _appOpenCounted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(reviewServiceProvider).registerAppOpen();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sekme değişince (ya da üstüne sayfa açılınca) dal arka plana geçer ve
    // ticker'ları kapanır: düzenleme modu da kapanır. Build sırasında
    // provider değiştirilemediği için bir sonraki mikro görevde yapılır.
    final bool active = TickerMode.valuesOf(context).enabled;
    if (_tabActive && !active) {
      Future.microtask(() {
        if (mounted) ref.read(boardsEditModeProvider.notifier).disable();
      });
    }
    _tabActive = active;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// Eşitlemeyi çalıştırır; hata olursa kullanıcıya durum bildirimi gösterir.
  Future<void> _sync() async {
    final String failure = context.l10n.gallerySyncFailed;
    try {
      await ref.read(galleryProvider.notifier).sync();
    } catch (error, stackTrace) {
      debugPrint('Galeri manuel eşitleme hatası: $error\n$stackTrace');
      if (!mounted) return;
      showStatusToast(context, failure, tone: StatusToastTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ekran boyunca yaşatılır: galeri güncellendikçe Pro kullanıcı için
    // analiz kuyruğunu otomatik tetikler.
    ref.watch(autoSortControllerProvider);
    // Tur özeti dinleyicisi modül ekrandan kaysa da yaşasın diye kabukta
    // tutulur (yeniden kurulum tetiklemez).
    ref.listen(analysisSummaryProvider, (_, _) {});
    final l10n = context.l10n;
    final bool isPro = ref.watch(
      entitlementProvider.select((state) => state.isPro),
    );
    final AsyncValue<List<ScreenshotEntry>> gallery = ref.watch(
      galleryProvider,
    );

    return AnalysisFlightScope(
      child: AppNavScaffold(
        title: l10n.tabLibrary,
        titleTrailing: isPro ? const ProBadge() : null,
        trailing: NavBarButton.icon(
          icon: AppIcons.settings,
          label: l10n.settingsTitle,
          onPressed: () => context.push(AppRoutes.settings),
        ),
        onRefresh: _sync,
        slivers: _slivers(gallery),
      ),
    );
  }

  /// Galeri durumuna göre gövde: yükleniyor, izin yok, okunamadı, boş ya da
  /// Kütüphane içeriği.
  List<Widget> _slivers(AsyncValue<List<ScreenshotEntry>> gallery) {
    final l10n = context.l10n;
    return gallery.when(
      // İzin değişimiyle yeniden eşitlenirken içerik yerinde kalır.
      skipLoadingOnReload: true,
      loading: () => const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CupertinoActivityIndicator()),
        ),
      ],
      error: (error, _) => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: error is PhotoAccessDeniedException
              ? const PermissionDeniedView()
              : EmptyStateView(
                  icon: AppIcons.error,
                  title: l10n.galleryLoadFailedTitle,
                  message: l10n.galleryLoadFailedBody,
                  actionLabel: l10n.retryAction,
                  onAction: () => ref.invalidate(galleryProvider),
                ),
        ),
      ],
      data: (entries) => entries.isEmpty
          ? [
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateView(
                  icon: AppIcons.photo,
                  title: l10n.galleryEmptyTitle,
                  message: l10n.galleryEmptyBody,
                  actionLabel: l10n.gallerySyncAction,
                  onAction: _sync,
                ),
              ),
            ]
          : _contentSlivers(entries),
    );
  }

  List<Widget> _contentSlivers(List<ScreenshotEntry> entries) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          0,
        ),
        sliver: SliverList.list(
          children: [
            AnalysisStatusModule(entries: entries),
            const AutoSortHint(),
            const LimitedAccessBanner(),
            LibraryCategoriesSection(entries: entries),
            const SizedBox(height: AppSpacing.lg),
            LibraryBoardsSection(entries: entries),
            const SizedBox(height: AppSpacing.lg),
            LibraryRecentsHeader(
              hasMore: entries.length > kLibraryRecentsLimit,
            ),
          ],
        ),
      ),
      LibraryRecentsGrid(entries: entries),
    ];
  }
}

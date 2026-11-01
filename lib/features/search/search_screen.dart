// Ara sekmesi: başlığa gömülü iOS arama alanı. Boş sorguda son aramalar ve
// sık etiketler, yazınca etiket + OCR + kategori üzerinde canlı sonuçlar;
// kategori çipleri aramayı daraltır (Pro).
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/ui_constants.dart';
import '../../core/l10n/category_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/screenshot_category.dart';
import '../../core/models/screenshot_entry.dart';
import '../../core/services/category_names_service.dart';
import '../../core/services/entitlement_service.dart';
import '../../core/services/photo_permission_service.dart';
import '../../core/services/recent_searches_service.dart';
import '../../core/widgets/app_nav_scaffold.dart';
import '../../core/widgets/empty_state_view.dart';
import '../gallery/providers/gallery_provider.dart';
import '../gallery/widgets/screenshot_grid.dart';
import '../paywall/open_paywall.dart';
import 'search_index.dart';
import 'search_request_provider.dart';
import 'widgets/search_category_bar.dart';
import 'widgets/search_suggestions.dart';

/// Ara sekmesinin kökü; free kullanıcıya kilit ve paywall CTA'sı gösterir.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  /// Seçili kategori filtresi (null = tümü).
  ScreenshotCategory? _category;

  /// Arama alanı etkin: başlık küçülmüş, "İptal" görünür. Alan etkin
  /// tarafta yeniden kurulduğu için klavye `autofocus` ile açılır.
  bool _active = false;

  @override
  void initState() {
    super.initState();
    // Sekme ilk kez bir istekle açılıyorsa (etikete dokunma) alan dolu gelir.
    final SearchRequest? request = ref.read(searchRequestProvider);
    if (request != null) {
      _controller.text = request.query;
      _query = request.query;
      // Kurulum sırasında provider değiştirilemez: kayıt sonraki mikro görevde.
      final RecentSearchesNotifier recents = ref.read(
        recentSearchesProvider.notifier,
      );
      scheduleMicrotask(() => recents.add(request.query));
      _consumeRequest();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyRequest(SearchRequest? request) {
    if (request == null) return;
    // Etiket kendi kategorisinde olmayabilir: eski filtre sessizce kalmasın.
    _category = null;
    _setQuery(request.query, remember: true);
    _consumeRequest();
  }

  /// Provider kurulum/dinleme sırasında değiştirilemez; temizlik bir sonraki
  /// mikro göreve bırakılır.
  void _consumeRequest() {
    final SearchRequestNotifier notifier = ref.read(
      searchRequestProvider.notifier,
    );
    scheduleMicrotask(notifier.clear);
  }

  /// Sorguyu alana ve sonuçlara uygular (öneriye dokunma, etiket isteği).
  void _setQuery(String query, {bool remember = false}) {
    _controller.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    setState(() => _query = query);
    if (remember) _remember();
  }

  /// Anlamlı arama anı (gönderme, sonuç açma, öneri ya da görüntüleyicide
  /// etiket seçme) geçmişe yazılır; yazarken her harf kaydedilmez.
  void _remember() => ref.read(recentSearchesProvider.notifier).add(_query);

  void _onActiveChanged(bool active) {
    setState(() {
      _active = active;
      if (active) return;
      // "İptal" aramayı baştan alır (iOS davranışı).
      _controller.clear();
      _query = '';
      _category = null;
    });
  }

  void _toggleCategory(ScreenshotCategory category) =>
      setState(() => _category = _category == category ? null : category);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bool canSearch = ref.watch(
      entitlementProvider.select((state) => state.canSearch),
    );
    ref.listen(searchRequestProvider, (_, request) => _applyRequest(request));

    if (!canSearch) {
      return AppNavScaffold(
        title: l10n.searchTitle,
        slivers: [
          _fill(
            EmptyStateView(
              icon: AppIcons.search,
              title: l10n.searchLockedTitle,
              message: l10n.searchLockedBody,
              actionLabel: l10n.paywallTitle,
              onAction: () => openPaywall(context),
            ),
          ),
        ],
      );
    }
    return AppNavScaffold(
      title: l10n.searchTitle,
      searchField: CupertinoSearchTextField(
        controller: _controller,
        autofocus: _active,
        placeholder: l10n.searchHint,
        onChanged: (value) => setState(() => _query = value),
        onSubmitted: (_) => _remember(),
      ),
      onSearchActiveChanged: _onActiveChanged,
      slivers: _body(),
    );
  }

  /// Galeri durumu → içerik sliver'ları.
  List<Widget> _body() {
    final l10n = context.l10n;
    final AsyncValue<List<ScreenshotEntry>> gallery = ref.watch(
      galleryProvider,
    );
    return gallery.when(
      skipLoadingOnReload: true,
      loading: () => [_fill(const Center(child: CupertinoActivityIndicator()))],
      error: (error, _) => [
        _fill(
          error is PhotoAccessDeniedException
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
      data: (_) => _searchSlivers(),
    );
  }

  List<Widget> _searchSlivers() {
    final l10n = context.l10n;
    final SearchIndex index = ref.watch(searchIndexProvider);
    if (index.isEmpty) {
      return [
        _fill(
          EmptyStateView(
            icon: AppIcons.search,
            title: l10n.searchNothingTitle,
            message: l10n.searchNothingBody,
          ),
        ),
      ];
    }
    final bool browsing = _query.trim().isEmpty && _category == null;
    return [
      SliverToBoxAdapter(
        child: SearchCategoryBar(
          categories: index.categories,
          selected: _category,
          onSelected: _toggleCategory,
        ),
      ),
      ...browsing ? _suggestions(index) : _results(index),
    ];
  }

  List<Widget> _suggestions(SearchIndex index) {
    final l10n = context.l10n;
    final List<String> recents = ref.watch(recentSearchesProvider);
    final List<String> tags = index.topTags(SearchLimits.suggestedTags);
    if (recents.isEmpty && tags.isEmpty) {
      return [
        _fill(
          EmptyStateView(
            icon: AppIcons.search,
            title: l10n.searchPromptTitle,
            message: l10n.searchPrompt,
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        sliver: SliverList.list(
          children: [
            if (recents.isNotEmpty)
              SearchRecents(
                recents: recents,
                onSelect: (query) => _setQuery(query, remember: true),
                onClear: ref.read(recentSearchesProvider.notifier).clear,
              ),
            if (tags.isNotEmpty)
              SearchTagSuggestions(
                tags: tags,
                onSelect: (tag) => _setQuery(tag, remember: true),
              ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _results(SearchIndex index) {
    final l10n = context.l10n;
    final Map<int, String> names = ref.watch(categoryNamesProvider);
    final List<ScreenshotEntry> results = index.search(
      _query,
      category: _category,
      nameOf: (category) => category.displayName(l10n, names),
    );
    if (results.isEmpty) {
      final String query = _query.trim();
      return [
        _fill(
          EmptyStateView(
            icon: AppIcons.search,
            title: l10n.searchEmpty,
            message: query.isEmpty ? null : l10n.searchEmptyBody(query),
            actionLabel: _category == null ? null : l10n.searchAllCategories,
            onAction: () => setState(() => _category = null),
          ),
        ),
      ];
    }
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Text(
            l10n.searchResultCount(results.length),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ),
      ScreenshotGrid(entries: results, onOpen: _remember),
    ];
  }

  /// Kalan alanı dolduran ortalanmış içerik (boş/yükleniyor durumları).
  Widget _fill(Widget child) =>
      SliverFillRemaining(hasScrollBody: false, child: child);
}

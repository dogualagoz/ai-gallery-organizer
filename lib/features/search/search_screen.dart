// Arama ekranı: tag + OCR + kategori üzerinde bellek içi arama (Pro).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/ui_constants.dart';
import '../../core/l10n/category_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/screenshot_entry.dart';
import '../../core/router/app_router.dart';
import '../../core/services/category_names_service.dart';
import '../../core/services/entitlement_service.dart';
import '../../core/utils/text_normalize.dart';
import '../../core/widgets/screenshot_results_grid.dart';
import '../gallery/providers/gallery_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bool canSearch = ref.watch(entitlementProvider).canSearch;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.searchTitle)),
      body: canSearch ? _buildSearch(context) : const _LockedSearch(),
    );
  }

  Widget _buildSearch(BuildContext context) {
    final l10n = context.l10n;
    final List<ScreenshotEntry> entries =
        ref.watch(galleryProvider).value ?? const [];
    final String normalizedQuery = normalizeForSearch(_query);
    final Map<int, String> categoryNames = ref.watch(categoryNamesProvider);
    final List<ScreenshotEntry> results = normalizedQuery.isEmpty
        ? const []
        : entries
              .where((entry) => !entry.isPending)
              .where(
                (entry) =>
                    _matches(entry, normalizedQuery, l10n, categoryNames),
              )
              .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.searchHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        Expanded(
          child: normalizedQuery.isEmpty
              ? _SearchMessage(text: l10n.searchPrompt, icon: Icons.search)
              : results.isEmpty
              ? _SearchMessage(text: l10n.searchEmpty, icon: Icons.search_off)
              : ScreenshotResultsGrid(entries: results),
        ),
      ],
    );
  }

  bool _matches(
    ScreenshotEntry entry,
    String normalizedQuery,
    AppLocalizations l10n,
    Map<int, String> categoryNames,
  ) {
    final StringBuffer haystack = StringBuffer()
      ..write(entry.tags.join(' '))
      ..write(' ')
      ..write(entry.ocrText ?? '')
      ..write(' ')
      ..write(entry.category?.displayName(l10n, categoryNames) ?? '');
    return normalizeForSearch(haystack.toString()).contains(normalizedQuery);
  }
}

/// Sorgu boşken/sonuçsuzken gösterilen sade mesaj.
class _SearchMessage extends StatelessWidget {
  const _SearchMessage({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 40,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Free kullanıcıya gösterilen kilitli durum + paywall CTA'sı.
class _LockedSearch extends StatelessWidget {
  const _LockedSearch();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.workspace_premium_outlined,
                size: 40,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.searchLockedTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.searchLockedBody,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => context.push(AppRoutes.paywall),
              child: Text(l10n.paywallTitle),
            ),
          ],
        ),
      ),
    );
  }
}

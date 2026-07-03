// Arama ekranı — Blok 5'te tag + OCR araması ile doldurulacak.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n_extension.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO(blok5): Bellek içi tag/OCR araması (Pro).
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.searchTitle)),
      body: Center(child: Text(context.l10n.comingSoon)),
    );
  }
}

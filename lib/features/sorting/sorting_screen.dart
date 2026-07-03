// Swipe sıralama ekranı — Blok 6'da kart tabanlı akışla doldurulacak.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n_extension.dart';

class SortingScreen extends ConsumerWidget {
  const SortingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO(blok6): Sola sil / sağa board'a ata / yukarı atla swipe akışı.
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.sortingTitle)),
      body: Center(child: Text(context.l10n.comingSoon)),
    );
  }
}

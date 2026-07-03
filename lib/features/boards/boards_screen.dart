// Board (pano) listesi ekranı — Blok 5'te kategori/board görünümüyle doldurulacak.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n_extension.dart';

class BoardsScreen extends ConsumerWidget {
  const BoardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO(blok5): Sistem kategorileri + özel board'lar.
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.boardsTitle)),
      body: Center(child: Text(context.l10n.comingSoon)),
    );
  }
}

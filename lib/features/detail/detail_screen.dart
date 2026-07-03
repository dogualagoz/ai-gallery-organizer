// Screenshot detay ekranı — Blok 3/4'te görsel + etiket + OCR ile doldurulacak.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n_extension.dart';

class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.assetId});

  /// Gösterilecek screenshot'ın photo_manager asset kimliği.
  final String assetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO(blok3): Büyük görsel + etiketler + OCR metni + aksiyonlar.
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.detailTitle)),
      body: Center(child: Text(context.l10n.comingSoon)),
    );
  }
}

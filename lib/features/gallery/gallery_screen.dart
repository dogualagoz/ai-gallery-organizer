// Ana galeri ekranı — Blok 3'te screenshot grid'i ile doldurulacak.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n_extension.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO(blok3): photo_manager import + thumbnail grid.
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.galleryTitle)),
      body: Center(child: Text(context.l10n.comingSoon)),
    );
  }
}

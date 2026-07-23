// Karoyu sarar: uzun basınca anasayfa ızgaralarının düzenleme modunu açar
// (hafif titreşim geri bildirimiyle). Normal dokunma çocuğa iletilir.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/board_provider.dart';

class LongPressEditWrapper extends ConsumerWidget {
  const LongPressEditWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        ref.read(boardsEditModeProvider.notifier).enable();
      },
      child: child,
    );
  }
}

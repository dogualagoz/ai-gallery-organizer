// Sheet'lerin sağ üstündeki kapatma düğmesi (iOS sheet'lerindeki gri daire
// içinde xmark) ve onu içeriğin üstüne sabitleyen katman.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../constants/ui_constants.dart';
import '../l10n/l10n_extension.dart';

/// Küçük görünen ama 44pt dokunma alanlı kapatma dairesi. [onPressed]
/// verilmezse en yakın rotayı kapatır.
class SheetCloseButton extends StatelessWidget {
  const SheetCloseButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size.square(kMinInteractiveDimensionCupertino),
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      child: Container(
        width: AppSizes.sheetClose,
        height: AppSizes.sheetClose,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(
          AppIcons.close,
          size: AppSizes.sheetCloseGlyph,
          color: scheme.onSurfaceVariant,
          semanticLabel: context.l10n.dismissAction,
        ),
      ),
    );
  }
}

/// [child]'ın sağ üst köşesine [SheetCloseButton] yerleştirir. Düğme içerik
/// kaydıkça yerinde kalır ve yükleme/hata dahil her durumda erişilebilir.
class SheetWithCloseButton extends StatelessWidget {
  const SheetWithCloseButton({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        const SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xs),
              child: SheetCloseButton(),
            ),
          ),
        ),
      ],
    );
  }
}

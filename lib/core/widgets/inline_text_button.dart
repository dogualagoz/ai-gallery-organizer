// Satır içi metin butonu: dar yatay pay, 44pt dokunma alanı.
import 'package:flutter/cupertino.dart';

import '../constants/ui_constants.dart';

/// Kart, başlık ya da bant içindeki metin eylemi (ör. "Tümünü gör",
/// "Daha fazla seç"). Görünür pay küçük, dokunma alanı en az 44pt.
class InlineTextButton extends StatelessWidget {
  const InlineTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
  });

  final String label;
  final VoidCallback? onPressed;

  /// Verilmezse Cupertino buton metni (aksan renk).
  final TextStyle? style;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: padding,
      minimumSize: const Size.square(kMinInteractiveDimensionCupertino),
      onPressed: onPressed,
      child: Text(label, style: style),
    );
  }
}

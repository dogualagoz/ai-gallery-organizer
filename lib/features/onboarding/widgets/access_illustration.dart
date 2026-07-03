// Onboarding 3. sayfa illüstrasyonu: kategori ikonlu kutucukların
// sırayla belirdiği 3x3 ızgara — "kütüphanen düzene giriyor" hissi.
import 'package:flutter/material.dart';

import '../../../core/constants/ui_constants.dart';

class AccessIllustration extends StatefulWidget {
  const AccessIllustration({super.key});

  @override
  State<AccessIllustration> createState() => _AccessIllustrationState();
}

class _AccessIllustrationState extends State<AccessIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Kategori setini çağrıştıran ikonlar (sistem kategorileriyle uyumlu).
  static const List<IconData> _icons = [
    Icons.lock_outline,
    Icons.chat_bubble_outline,
    Icons.shopping_bag_outlined,
    Icons.sticky_note_2_outlined,
    Icons.receipt_long_outlined,
    Icons.photo_outlined,
    Icons.alternate_email,
    Icons.qr_code_2,
    Icons.confirmation_number_outlined,
  ];

  @override
  void initState() {
    super.initState();
    // Sayfa görünür olduğunda tek seferlik giriş animasyonu oynar.
    _controller = AnimationController(vsync: this, duration: AppDurations.scene)
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Center(
      child: SizedBox(
        width: 264,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (int i = 0; i < _icons.length; i++) _buildTile(i, scheme),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTile(int index, ColorScheme scheme) {
    // Kutucuklar soldan sağa, yukarıdan aşağıya sırayla belirir.
    final double t = CurvedAnimation(
      parent: _controller,
      curve: Interval(index * 0.08, 0.6 + index * 0.04, curve: Curves.easeOutBack),
    ).value;

    return Transform.scale(
      scale: 0.6 + 0.4 * t,
      child: Opacity(
        opacity: t.clamp(0, 1),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: scheme.outline),
          ),
          child: Icon(
            _icons[index],
            color: index % 3 == 1 ? scheme.primary : scheme.onSurfaceVariant,
            size: 30,
          ),
        ),
      ),
    );
  }
}

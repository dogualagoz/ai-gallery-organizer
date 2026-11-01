// Yalnız debug derlemede görünen Ayarlar bölümü: yetki ve kota durumunu
// sıfırlayıp paywall, limit ve analiz akışlarını gerçek istek atmadan dener.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/services/entitlement_service.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/widgets/grouped_section.dart';
import '../../analysis/providers/analysis_queue_provider.dart';

/// Yalnız debug derlemede görünür: paywall/limit akışlarını test etmek için
/// yetki durumunu sıfırlar. Release build'e hiç girmez (çağıran kDebugMode
/// guard'lı); metinler bu yüzden lokalize edilmez.
class DebugSection extends ConsumerWidget {
  const DebugSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GroupedSection(
      header: 'Debug',
      children: [
        GroupedRow(
          icon: AppIcons.pro,
          title: 'Enter Pro (debug)',
          onTap: () => ref.read(entitlementProvider.notifier).setPro(true),
        ),
        GroupedRow(
          icon: AppIcons.close,
          title: 'Exit Pro (debug)',
          onTap: () => ref.read(entitlementProvider.notifier).setPro(false),
        ),
        GroupedRow(
          icon: AppIcons.reanalyze,
          title: 'Reset analysis usage & credits (debug)',
          onTap: () =>
              ref.read(entitlementProvider.notifier).resetUsageForDebug(),
        ),
        // Kütüphane'deki analiz modülünü ve uçuşları gerçek istek atmadan
        // oynatır; sheet kapatılınca animasyon izlenir.
        GroupedRow(
          icon: AppIcons.analyze,
          title: 'Simulate analysis (debug)',
          onTap: () => ref.read(analysisQueueProvider.notifier).simulate(),
        ),
        GroupedRow(
          icon: AppIcons.undo,
          title: 'Show onboarding again (debug)',
          onTap: () =>
              ref.read(onboardingCompleteProvider.notifier).resetForDebug(),
        ),
      ],
    );
  }
}

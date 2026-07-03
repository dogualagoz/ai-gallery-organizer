// Onboarding ekranı — Blok 2'de animasyonlu 3 sayfalık akışla doldurulacak.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/ui_constants.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/services/preferences_service.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO(blok2): Animasyonlu 3 sayfalık onboarding + izin akışı.
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.l10n.appTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => ref
                    .read(onboardingCompleteProvider.notifier)
                    .markComplete(),
                child: Text(context.l10n.comingSoon),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

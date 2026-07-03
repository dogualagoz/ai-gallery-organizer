// Paywall ekranı — Blok 7'de plan kartları + IAP ile doldurulacak.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n_extension.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO(blok7): 3 plan kartı, trial CTA, restore, yasal linkler.
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.paywallTitle)),
      body: Center(child: Text(context.l10n.comingSoon)),
    );
  }
}

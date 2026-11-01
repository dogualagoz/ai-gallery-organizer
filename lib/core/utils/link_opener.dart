// Harici linkleri açan ortak yardımcı; başarısızlık sessiz yutulmaz.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n_extension.dart';
import '../widgets/status_toast.dart';

/// [url]'i sistem tarayıcısında açar; açılamazsa lokalize hata bildirimi gösterir.
Future<void> openExternalUrl(BuildContext context, String url) async {
  final String failureMessage = context.l10n.settingsLinkFailed;
  // Gösterici await öncesi alınır; böylece context'in ömrüne bağımlılık kalmaz.
  final StatusToaster toaster = StatusToaster.of(context);
  bool opened = false;
  try {
    opened = await launchUrl(Uri.parse(url));
  } catch (error, stackTrace) {
    debugPrint('Link açma hatası ($url): $error\n$stackTrace');
  }
  if (!opened) {
    toaster.show(failureMessage, tone: StatusToastTone.error);
  }
}

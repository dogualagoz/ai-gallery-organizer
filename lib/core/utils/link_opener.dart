// Harici linkleri açan ortak yardımcı; başarısızlık sessiz yutulmaz.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n_extension.dart';

/// [url]'i sistem tarayıcısında açar; açılamazsa lokalize hata snackbar'ı gösterir.
Future<void> openExternalUrl(BuildContext context, String url) async {
  final String failureMessage = context.l10n.settingsLinkFailed;
  // Messenger await öncesi alınır; böylece context'in ömrüne bağımlılık kalmaz.
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  bool opened = false;
  try {
    opened = await launchUrl(Uri.parse(url));
  } catch (error, stackTrace) {
    debugPrint('Link açma hatası ($url): $error\n$stackTrace');
  }
  if (!opened) {
    messenger.showSnackBar(SnackBar(content: Text(failureMessage)));
  }
}

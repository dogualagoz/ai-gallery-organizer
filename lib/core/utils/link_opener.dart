// Harici linkleri açan ortak yardımcı; başarısızlık sessiz yutulmaz.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n_extension.dart';
import '../widgets/status_toast.dart';

/// [url]'i sistemde açar; açılamazsa varsa [fallbackUrl]'i dener (ör. Mail
/// uygulaması kurulu değilse destek sayfası), o da olmazsa lokalize hata
/// bildirimi gösterir.
Future<void> openExternalUrl(
  BuildContext context,
  String url, {
  String? fallbackUrl,
}) async {
  final String failureMessage = context.l10n.settingsLinkFailed;
  // Gösterici await öncesi alınır; böylece context'in ömrüne bağımlılık kalmaz.
  final StatusToaster toaster = StatusToaster.of(context);
  bool opened = await _launch(url);
  final String? fallback = fallbackUrl;
  if (!opened && fallback != null) opened = await _launch(fallback);
  if (!opened) {
    toaster.show(failureMessage, tone: StatusToastTone.error);
  }
}

Future<bool> _launch(String url) async {
  try {
    return await launchUrl(Uri.parse(url));
  } catch (error, stackTrace) {
    debugPrint('Link açma hatası ($url): $error\n$stackTrace');
    return false;
  }
}

// Yerel veri açılamadığında gösterilen kurtarma ekranı: yeniden dene / onaylı sıfırla.
import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../l10n/l10n_extension.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/empty_state_view.dart';

/// ProviderScope kurulamadan önce çalışan minimal uygulama kabuğu.
///
/// [onRetry] depolamayı yeniden açmayı dener, [onReset] kullanıcı onayından
/// sonra yerel verileri silip yeniden açar. Başarıda çağıran `runApp` ile bu
/// kabuğu gerçek uygulamayla değiştirir; başarısızlıkta yeni bir kabuk kurar.
class StartupErrorApp extends StatefulWidget {
  const StartupErrorApp({
    super.key,
    required this.onRetry,
    required this.onReset,
  });

  final Future<void> Function() onRetry;
  final Future<void> Function() onReset;

  @override
  State<StartupErrorApp> createState() => _StartupErrorAppState();
}

class _StartupErrorAppState extends State<StartupErrorApp> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      // Başarıda kabuk zaten değiştirilmiş olabilir.
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmReset(BuildContext context) async {
    final l10n = context.l10n;
    final bool confirmed = await showDestructiveConfirm(
      context,
      title: l10n.startupErrorResetConfirmTitle,
      message: l10n.startupErrorResetConfirmBody,
      confirmLabel: l10n.startupErrorReset,
    );
    if (confirmed) await _run(widget.onReset);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          final l10n = context.l10n;
          return Scaffold(
            body: SafeArea(
              child: EmptyStateView(
                icon: AppIcons.error,
                title: l10n.startupErrorTitle,
                message: l10n.startupErrorBody,
                actionLabel: l10n.retryAction,
                onAction: _busy ? null : () => _run(widget.onRetry),
                secondaryActionLabel: l10n.startupErrorReset,
                onSecondaryAction: _busy ? null : () => _confirmReset(context),
              ),
            ),
          );
        },
      ),
    );
  }
}

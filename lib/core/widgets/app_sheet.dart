// iOS sheet yardımcıları: sayfa gibi modaller için CupertinoSheetRoute (go_router
// Page'i dahil), küçük seçiciler için kök navigator'da kısa bottom sheet.
import 'package:flutter/cupertino.dart';

/// go_router `pageBuilder`'ında kullanılan iOS sheet sayfası: kart gibi alttan
/// açılır, arkadaki sayfa geri çekilip küçülür, aşağı sürükleyince kapanır.
/// Sayfa kök navigator'a ait bir rotada tanımlanmalıdır (sekme çubuğu altta
/// kalsın diye).
class CupertinoSheetPage<T> extends Page<T> {
  const CupertinoSheetPage({
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    required this.builder,
    this.enableDrag = true,
  });

  /// Verilen [ScrollController] sheet'in kaydırıcısına bağlanmalı; aksi halde
  /// içerik kaydırması ile "aşağı çekip kapat" jesti birbirini tanımaz.
  final ScrollableWidgetBuilder builder;

  /// Aşağı sürükleyerek kapatma (ör. satın alma sürerken kapatılabilir).
  final bool enableDrag;

  @override
  Route<T> createRoute(BuildContext context) {
    return CupertinoSheetRoute<T>(
      settings: this,
      scrollableBuilder: builder,
      enableDrag: enableDrag,
    );
  }
}

/// Sayfa gibi modal'ı rota tanımı olmadan açar (kök navigator).
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required ScrollableWidgetBuilder builder,
}) {
  return showCupertinoSheet<T>(context: context, scrollableBuilder: builder);
}

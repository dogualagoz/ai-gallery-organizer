// Kategori enum'ının lokalize etiket ve ikon karşılıkları (UI katmanı için).
import 'package:flutter/material.dart';

import '../models/screenshot_category.dart';
import 'l10n_extension.dart';

extension ScreenshotCategoryX on ScreenshotCategory {
  /// Kullanıcıya gösterilecek lokalize ad.
  String label(AppLocalizations l10n) {
    switch (this) {
      case ScreenshotCategory.lockScreen:
        return l10n.categoryLockScreen;
      case ScreenshotCategory.social:
        return l10n.categorySocial;
      case ScreenshotCategory.shopping:
        return l10n.categoryShopping;
      case ScreenshotCategory.notesPasswords:
        return l10n.categoryNotesPasswords;
      case ScreenshotCategory.messages:
        return l10n.categoryMessages;
      case ScreenshotCategory.receipts:
        return l10n.categoryReceipts;
      case ScreenshotCategory.other:
        return l10n.categoryOther;
    }
  }

  /// Kategoriye eşlik eden ikon.
  IconData get icon {
    switch (this) {
      case ScreenshotCategory.lockScreen:
        return Icons.lock_outline;
      case ScreenshotCategory.social:
        return Icons.alternate_email;
      case ScreenshotCategory.shopping:
        return Icons.shopping_bag_outlined;
      case ScreenshotCategory.notesPasswords:
        return Icons.sticky_note_2_outlined;
      case ScreenshotCategory.messages:
        return Icons.chat_bubble_outline;
      case ScreenshotCategory.receipts:
        return Icons.receipt_long_outlined;
      case ScreenshotCategory.other:
        return Icons.photo_outlined;
    }
  }
}

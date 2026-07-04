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
      case ScreenshotCategory.qrCodes:
        return l10n.categoryQrCodes;
      case ScreenshotCategory.recipes:
        return l10n.categoryRecipes;
      case ScreenshotCategory.places:
        return l10n.categoryPlaces;
      case ScreenshotCategory.inspiration:
        return l10n.categoryInspiration;
      case ScreenshotCategory.memes:
        return l10n.categoryMemes;
      case ScreenshotCategory.outfits:
        return l10n.categoryOutfits;
      case ScreenshotCategory.health:
        return l10n.categoryHealth;
      case ScreenshotCategory.tickets:
        return l10n.categoryTickets;
      case ScreenshotCategory.travel:
        return l10n.categoryTravel;
      case ScreenshotCategory.food:
        return l10n.categoryFood;
      case ScreenshotCategory.finance:
        return l10n.categoryFinance;
      case ScreenshotCategory.documents:
        return l10n.categoryDocuments;
      case ScreenshotCategory.education:
        return l10n.categoryEducation;
      case ScreenshotCategory.entertainment:
        return l10n.categoryEntertainment;
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
      case ScreenshotCategory.qrCodes:
        return Icons.qr_code_2;
      case ScreenshotCategory.recipes:
        return Icons.restaurant_menu_outlined;
      case ScreenshotCategory.places:
        return Icons.place_outlined;
      case ScreenshotCategory.inspiration:
        return Icons.lightbulb_outline;
      case ScreenshotCategory.memes:
        return Icons.sentiment_very_satisfied_outlined;
      case ScreenshotCategory.outfits:
        return Icons.checkroom_outlined;
      case ScreenshotCategory.health:
        return Icons.favorite_outline;
      case ScreenshotCategory.tickets:
        return Icons.confirmation_number_outlined;
      case ScreenshotCategory.travel:
        return Icons.flight_takeoff_outlined;
      case ScreenshotCategory.food:
        return Icons.lunch_dining_outlined;
      case ScreenshotCategory.finance:
        return Icons.account_balance_outlined;
      case ScreenshotCategory.documents:
        return Icons.description_outlined;
      case ScreenshotCategory.education:
        return Icons.school_outlined;
      case ScreenshotCategory.entertainment:
        return Icons.movie_outlined;
    }
  }
}

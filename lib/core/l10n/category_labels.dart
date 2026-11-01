// Kategori enum'ının lokalize etiket ve ikon karşılıkları (UI katmanı için).
import 'package:flutter/cupertino.dart';

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

  /// Görüntülenecek ad: kullanıcı özel adı ([overrides]) varsa onu, yoksa
  /// lokalize [label]'ı döndürür. [overrides] anahtarı kategori index'idir.
  String displayName(AppLocalizations l10n, Map<int, String> overrides) =>
      overrides[index] ?? label(l10n);

  /// Kategoriye eşlik eden ikon (SF Symbols karşılığı CupertinoIcons).
  IconData get icon {
    switch (this) {
      case ScreenshotCategory.lockScreen:
        return CupertinoIcons.lock;
      case ScreenshotCategory.social:
        return CupertinoIcons.at;
      case ScreenshotCategory.shopping:
        return CupertinoIcons.bag;
      case ScreenshotCategory.notesPasswords:
        return CupertinoIcons.square_pencil;
      case ScreenshotCategory.messages:
        return CupertinoIcons.chat_bubble;
      case ScreenshotCategory.receipts:
        return CupertinoIcons.doc_plaintext;
      case ScreenshotCategory.other:
        return CupertinoIcons.photo;
      case ScreenshotCategory.qrCodes:
        return CupertinoIcons.qrcode;
      case ScreenshotCategory.recipes:
        return CupertinoIcons.flame;
      case ScreenshotCategory.places:
        return CupertinoIcons.location;
      case ScreenshotCategory.inspiration:
        return CupertinoIcons.lightbulb;
      case ScreenshotCategory.memes:
        return CupertinoIcons.smiley;
      case ScreenshotCategory.outfits:
        return CupertinoIcons.tag;
      case ScreenshotCategory.health:
        return CupertinoIcons.heart;
      case ScreenshotCategory.tickets:
        return CupertinoIcons.ticket;
      case ScreenshotCategory.travel:
        return CupertinoIcons.airplane;
      case ScreenshotCategory.food:
        return CupertinoIcons.cart;
      case ScreenshotCategory.finance:
        return CupertinoIcons.creditcard;
      case ScreenshotCategory.documents:
        return CupertinoIcons.doc_text;
      case ScreenshotCategory.education:
        return CupertinoIcons.book;
      case ScreenshotCategory.entertainment:
        return CupertinoIcons.film;
    }
  }
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Snaply';

  @override
  String get tabGallery => 'Gallery';

  @override
  String get tabBoards => 'Boards';

  @override
  String get tabSettings => 'Settings';

  @override
  String get galleryTitle => 'Screenshots';

  @override
  String get boardsTitle => 'Boards';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTheme => 'Appearance';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get searchTitle => 'Search';

  @override
  String get sortingTitle => 'Sort';

  @override
  String get paywallTitle => 'Go Pro';

  @override
  String get detailTitle => 'Details';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get onboardingTitle1 => 'Your screenshots, finally sorted';

  @override
  String get onboardingBody1 =>
      'Snaply finds every screenshot in your library and files it into tidy boards — automatically.';

  @override
  String get onboardingTitle2 => 'Private by design';

  @override
  String get onboardingBody2 =>
      'Your screenshots are stored on your device. Each one is sent briefly to AI only to label it; nothing is kept on any server.';

  @override
  String get onboardingTitle3 => 'Allow photo access';

  @override
  String get onboardingBody3 =>
      'To find and organize your screenshots, Snaply needs access to your photo library. You stay in control.';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingStart => 'Allow and start';

  @override
  String get permissionDeniedTitle => 'Photo access needed';

  @override
  String get permissionDeniedBody =>
      'Snaply can\'t see your screenshots without permission. You can enable access in Settings.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get notNow => 'Not now';

  @override
  String get gallerySyncTooltip => 'Sync library';

  @override
  String get galleryEmptyTitle => 'No screenshots yet';

  @override
  String get galleryEmptyBody =>
      'Take a screenshot, or sync your library to bring existing ones in.';

  @override
  String get gallerySyncAction => 'Sync now';

  @override
  String get gallerySyncFailed =>
      'Couldn\'t sync your library. Please try again.';

  @override
  String get galleryPermissionTitle => 'Snaply can\'t see your library';

  @override
  String get galleryPermissionBody =>
      'Photo access is off. Enable it in Settings to organize your screenshots.';

  @override
  String galleryCount(int count) {
    return '$count screenshots';
  }

  @override
  String get detailNotAnalyzed => 'Not analyzed yet';

  @override
  String get detailTagsTitle => 'Tags';

  @override
  String get detailOcrTitle => 'Text in screenshot';

  @override
  String get detailAnalyzeNow => 'Analyze now';

  @override
  String get detailShare => 'Share';

  @override
  String get detailDelete => 'Delete';

  @override
  String get detailShareFailed =>
      'Couldn\'t open the share sheet. Please try again.';

  @override
  String get detailDeleteFailed =>
      'Couldn\'t delete the screenshot. Please try again.';

  @override
  String analysisPendingBanner(int count) {
    return '$count screenshots waiting for analysis';
  }

  @override
  String get analysisStartAction => 'Analyze';

  @override
  String analysisProgress(int done, int total) {
    return '$done of $total analyzed';
  }

  @override
  String get analysisCancelAction => 'Cancel';

  @override
  String analysisCompleted(int count) {
    return '$count screenshots analyzed';
  }

  @override
  String analysisCompletedWithFailures(int done, int failed) {
    return '$done analyzed, $failed failed';
  }

  @override
  String get analysisFailedBanner =>
      'Analysis failed. Check your connection and try again.';

  @override
  String get analysisRetryAction => 'Retry';

  @override
  String get analysisLimitBanner => 'Your free analysis quota is used up.';

  @override
  String get dismissAction => 'Dismiss';

  @override
  String get categoryLockScreen => 'Lock screen';

  @override
  String get categorySocial => 'Social';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categoryNotesPasswords => 'Notes & passwords';

  @override
  String get categoryMessages => 'Messages';

  @override
  String get categoryReceipts => 'Receipts';

  @override
  String get categoryOther => 'Other';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get boardsSystemSection => 'Categories';

  @override
  String get boardsCustomSection => 'My boards';

  @override
  String get boardsNewBoardAction => 'New board';

  @override
  String get boardsNewBoardDialogTitle => 'New board';

  @override
  String get boardsNewBoardHint => 'Board name';

  @override
  String get boardsCreateAction => 'Create';

  @override
  String get boardsRenameAction => 'Rename';

  @override
  String get boardsRenameDialogTitle => 'Rename board';

  @override
  String get boardsDeleteAction => 'Delete board';

  @override
  String get boardsDeleteConfirmTitle => 'Delete this board?';

  @override
  String get boardsDeleteConfirmBody =>
      'Screenshots inside won\'t be deleted, only removed from this board.';

  @override
  String get boardsLimitTitle => 'You\'ve reached the free board limit';

  @override
  String get boardDetailEmpty => 'No screenshots here yet';

  @override
  String get searchHint => 'Search tags, text, or category';

  @override
  String get searchPrompt => 'Start typing to search';

  @override
  String get searchEmpty => 'No results found';

  @override
  String get searchLockedTitle => 'Search is a Pro feature';

  @override
  String get searchLockedBody =>
      'Go Pro to search across tags and screenshot text.';

  @override
  String get sortingEmptyTitle => 'Nothing left to sort';

  @override
  String get sortingEmptyBody => 'All your screenshots look organized.';

  @override
  String get sortingLimitTitle => 'Your free sorting quota is used up';

  @override
  String get sortingLimitBody => 'Go Pro for unlimited sorting.';

  @override
  String get sortingAssignSheetTitle => 'Which board should this go to?';

  @override
  String get sortingHintDelete => 'Delete';

  @override
  String get sortingHintAssign => 'Add to board';

  @override
  String get sortingHintSkip => 'Skip';

  @override
  String sortingRemainingCount(int count) {
    return '$count left';
  }

  @override
  String get sortingDeleteFailed => 'Couldn\'t delete the screenshot.';

  @override
  String get bulkSelectAction => 'Select';

  @override
  String bulkSelectionCount(int count) {
    return '$count selected';
  }

  @override
  String get bulkDeleteAction => 'Delete selected';

  @override
  String get bulkDeleteFailed =>
      'Couldn\'t delete the selected screenshots. Please try again.';

  @override
  String get paywallWelcomeTitle => 'Snaply Pro';

  @override
  String get paywallSubtitle =>
      'Unlimited analysis, unlimited boards, and more';

  @override
  String get paywallFeatureAnalysis => 'Automatic AI analysis';

  @override
  String get paywallFeatureBoards => 'Custom boards';

  @override
  String get paywallFeatureSwipe => 'Swipe sorting';

  @override
  String get paywallFeatureSearch => 'Tag and text search';

  @override
  String get paywallFeatureBulkDelete => 'Bulk delete';

  @override
  String get paywallFreeLabel => 'Free';

  @override
  String get paywallProLabel => 'Pro';

  @override
  String paywallLimitedValue(int count) {
    return '$count';
  }

  @override
  String get paywallUnlimitedValue => 'Unlimited';

  @override
  String get paywallLockedValue => 'Locked';

  @override
  String get paywallUnlockedValue => 'Unlocked';

  @override
  String get paywallPlanMonthly => 'Monthly';

  @override
  String get paywallPlanYearly => 'Yearly';

  @override
  String get paywallPlanLifetime => 'Lifetime';

  @override
  String get paywallYearlyBadge => 'Best value';

  @override
  String get paywallYearlyTrial => 'Try 14 days free';

  @override
  String paywallPerMonth(String price) {
    return '$price / month';
  }

  @override
  String paywallPerYear(String price) {
    return '$price / year';
  }

  @override
  String paywallOneTime(String price) {
    return '$price one-time';
  }

  @override
  String get paywallContinueAction => 'Continue';

  @override
  String get paywallRestoreAction => 'Restore purchases';

  @override
  String get paywallPurchaseFailed =>
      'Purchase couldn\'t be completed. Please try again.';

  @override
  String get paywallProductsUnavailable =>
      'Plans couldn\'t be loaded right now. Please try again later.';

  @override
  String get paywallTermsLink => 'Terms of Use';

  @override
  String get paywallPrivacyLink => 'Privacy Policy';

  @override
  String get paywallAutoRenewNote =>
      'Subscriptions renew automatically at the end of each period; cancel anytime in your App Store settings.';

  @override
  String get settingsProActive => 'You\'re on Snaply Pro';

  @override
  String get settingsProActiveBody => 'Every feature is unlocked. Thank you!';

  @override
  String get settingsGoPro => 'Upgrade to Snaply Pro';

  @override
  String get settingsGoProBody =>
      'Unlimited analysis, boards and search await.';

  @override
  String get settingsPurchasesSection => 'Purchases';

  @override
  String get settingsRestoreSuccess => 'Purchases restored.';

  @override
  String get settingsAboutSection => 'About';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsLinkFailed =>
      'The link couldn\'t be opened. Please try again.';
}

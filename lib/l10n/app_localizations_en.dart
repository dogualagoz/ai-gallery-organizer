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
  String get tabHome => 'Home';

  @override
  String get tabSort => 'Sort';

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
  String get autoSortPausedChip => 'Auto-sort paused — upgrade to Pro';

  @override
  String get settingsSectionAutoSort => 'Auto-sort';

  @override
  String get settingsAutoSortTitle => 'Automatically sort new screenshots';

  @override
  String get settingsAutoSortSubtitle =>
      'Runs in the background whenever new screenshots appear';

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
  String get analysisLimitBanner =>
      'Your free weekly analysis quota is used up. Go Pro or grab an analysis pack.';

  @override
  String get analysisTrialLimitBanner =>
      'You\'ve reached the trial analysis limit. Grab an analysis pack, or unlimited unlocks when your trial converts.';

  @override
  String analysisLimitCompleted(int count) {
    return '$count screenshots organized. Go Pro or grab an analysis pack to keep going.';
  }

  @override
  String get analysisDailyCapBanner =>
      'Daily analysis limit reached. It will continue tomorrow.';

  @override
  String onboardingTitleQuota(int count) {
    return '$count free analyses, every week';
  }

  @override
  String onboardingBodyQuota(int count) {
    return 'Snaply organizes $count screenshots for free each week — your quota renews automatically. Packs and Pro are there when you need more.';
  }

  @override
  String analyzeHeroTitle(int count) {
    return 'Analyze $count screenshots';
  }

  @override
  String analyzeHeroQuotaHint(int remaining, int limit) {
    return '$remaining of $limit free analyses left this week';
  }

  @override
  String get analyzeHeroUnlimited => 'Unlimited analysis with Pro';

  @override
  String analyzeHeroTrialHint(int count) {
    return '$count trial analyses left';
  }

  @override
  String get analysisExperienceTitle => 'Organizing your screenshots';

  @override
  String get milestoneTitle => 'Great progress!';

  @override
  String milestoneSubtitle(int limit) {
    return 'You\'ve used all $limit free analyses this week.';
  }

  @override
  String milestoneRunSummary(int count) {
    return '$count screenshots organized in this run.';
  }

  @override
  String milestoneResetHint(int days) {
    return 'Your free quota renews in $days days.';
  }

  @override
  String get milestoneCtaPacks => 'Browse analysis packs';

  @override
  String get milestoneCtaPro => 'Go Pro — unlimited analysis';

  @override
  String get milestoneCtaLater => 'Continue next week';

  @override
  String get dismissAction => 'Dismiss';

  @override
  String get categoryLockScreen => 'Lock screen';

  @override
  String get categorySocial => 'Social';

  @override
  String get categoryNotesPasswords => 'Notes & passwords';

  @override
  String get categoryMessages => 'Chats';

  @override
  String get categoryShopping => 'Products';

  @override
  String get categoryQrCodes => 'QR codes';

  @override
  String get categoryRecipes => 'Recipes';

  @override
  String get categoryPlaces => 'Places';

  @override
  String get categoryInspiration => 'Inspiration';

  @override
  String get categoryMemes => 'Memes';

  @override
  String get categoryOutfits => 'Outfits';

  @override
  String get categoryHealth => 'Health';

  @override
  String get categoryTickets => 'Tickets';

  @override
  String get categoryTravel => 'Travel';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryFinance => 'Finance';

  @override
  String get categoryDocuments => 'Documents';

  @override
  String get categoryEducation => 'Education';

  @override
  String get categoryEntertainment => 'Entertainment';

  @override
  String get categoryReceipts => 'Receipts';

  @override
  String get categoryOther => 'Other';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get boardsSystemSection => 'Categories';

  @override
  String get boardsEmptyHint =>
      'Categorized screenshots will appear here once analyzed';

  @override
  String get boardsCustomSection => 'My boards';

  @override
  String get homeRecentsSection => 'Recents';

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
  String get boardsLimitTitle => 'Custom boards are a Pro feature';

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
  String get paywallWelcomeTitle => 'Never lose a screenshot again';

  @override
  String get paywallSubtitle =>
      'Snaply Pro sorts every screenshot for you, automatically';

  @override
  String get paywallFeatureAnalysis => 'Automatic AI analysis';

  @override
  String get paywallFeatureAnalysisBody =>
      'Every screenshot is categorized the moment it appears';

  @override
  String get paywallFeatureBoards => 'Custom boards';

  @override
  String get paywallFeatureBoardsBody =>
      'Create your own boards beyond the smart ones';

  @override
  String get paywallFeatureSwipe => 'Swipe sorting';

  @override
  String get paywallFeatureSwipeBody =>
      'Sort the stragglers with quick, satisfying swipes';

  @override
  String get paywallFeatureSearch => 'Tag and text search';

  @override
  String get paywallFeatureSearchBody =>
      'Find anything by its text, tag, or category';

  @override
  String get paywallFeatureBulkDelete => 'Bulk delete';

  @override
  String get paywallFeatureBulkDeleteBody =>
      'Clear out hundreds of screenshots in one go';

  @override
  String get paywallUnitMonth => '/month';

  @override
  String get paywallUnitYear => '/year';

  @override
  String get paywallUnitOnce => 'one-time';

  @override
  String get paywallPlanMonthly => 'Monthly';

  @override
  String get paywallPlanYearly => 'Yearly';

  @override
  String get paywallPlanLifetime => 'Lifetime';

  @override
  String paywallSavingsBadge(int percent) {
    return 'Save $percent%';
  }

  @override
  String paywallPerMonthEquivalent(String price) {
    return '≈ $price/mo';
  }

  @override
  String get paywallYearlyTrial => 'Try 7 days free';

  @override
  String get paywallCtaTrial => 'Try 7 days free';

  @override
  String paywallThenPerYear(String price) {
    return 'Then $price/year. Cancel anytime.';
  }

  @override
  String get paywallTimelineDay1Title => 'Day 1 — Today';

  @override
  String paywallTimelineDay1Body(int count) {
    return 'Pro features unlock immediately, including $count AI analyses during the trial.';
  }

  @override
  String get paywallTimelineDay5Title => 'Day 5 — Reminder';

  @override
  String get paywallTimelineDay5Body =>
      'We\'ll email you before your trial ends.';

  @override
  String get paywallTimelineDay7Title => 'Day 7 — Trial ends';

  @override
  String get paywallTimelineDay7Body =>
      'Your subscription starts. Cancel anytime before.';

  @override
  String get paywallPacksTitle => 'Just need more analyses?';

  @override
  String get paywallPacksSubtitle =>
      'One-time credit packs, no subscription needed.';

  @override
  String paywallPackCredits(int count) {
    return '$count analyses';
  }

  @override
  String paywallPackDescription(int count) {
    return 'Analyzes and organizes your last $count screenshots.';
  }

  @override
  String paywallPackPurchased(int count) {
    return '$count analyses added to your account!';
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
  String get settingsRemainingAnalyses => 'Remaining analyses';

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

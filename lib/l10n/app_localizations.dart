import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Snaply'**
  String get appTitle;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get tabSort;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @galleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Screenshots'**
  String get galleryTitle;

  /// No description provided for @boardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Boards'**
  String get boardsTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsTheme;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @autoSortPausedChip.
  ///
  /// In en, this message translates to:
  /// **'Auto-sort paused — upgrade to Pro'**
  String get autoSortPausedChip;

  /// No description provided for @settingsSectionAutoSort.
  ///
  /// In en, this message translates to:
  /// **'Auto-sort'**
  String get settingsSectionAutoSort;

  /// No description provided for @settingsAutoSortTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically sort new screenshots'**
  String get settingsAutoSortTitle;

  /// No description provided for @settingsAutoSortSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Runs in the background whenever new screenshots appear'**
  String get settingsAutoSortSubtitle;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @sortingTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortingTitle;

  /// No description provided for @paywallTitle.
  ///
  /// In en, this message translates to:
  /// **'Go Pro'**
  String get paywallTitle;

  /// No description provided for @detailTitle.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailTitle;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Your screenshots, finally sorted'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'Snaply finds every screenshot in your library and files it into tidy boards — automatically.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Private by design'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'Your screenshots are stored on your device. Each one is sent briefly to AI only to label it; nothing is kept on any server.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Allow photo access'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'To find and organize your screenshots, Snaply needs access to your photo library. You stay in control.'**
  String get onboardingBody3;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Allow and start'**
  String get onboardingStart;

  /// No description provided for @permissionDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo access needed'**
  String get permissionDeniedTitle;

  /// No description provided for @permissionDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'Snaply can\'t see your screenshots without permission. You can enable access in Settings.'**
  String get permissionDeniedBody;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @gallerySyncTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sync library'**
  String get gallerySyncTooltip;

  /// No description provided for @galleryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No screenshots yet'**
  String get galleryEmptyTitle;

  /// No description provided for @galleryEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Take a screenshot, or sync your library to bring existing ones in.'**
  String get galleryEmptyBody;

  /// No description provided for @gallerySyncAction.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get gallerySyncAction;

  /// No description provided for @gallerySyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sync your library. Please try again.'**
  String get gallerySyncFailed;

  /// No description provided for @galleryCount.
  ///
  /// In en, this message translates to:
  /// **'{count} screenshots'**
  String galleryCount(int count);

  /// No description provided for @detailNotAnalyzed.
  ///
  /// In en, this message translates to:
  /// **'Not analyzed yet'**
  String get detailNotAnalyzed;

  /// No description provided for @detailTagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get detailTagsTitle;

  /// No description provided for @detailOcrTitle.
  ///
  /// In en, this message translates to:
  /// **'Text in screenshot'**
  String get detailOcrTitle;

  /// No description provided for @detailAnalyzeNow.
  ///
  /// In en, this message translates to:
  /// **'Analyze now'**
  String get detailAnalyzeNow;

  /// No description provided for @detailShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get detailShare;

  /// No description provided for @detailDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get detailDelete;

  /// No description provided for @detailShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the share sheet. Please try again.'**
  String get detailShareFailed;

  /// No description provided for @detailDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the screenshot. Please try again.'**
  String get detailDeleteFailed;

  /// No description provided for @analysisPendingBanner.
  ///
  /// In en, this message translates to:
  /// **'{count} screenshots waiting for analysis'**
  String analysisPendingBanner(int count);

  /// No description provided for @analysisStartAction.
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get analysisStartAction;

  /// No description provided for @analysisProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} analyzed'**
  String analysisProgress(int done, int total);

  /// No description provided for @analysisCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get analysisCancelAction;

  /// No description provided for @analysisCompleted.
  ///
  /// In en, this message translates to:
  /// **'{count} screenshots analyzed'**
  String analysisCompleted(int count);

  /// No description provided for @analysisCompletedWithFailures.
  ///
  /// In en, this message translates to:
  /// **'{done} analyzed, {failed} failed'**
  String analysisCompletedWithFailures(int done, int failed);

  /// No description provided for @analysisFailedBanner.
  ///
  /// In en, this message translates to:
  /// **'Analysis failed. Check your connection and try again.'**
  String get analysisFailedBanner;

  /// No description provided for @analysisRetryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get analysisRetryAction;

  /// No description provided for @analysisLimitBanner.
  ///
  /// In en, this message translates to:
  /// **'Your free weekly analysis quota is used up. Go Pro or grab an analysis pack.'**
  String get analysisLimitBanner;

  /// No description provided for @analysisTrialLimitBanner.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the trial analysis limit. Grab an analysis pack, or unlimited unlocks when your trial converts.'**
  String get analysisTrialLimitBanner;

  /// No description provided for @analysisLimitCompleted.
  ///
  /// In en, this message translates to:
  /// **'{count} screenshots organized. Go Pro or grab an analysis pack to keep going.'**
  String analysisLimitCompleted(int count);

  /// No description provided for @analysisDailyCapBanner.
  ///
  /// In en, this message translates to:
  /// **'Daily analysis limit reached. It will continue tomorrow.'**
  String get analysisDailyCapBanner;

  /// No description provided for @proBadgeLabel.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get proBadgeLabel;

  /// No description provided for @settingsTrialRemaining.
  ///
  /// In en, this message translates to:
  /// **'Trial — {count} analyses left'**
  String settingsTrialRemaining(int count);

  /// No description provided for @onboardingTitleQuota.
  ///
  /// In en, this message translates to:
  /// **'{count} free analyses, every week'**
  String onboardingTitleQuota(int count);

  /// No description provided for @onboardingBodyQuota.
  ///
  /// In en, this message translates to:
  /// **'Snaply organizes {count} screenshots for free each week — your quota renews automatically. Packs and Pro are there when you need more.'**
  String onboardingBodyQuota(int count);

  /// No description provided for @analyzeHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Analyze {count} screenshots'**
  String analyzeHeroTitle(int count);

  /// No description provided for @analyzeHeroQuotaHint.
  ///
  /// In en, this message translates to:
  /// **'{remaining} of {limit} free analyses left this week'**
  String analyzeHeroQuotaHint(int remaining, int limit);

  /// No description provided for @analyzeHeroQuotaWithCredits.
  ///
  /// In en, this message translates to:
  /// **'{remaining} of {limit} weekly free + {credits} credits'**
  String analyzeHeroQuotaWithCredits(int remaining, int limit, int credits);

  /// No description provided for @analyzeHeroUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited analysis with Pro'**
  String get analyzeHeroUnlimited;

  /// No description provided for @analyzeHeroTrialHint.
  ///
  /// In en, this message translates to:
  /// **'{count} trial analyses left'**
  String analyzeHeroTrialHint(int count);

  /// No description provided for @analysisExperienceTitle.
  ///
  /// In en, this message translates to:
  /// **'Organizing your screenshots'**
  String get analysisExperienceTitle;

  /// No description provided for @milestoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Great progress!'**
  String get milestoneTitle;

  /// No description provided for @milestoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used all {limit} free analyses this week.'**
  String milestoneSubtitle(int limit);

  /// No description provided for @milestoneRunSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} screenshots organized in this run.'**
  String milestoneRunSummary(int count);

  /// No description provided for @milestoneResetHint.
  ///
  /// In en, this message translates to:
  /// **'Your free quota renews in {days} days.'**
  String milestoneResetHint(int days);

  /// No description provided for @milestoneCtaPacks.
  ///
  /// In en, this message translates to:
  /// **'Browse analysis packs'**
  String get milestoneCtaPacks;

  /// No description provided for @milestoneCtaPro.
  ///
  /// In en, this message translates to:
  /// **'Go Pro — unlimited analysis'**
  String get milestoneCtaPro;

  /// No description provided for @milestoneCtaLater.
  ///
  /// In en, this message translates to:
  /// **'Continue next week'**
  String get milestoneCtaLater;

  /// No description provided for @dismissAction.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismissAction;

  /// No description provided for @categoryLockScreen.
  ///
  /// In en, this message translates to:
  /// **'Lock screen'**
  String get categoryLockScreen;

  /// No description provided for @categorySocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get categorySocial;

  /// No description provided for @categoryNotesPasswords.
  ///
  /// In en, this message translates to:
  /// **'Notes & passwords'**
  String get categoryNotesPasswords;

  /// No description provided for @categoryMessages.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get categoryMessages;

  /// No description provided for @categoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get categoryShopping;

  /// No description provided for @categoryQrCodes.
  ///
  /// In en, this message translates to:
  /// **'QR codes'**
  String get categoryQrCodes;

  /// No description provided for @categoryRecipes.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get categoryRecipes;

  /// No description provided for @categoryPlaces.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get categoryPlaces;

  /// No description provided for @categoryInspiration.
  ///
  /// In en, this message translates to:
  /// **'Inspiration'**
  String get categoryInspiration;

  /// No description provided for @categoryMemes.
  ///
  /// In en, this message translates to:
  /// **'Memes'**
  String get categoryMemes;

  /// No description provided for @categoryOutfits.
  ///
  /// In en, this message translates to:
  /// **'Outfits'**
  String get categoryOutfits;

  /// No description provided for @categoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get categoryHealth;

  /// No description provided for @categoryTickets.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get categoryTickets;

  /// No description provided for @categoryTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get categoryTravel;

  /// No description provided for @categoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// No description provided for @categoryFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get categoryFinance;

  /// No description provided for @categoryDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get categoryDocuments;

  /// No description provided for @categoryEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get categoryEducation;

  /// No description provided for @categoryEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get categoryEntertainment;

  /// No description provided for @categoryReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get categoryReceipts;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @boardsSystemSection.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get boardsSystemSection;

  /// No description provided for @boardsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Categorized screenshots will appear here once analyzed'**
  String get boardsEmptyHint;

  /// No description provided for @boardsCustomSection.
  ///
  /// In en, this message translates to:
  /// **'My boards'**
  String get boardsCustomSection;

  /// No description provided for @homeRecentsSection.
  ///
  /// In en, this message translates to:
  /// **'Recents'**
  String get homeRecentsSection;

  /// No description provided for @boardsNewBoardAction.
  ///
  /// In en, this message translates to:
  /// **'New board'**
  String get boardsNewBoardAction;

  /// No description provided for @boardsNewBoardDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'New board'**
  String get boardsNewBoardDialogTitle;

  /// No description provided for @boardsNewBoardHint.
  ///
  /// In en, this message translates to:
  /// **'Board name'**
  String get boardsNewBoardHint;

  /// No description provided for @boardsCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get boardsCreateAction;

  /// No description provided for @boardsRenameAction.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get boardsRenameAction;

  /// No description provided for @boardsRenameDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename board'**
  String get boardsRenameDialogTitle;

  /// No description provided for @boardsDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete board'**
  String get boardsDeleteAction;

  /// No description provided for @boardsDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this board?'**
  String get boardsDeleteConfirmTitle;

  /// No description provided for @boardsDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Screenshots inside won\'t be deleted, only removed from this board.'**
  String get boardsDeleteConfirmBody;

  /// No description provided for @boardsLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom boards are a Pro feature'**
  String get boardsLimitTitle;

  /// No description provided for @boardDetailEmpty.
  ///
  /// In en, this message translates to:
  /// **'No screenshots here yet'**
  String get boardDetailEmpty;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search tags, text, or category'**
  String get searchHint;

  /// No description provided for @searchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Start typing to search'**
  String get searchPrompt;

  /// No description provided for @searchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get searchEmpty;

  /// No description provided for @searchLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Search is a Pro feature'**
  String get searchLockedTitle;

  /// No description provided for @searchLockedBody.
  ///
  /// In en, this message translates to:
  /// **'Go Pro to search across tags and screenshot text.'**
  String get searchLockedBody;

  /// No description provided for @sortingEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing left to sort'**
  String get sortingEmptyTitle;

  /// No description provided for @sortingEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'All your screenshots look organized.'**
  String get sortingEmptyBody;

  /// No description provided for @sortingLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Your free sorting quota is used up'**
  String get sortingLimitTitle;

  /// No description provided for @sortingLimitBody.
  ///
  /// In en, this message translates to:
  /// **'Go Pro for unlimited sorting.'**
  String get sortingLimitBody;

  /// No description provided for @sortingAssignSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Which board should this go to?'**
  String get sortingAssignSheetTitle;

  /// No description provided for @sortingHintDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get sortingHintDelete;

  /// No description provided for @sortingHintAssign.
  ///
  /// In en, this message translates to:
  /// **'Add to board'**
  String get sortingHintAssign;

  /// No description provided for @sortingHintSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get sortingHintSkip;

  /// No description provided for @sortingRemainingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String sortingRemainingCount(int count);

  /// No description provided for @sortingDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the screenshot.'**
  String get sortingDeleteFailed;

  /// No description provided for @bulkSelectAction.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get bulkSelectAction;

  /// No description provided for @bulkSelectionCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String bulkSelectionCount(int count);

  /// No description provided for @bulkDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get bulkDeleteAction;

  /// No description provided for @bulkDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the selected screenshots. Please try again.'**
  String get bulkDeleteFailed;

  /// No description provided for @paywallWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Never lose a screenshot again'**
  String get paywallWelcomeTitle;

  /// No description provided for @paywallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Snaply Pro sorts every screenshot for you, automatically'**
  String get paywallSubtitle;

  /// No description provided for @paywallFeatureAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Automatic AI analysis'**
  String get paywallFeatureAnalysis;

  /// No description provided for @paywallFeatureAnalysisBody.
  ///
  /// In en, this message translates to:
  /// **'Every screenshot is categorized the moment it appears'**
  String get paywallFeatureAnalysisBody;

  /// No description provided for @paywallFeatureBoards.
  ///
  /// In en, this message translates to:
  /// **'Custom boards'**
  String get paywallFeatureBoards;

  /// No description provided for @paywallFeatureBoardsBody.
  ///
  /// In en, this message translates to:
  /// **'Create your own boards beyond the smart ones'**
  String get paywallFeatureBoardsBody;

  /// No description provided for @paywallFeatureSwipe.
  ///
  /// In en, this message translates to:
  /// **'Swipe sorting'**
  String get paywallFeatureSwipe;

  /// No description provided for @paywallFeatureSwipeBody.
  ///
  /// In en, this message translates to:
  /// **'Sort the stragglers with quick, satisfying swipes'**
  String get paywallFeatureSwipeBody;

  /// No description provided for @paywallFeatureSearch.
  ///
  /// In en, this message translates to:
  /// **'Tag and text search'**
  String get paywallFeatureSearch;

  /// No description provided for @paywallFeatureSearchBody.
  ///
  /// In en, this message translates to:
  /// **'Find anything by its text, tag, or category'**
  String get paywallFeatureSearchBody;

  /// No description provided for @paywallFeatureBulkDelete.
  ///
  /// In en, this message translates to:
  /// **'Bulk delete'**
  String get paywallFeatureBulkDelete;

  /// No description provided for @paywallFeatureBulkDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Clear out hundreds of screenshots in one go'**
  String get paywallFeatureBulkDeleteBody;

  /// No description provided for @paywallUnitMonth.
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get paywallUnitMonth;

  /// No description provided for @paywallUnitYear.
  ///
  /// In en, this message translates to:
  /// **'/year'**
  String get paywallUnitYear;

  /// No description provided for @paywallUnitOnce.
  ///
  /// In en, this message translates to:
  /// **'one-time'**
  String get paywallUnitOnce;

  /// No description provided for @paywallPlanMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get paywallPlanMonthly;

  /// No description provided for @paywallPlanYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get paywallPlanYearly;

  /// No description provided for @paywallPlanLifetime.
  ///
  /// In en, this message translates to:
  /// **'Lifetime'**
  String get paywallPlanLifetime;

  /// No description provided for @paywallSavingsBadge.
  ///
  /// In en, this message translates to:
  /// **'Save {percent}%'**
  String paywallSavingsBadge(int percent);

  /// No description provided for @paywallPerMonthEquivalent.
  ///
  /// In en, this message translates to:
  /// **'≈ {price}/mo'**
  String paywallPerMonthEquivalent(String price);

  /// No description provided for @paywallYearlyTrial.
  ///
  /// In en, this message translates to:
  /// **'Try 7 days free'**
  String get paywallYearlyTrial;

  /// No description provided for @paywallCtaTrial.
  ///
  /// In en, this message translates to:
  /// **'Try 7 days free'**
  String get paywallCtaTrial;

  /// No description provided for @paywallThenPerYear.
  ///
  /// In en, this message translates to:
  /// **'Then {price}/year. Cancel anytime.'**
  String paywallThenPerYear(String price);

  /// No description provided for @paywallTimelineDay1Title.
  ///
  /// In en, this message translates to:
  /// **'Day 1 — Today'**
  String get paywallTimelineDay1Title;

  /// No description provided for @paywallTimelineDay1Body.
  ///
  /// In en, this message translates to:
  /// **'Pro features unlock immediately, including {count} AI analyses during the trial.'**
  String paywallTimelineDay1Body(int count);

  /// No description provided for @paywallTimelineDay5Title.
  ///
  /// In en, this message translates to:
  /// **'Day 5 — Reminder'**
  String get paywallTimelineDay5Title;

  /// No description provided for @paywallTimelineDay5Body.
  ///
  /// In en, this message translates to:
  /// **'We\'ll email you before your trial ends.'**
  String get paywallTimelineDay5Body;

  /// No description provided for @paywallTimelineDay7Title.
  ///
  /// In en, this message translates to:
  /// **'Day 7 — Trial ends'**
  String get paywallTimelineDay7Title;

  /// No description provided for @paywallTimelineDay7Body.
  ///
  /// In en, this message translates to:
  /// **'Your subscription starts. Cancel anytime before.'**
  String get paywallTimelineDay7Body;

  /// No description provided for @paywallPacksTitle.
  ///
  /// In en, this message translates to:
  /// **'Just need more analyses?'**
  String get paywallPacksTitle;

  /// No description provided for @paywallPacksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One-time credit packs, no subscription needed.'**
  String get paywallPacksSubtitle;

  /// No description provided for @paywallPackCredits.
  ///
  /// In en, this message translates to:
  /// **'{count} analyses'**
  String paywallPackCredits(int count);

  /// No description provided for @paywallPackDescription.
  ///
  /// In en, this message translates to:
  /// **'Analyzes and organizes your last {count} screenshots.'**
  String paywallPackDescription(int count);

  /// No description provided for @paywallPackPurchased.
  ///
  /// In en, this message translates to:
  /// **'{count} analyses added to your account!'**
  String paywallPackPurchased(int count);

  /// No description provided for @paywallContinueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get paywallContinueAction;

  /// No description provided for @paywallRestoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get paywallRestoreAction;

  /// No description provided for @paywallPurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase couldn\'t be completed. Please try again.'**
  String get paywallPurchaseFailed;

  /// No description provided for @paywallProductsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Plans couldn\'t be loaded right now. Please try again later.'**
  String get paywallProductsUnavailable;

  /// No description provided for @paywallTermsLink.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get paywallTermsLink;

  /// No description provided for @paywallPrivacyLink.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get paywallPrivacyLink;

  /// No description provided for @paywallAutoRenewNote.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions renew automatically at the end of each period; cancel anytime in your App Store settings.'**
  String get paywallAutoRenewNote;

  /// No description provided for @settingsProActive.
  ///
  /// In en, this message translates to:
  /// **'You\'re on Snaply Pro'**
  String get settingsProActive;

  /// No description provided for @settingsProActiveBody.
  ///
  /// In en, this message translates to:
  /// **'Every feature is unlocked. Thank you!'**
  String get settingsProActiveBody;

  /// No description provided for @settingsGoPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Snaply Pro'**
  String get settingsGoPro;

  /// No description provided for @settingsGoProBody.
  ///
  /// In en, this message translates to:
  /// **'Unlimited analysis, boards and search await.'**
  String get settingsGoProBody;

  /// No description provided for @settingsPurchasesSection.
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get settingsPurchasesSection;

  /// No description provided for @settingsRemainingAnalyses.
  ///
  /// In en, this message translates to:
  /// **'Remaining analyses'**
  String get settingsRemainingAnalyses;

  /// No description provided for @settingsRestoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Purchases restored.'**
  String get settingsRestoreSuccess;

  /// No description provided for @settingsAboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAboutSection;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// No description provided for @settingsLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'The link couldn\'t be opened. Please try again.'**
  String get settingsLinkFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

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

  /// No description provided for @tabGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get tabGallery;

  /// No description provided for @tabBoards.
  ///
  /// In en, this message translates to:
  /// **'Boards'**
  String get tabBoards;

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
  /// **'Your screenshots stay on your device. Each one is briefly analyzed to label it, nothing is stored anywhere else.'**
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

  /// No description provided for @galleryPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Snaply can\'t see your library'**
  String get galleryPermissionTitle;

  /// No description provided for @galleryPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Photo access is off. Enable it in Settings to organize your screenshots.'**
  String get galleryPermissionBody;

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
  /// **'Your free analysis quota is used up.'**
  String get analysisLimitBanner;

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

  /// No description provided for @categoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get categoryShopping;

  /// No description provided for @categoryNotesPasswords.
  ///
  /// In en, this message translates to:
  /// **'Notes & passwords'**
  String get categoryNotesPasswords;

  /// No description provided for @categoryMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get categoryMessages;

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

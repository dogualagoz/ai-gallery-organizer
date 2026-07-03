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
      'Your screenshots stay on your device. Each one is briefly analyzed to label it, nothing is stored anywhere else.';

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
}

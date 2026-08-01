import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kri.dart';

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
    Locale('kri'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Salone Shield'**
  String get appName;

  /// Shown under the logo on the splash screen.
  ///
  /// In en, this message translates to:
  /// **'Check before you send.'**
  String get appTagline;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @actionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get actionSkip;

  /// No description provided for @actionGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get actionGetStarted;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionTryAgain;

  /// No description provided for @actionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionCopy;

  /// No description provided for @actionCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get actionCopied;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get languageTitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change this later in Settings.'**
  String get languageSubtitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageKrio.
  ///
  /// In en, this message translates to:
  /// **'Krio'**
  String get languageKrio;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Spot suspicious requests'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'Paste any WhatsApp message and Salone Shield will show you the warning signs scammers use.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Verify before you send money'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'A message asking for money is not proof of who sent it. Check the person on a number you already trust.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Protect your codes and QR access'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'Nobody needs your six-digit code or your QR screen. Anyone who asks is trying to take your account.'**
  String get onboardingBody3;

  /// No description provided for @onboardingTitle4.
  ///
  /// In en, this message translates to:
  /// **'Your messages stay on your phone'**
  String get onboardingTitle4;

  /// No description provided for @onboardingBody4.
  ///
  /// In en, this message translates to:
  /// **'Analysis runs on your device. Nothing is uploaded unless you choose to report a scam.'**
  String get onboardingBody4;

  /// No description provided for @permissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'What this app needs'**
  String get permissionsTitle;

  /// No description provided for @permissionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Salone Shield asks for as little as possible, and explains everything before asking.'**
  String get permissionsSubtitle;

  /// No description provided for @permissionInternetTitle.
  ///
  /// In en, this message translates to:
  /// **'Internet'**
  String get permissionInternetTitle;

  /// No description provided for @permissionInternetBody.
  ///
  /// In en, this message translates to:
  /// **'Only used for signing in and for sending a scam report. Message analysis works offline.'**
  String get permissionInternetBody;

  /// No description provided for @permissionPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get permissionPhotosTitle;

  /// No description provided for @permissionPhotosBody.
  ///
  /// In en, this message translates to:
  /// **'Only when you choose a screenshot to scan. The image is read on your device and is not uploaded.'**
  String get permissionPhotosBody;

  /// No description provided for @permissionContactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get permissionContactsTitle;

  /// No description provided for @permissionContactsBody.
  ///
  /// In en, this message translates to:
  /// **'Only if you add a trusted contact. Your contact list is never uploaded.'**
  String get permissionContactsBody;

  /// No description provided for @permissionNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification access'**
  String get permissionNotificationsTitle;

  /// No description provided for @permissionNotificationsBody.
  ///
  /// In en, this message translates to:
  /// **'Not used yet. When it arrives it will be off by default and you will be asked first.'**
  String get permissionNotificationsBody;

  /// No description provided for @permissionNoneRequestedNote.
  ///
  /// In en, this message translates to:
  /// **'This version requests no sensitive permissions at all.'**
  String get permissionNoneRequestedNote;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Salone Shield'**
  String get homeTitle;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'You are protected by checking, not by luck.'**
  String get homeGreeting;

  /// No description provided for @homeSecurityStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Security status'**
  String get homeSecurityStatusTitle;

  /// No description provided for @homeSecurityStatusBody.
  ///
  /// In en, this message translates to:
  /// **'Analysis runs on this phone. No message has been uploaded.'**
  String get homeSecurityStatusBody;

  /// No description provided for @homeActionAnalyse.
  ///
  /// In en, this message translates to:
  /// **'Analyse message'**
  String get homeActionAnalyse;

  /// No description provided for @homeActionAnalyseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paste a suspicious WhatsApp message'**
  String get homeActionAnalyseSubtitle;

  /// No description provided for @homeActionScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Scan screenshot'**
  String get homeActionScreenshot;

  /// No description provided for @homeActionScreenshotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read the text from a picture'**
  String get homeActionScreenshotSubtitle;

  /// No description provided for @homeActionLink.
  ///
  /// In en, this message translates to:
  /// **'Check a link'**
  String get homeActionLink;

  /// No description provided for @homeActionLinkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See if a link looks dangerous'**
  String get homeActionLinkSubtitle;

  /// No description provided for @homeActionVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify a person'**
  String get homeActionVerify;

  /// No description provided for @homeActionVerifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm who really sent a message'**
  String get homeActionVerifySubtitle;

  /// No description provided for @homeActionReport.
  ///
  /// In en, this message translates to:
  /// **'Report a scam'**
  String get homeActionReport;

  /// No description provided for @homeActionReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Warn other people'**
  String get homeActionReportSubtitle;

  /// No description provided for @homeActionChecklist.
  ///
  /// In en, this message translates to:
  /// **'Security checklist'**
  String get homeActionChecklist;

  /// No description provided for @homeActionChecklistSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lock down your accounts'**
  String get homeActionChecklistSubtitle;

  /// No description provided for @homeRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent checks'**
  String get homeRecentTitle;

  /// No description provided for @homeRecentEmpty.
  ///
  /// In en, this message translates to:
  /// **'No checks yet. Paste a message to get started.'**
  String get homeRecentEmpty;

  /// No description provided for @homeRecentCleared.
  ///
  /// In en, this message translates to:
  /// **'Recent checks cleared.'**
  String get homeRecentCleared;

  /// No description provided for @homeClearRecent.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get homeClearRecent;

  /// No description provided for @comingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Not ready yet'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'This feature arrives in a later release. It is listed here so you know it is planned, not hidden.'**
  String get comingSoonBody;

  /// No description provided for @analyseTitle.
  ///
  /// In en, this message translates to:
  /// **'Analyse message'**
  String get analyseTitle;

  /// No description provided for @analyseInstruction.
  ///
  /// In en, this message translates to:
  /// **'Paste the message exactly as you received it.'**
  String get analyseInstruction;

  /// No description provided for @analyseHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the WhatsApp message here…'**
  String get analyseHint;

  /// No description provided for @analysePaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get analysePaste;

  /// No description provided for @analyseClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get analyseClear;

  /// No description provided for @analyseRun.
  ///
  /// In en, this message translates to:
  /// **'Analyse'**
  String get analyseRun;

  /// No description provided for @analysePrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'This text is checked on your phone and is not uploaded or saved after you leave the result.'**
  String get analysePrivacyNote;

  /// No description provided for @analyseCharacterCount.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} characters'**
  String analyseCharacterCount(int count, int max);

  /// No description provided for @analyseEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Paste a message first, then tap Analyse.'**
  String get analyseEmptyError;

  /// No description provided for @analyseTooLongError.
  ///
  /// In en, this message translates to:
  /// **'That message is too long to check. Paste the important part only.'**
  String get analyseTooLongError;

  /// No description provided for @analyseNothingToPaste.
  ///
  /// In en, this message translates to:
  /// **'Your clipboard is empty.'**
  String get analyseNothingToPaste;

  /// No description provided for @resultTitle.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get resultTitle;

  /// No description provided for @resultScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Risk score {score} out of 100'**
  String resultScoreLabel(int score);

  /// No description provided for @resultSignalsTitle.
  ///
  /// In en, this message translates to:
  /// **'What we found'**
  String get resultSignalsTitle;

  /// No description provided for @resultSignalsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No known scam pattern matched this message.'**
  String get resultSignalsEmpty;

  /// No description provided for @resultSignalCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No warning signs} =1{1 warning sign} other{{count} warning signs}}'**
  String resultSignalCount(int count);

  /// No description provided for @resultMatchedText.
  ///
  /// In en, this message translates to:
  /// **'Matched: “{text}”'**
  String resultMatchedText(String text);

  /// No description provided for @resultConfidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence {percent}%'**
  String resultConfidence(int percent);

  /// No description provided for @resultNumbersTitle.
  ///
  /// In en, this message translates to:
  /// **'Phone numbers in this message'**
  String get resultNumbersTitle;

  /// No description provided for @resultNumbersNote.
  ///
  /// In en, this message translates to:
  /// **'A number appearing here does not mean it belongs to a criminal.'**
  String get resultNumbersNote;

  /// No description provided for @resultLinksTitle.
  ///
  /// In en, this message translates to:
  /// **'Links in this message'**
  String get resultLinksTitle;

  /// No description provided for @resultLinksNote.
  ///
  /// In en, this message translates to:
  /// **'Links were examined but not opened.'**
  String get resultLinksNote;

  /// No description provided for @resultActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'What to do now'**
  String get resultActionsTitle;

  /// No description provided for @resultLimitationsTitle.
  ///
  /// In en, this message translates to:
  /// **'What we could not check'**
  String get resultLimitationsTitle;

  /// No description provided for @resultVerifyPerson.
  ///
  /// In en, this message translates to:
  /// **'Verify the person'**
  String get resultVerifyPerson;

  /// No description provided for @resultReport.
  ///
  /// In en, this message translates to:
  /// **'Report this'**
  String get resultReport;

  /// No description provided for @resultMarkSafe.
  ///
  /// In en, this message translates to:
  /// **'I verified it — mark safe'**
  String get resultMarkSafe;

  /// No description provided for @resultMarkedSafe.
  ///
  /// In en, this message translates to:
  /// **'Marked as verified safe on this phone.'**
  String get resultMarkedSafe;

  /// No description provided for @resultCopyWarning.
  ///
  /// In en, this message translates to:
  /// **'Copy warning to share'**
  String get resultCopyWarning;

  /// No description provided for @resultCopiedWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning copied. You can paste it to warn someone.'**
  String get resultCopiedWarning;

  /// No description provided for @resultAnalyseAnother.
  ///
  /// In en, this message translates to:
  /// **'Check another message'**
  String get resultAnalyseAnother;

  /// No description provided for @riskLevelLow.
  ///
  /// In en, this message translates to:
  /// **'Low risk'**
  String get riskLevelLow;

  /// No description provided for @riskLevelCaution.
  ///
  /// In en, this message translates to:
  /// **'Be careful'**
  String get riskLevelCaution;

  /// No description provided for @riskLevelHigh.
  ///
  /// In en, this message translates to:
  /// **'High risk'**
  String get riskLevelHigh;

  /// No description provided for @riskLevelCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical risk'**
  String get riskLevelCritical;

  /// No description provided for @riskLevelLowShort.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get riskLevelLowShort;

  /// No description provided for @riskLevelCautionShort.
  ///
  /// In en, this message translates to:
  /// **'Caution'**
  String get riskLevelCautionShort;

  /// No description provided for @riskLevelHighShort.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get riskLevelHighShort;

  /// No description provided for @riskLevelCriticalShort.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get riskLevelCriticalShort;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings and privacy'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'Match my phone'**
  String get settingsThemeSystem;

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

  /// No description provided for @settingsPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacyTitle;

  /// No description provided for @settingsClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Delete local history'**
  String get settingsClearHistory;

  /// No description provided for @settingsClearHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'Removes every check stored on this phone.'**
  String get settingsClearHistoryBody;

  /// No description provided for @settingsClearHistoryDone.
  ///
  /// In en, this message translates to:
  /// **'Local history deleted.'**
  String get settingsClearHistoryDone;

  /// No description provided for @settingsAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Share anonymous usage counts'**
  String get settingsAnalytics;

  /// No description provided for @settingsAnalyticsBody.
  ///
  /// In en, this message translates to:
  /// **'Off by default. Never includes message content.'**
  String get settingsAnalyticsBody;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About Salone Shield'**
  String get settingsAbout;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyTitle;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'Salone Shield analyses messages on your phone. Message text is never uploaded, and is not kept after you leave the result screen. Only a small record of the risk level and which rules matched is stored locally, and you can delete it at any time.\n\nSalone Shield will never ask you for a WhatsApp verification code, a two-step PIN, or a mobile-money PIN. Nobody legitimate ever will.'**
  String get privacyBody;

  /// No description provided for @neverAskTitle.
  ///
  /// In en, this message translates to:
  /// **'Salone Shield will never ask for your code or PIN'**
  String get neverAskTitle;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Nothing was saved. You can try again safely.'**
  String get errorGeneric;

  /// No description provided for @errorRulesFailed.
  ///
  /// In en, this message translates to:
  /// **'The scam rules could not be loaded, so messages cannot be checked right now. Restarting the app usually fixes this.'**
  String get errorRulesFailed;

  /// No description provided for @urlFindingNoHttps.
  ///
  /// In en, this message translates to:
  /// **'Not a secure (https) link'**
  String get urlFindingNoHttps;

  /// No description provided for @urlFindingIpAddress.
  ///
  /// In en, this message translates to:
  /// **'Uses a raw IP address instead of a name'**
  String get urlFindingIpAddress;

  /// No description provided for @urlFindingPunycode.
  ///
  /// In en, this message translates to:
  /// **'Uses look-alike foreign characters'**
  String get urlFindingPunycode;

  /// No description provided for @urlFindingSubdomains.
  ///
  /// In en, this message translates to:
  /// **'Unusually many subdomains'**
  String get urlFindingSubdomains;

  /// No description provided for @urlFindingBrandLookalike.
  ///
  /// In en, this message translates to:
  /// **'Imitates a well-known brand'**
  String get urlFindingBrandLookalike;

  /// No description provided for @urlFindingShortener.
  ///
  /// In en, this message translates to:
  /// **'Hidden behind a link shortener'**
  String get urlFindingShortener;

  /// No description provided for @urlFindingCredentials.
  ///
  /// In en, this message translates to:
  /// **'Contains a username or password'**
  String get urlFindingCredentials;

  /// No description provided for @urlFindingPort.
  ///
  /// In en, this message translates to:
  /// **'Uses an unusual port'**
  String get urlFindingPort;

  /// No description provided for @urlFindingRedirect.
  ///
  /// In en, this message translates to:
  /// **'Sends you on to another address'**
  String get urlFindingRedirect;

  /// No description provided for @urlFindingTld.
  ///
  /// In en, this message translates to:
  /// **'Uses a domain ending often used by scams'**
  String get urlFindingTld;

  /// No description provided for @urlFindingExecutable.
  ///
  /// In en, this message translates to:
  /// **'Downloads an app file directly'**
  String get urlFindingExecutable;

  /// No description provided for @urlFindingMismatch.
  ///
  /// In en, this message translates to:
  /// **'Shows one address but goes to another'**
  String get urlFindingMismatch;

  /// No description provided for @trustedContactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Trusted contacts'**
  String get trustedContactsTitle;

  /// No description provided for @trustedContactsIntro.
  ///
  /// In en, this message translates to:
  /// **'Save the people who might ask you for money. Salone Shield can then tell you when a message claims to be one of them but comes from a different number.'**
  String get trustedContactsIntro;

  /// No description provided for @trustedContactsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No trusted contacts yet. Add the people you would actually send money to.'**
  String get trustedContactsEmpty;

  /// No description provided for @trustedContactsPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Only the people you add are saved, on this phone only. Your contact list is never read or uploaded.'**
  String get trustedContactsPrivacyNote;

  /// No description provided for @trustedContactsFull.
  ///
  /// In en, this message translates to:
  /// **'You have reached the limit of {max} trusted contacts.'**
  String trustedContactsFull(int max);

  /// No description provided for @trustedContactAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a trusted contact'**
  String get trustedContactAdd;

  /// No description provided for @trustedContactFromPhone.
  ///
  /// In en, this message translates to:
  /// **'Choose from my contacts'**
  String get trustedContactFromPhone;

  /// No description provided for @trustedContactManually.
  ///
  /// In en, this message translates to:
  /// **'Type it in myself'**
  String get trustedContactManually;

  /// No description provided for @trustedContactPickerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not open your contacts. You can type the number instead.'**
  String get trustedContactPickerUnavailable;

  /// No description provided for @trustedContactName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get trustedContactName;

  /// No description provided for @trustedContactNameHint.
  ///
  /// In en, this message translates to:
  /// **'How you know them'**
  String get trustedContactNameHint;

  /// No description provided for @trustedContactNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get trustedContactNumber;

  /// No description provided for @trustedContactNumberHint.
  ///
  /// In en, this message translates to:
  /// **'076 123 456'**
  String get trustedContactNumberHint;

  /// No description provided for @trustedContactAddNumber.
  ///
  /// In en, this message translates to:
  /// **'Add another number'**
  String get trustedContactAddNumber;

  /// No description provided for @trustedContactRelationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship (optional)'**
  String get trustedContactRelationship;

  /// No description provided for @trustedContactRelationshipHint.
  ///
  /// In en, this message translates to:
  /// **'Brother, boss, susu group…'**
  String get trustedContactRelationshipHint;

  /// No description provided for @trustedContactQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question only they can answer (optional)'**
  String get trustedContactQuestion;

  /// No description provided for @trustedContactQuestionHint.
  ///
  /// In en, this message translates to:
  /// **'Where did we meet last Christmas?'**
  String get trustedContactQuestionHint;

  /// No description provided for @trustedContactQuestionNote.
  ///
  /// In en, this message translates to:
  /// **'Never use a password, a PIN, or anything a bank would ask you.'**
  String get trustedContactQuestionNote;

  /// No description provided for @trustedContactSave.
  ///
  /// In en, this message translates to:
  /// **'Save contact'**
  String get trustedContactSave;

  /// No description provided for @trustedContactSaved.
  ///
  /// In en, this message translates to:
  /// **'Trusted contact saved.'**
  String get trustedContactSaved;

  /// No description provided for @trustedContactInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a name and at least one phone number we can read.'**
  String get trustedContactInvalid;

  /// No description provided for @trustedContactRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get trustedContactRemove;

  /// No description provided for @trustedContactRemoved.
  ///
  /// In en, this message translates to:
  /// **'Trusted contact removed.'**
  String get trustedContactRemoved;

  /// No description provided for @trustedContactRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from your trusted contacts?'**
  String trustedContactRemoveConfirm(String name);

  /// No description provided for @trustedContactPrimary.
  ///
  /// In en, this message translates to:
  /// **'Main number'**
  String get trustedContactPrimary;

  /// No description provided for @trustedContactSetPrimary.
  ///
  /// In en, this message translates to:
  /// **'Use as main number'**
  String get trustedContactSetPrimary;

  /// No description provided for @trustedContactNumberCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 number} other{{count} numbers}}'**
  String trustedContactNumberCount(int count);

  /// No description provided for @verifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify the person'**
  String get verifyTitle;

  /// No description provided for @verifyIntro.
  ///
  /// In en, this message translates to:
  /// **'Before you send anything, make sure the person is who they say they are.'**
  String get verifyIntro;

  /// No description provided for @verifyNumberInMessage.
  ///
  /// In en, this message translates to:
  /// **'Number in this message'**
  String get verifyNumberInMessage;

  /// No description provided for @verifyWhoClaims.
  ///
  /// In en, this message translates to:
  /// **'Who does the message claim to be?'**
  String get verifyWhoClaims;

  /// No description provided for @verifyChooseContact.
  ///
  /// In en, this message translates to:
  /// **'Choose a trusted contact'**
  String get verifyChooseContact;

  /// No description provided for @verifyNoContactsYet.
  ///
  /// In en, this message translates to:
  /// **'You have not saved any trusted contacts yet.'**
  String get verifyNoContactsYet;

  /// No description provided for @verifyAddContactsFirst.
  ///
  /// In en, this message translates to:
  /// **'Add trusted contacts'**
  String get verifyAddContactsFirst;

  /// No description provided for @verifyClaimedNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name they used'**
  String get verifyClaimedNameHint;

  /// No description provided for @verifyMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Number check'**
  String get verifyMatchTitle;

  /// No description provided for @verifyMatchMatches.
  ///
  /// In en, this message translates to:
  /// **'This is a number {name} already uses.'**
  String verifyMatchMatches(String name);

  /// No description provided for @verifyMatchMatchesBody.
  ///
  /// In en, this message translates to:
  /// **'That is reassuring, but a stolen phone or a hijacked account still sends messages from the right number. If money is involved, call and hear their voice.'**
  String get verifyMatchMatchesBody;

  /// No description provided for @verifyMatchDiffers.
  ///
  /// In en, this message translates to:
  /// **'This is NOT a number {name} has used before.'**
  String verifyMatchDiffers(String name);

  /// No description provided for @verifyMatchDiffersBody.
  ///
  /// In en, this message translates to:
  /// **'This is the most common impersonation scam. Do not send anything. Call the number you already have saved for them.'**
  String get verifyMatchDiffersBody;

  /// No description provided for @verifyMatchUnknown.
  ///
  /// In en, this message translates to:
  /// **'No saved number to compare against.'**
  String get verifyMatchUnknown;

  /// No description provided for @verifyMatchUnknownBody.
  ///
  /// In en, this message translates to:
  /// **'Save this person as a trusted contact once you know their real number, and the next message can be checked automatically.'**
  String get verifyMatchUnknownBody;

  /// No description provided for @verifyPreviousImpersonation.
  ///
  /// In en, this message translates to:
  /// **'You checked this number before and confirmed it was an impersonator.'**
  String get verifyPreviousImpersonation;

  /// No description provided for @verifyPreviousChecks.
  ///
  /// In en, this message translates to:
  /// **'You have checked this number {count} times before.'**
  String verifyPreviousChecks(int count);

  /// No description provided for @verifyHowTitle.
  ///
  /// In en, this message translates to:
  /// **'How to check'**
  String get verifyHowTitle;

  /// No description provided for @verifyMethodCall.
  ///
  /// In en, this message translates to:
  /// **'Call the saved number'**
  String get verifyMethodCall;

  /// No description provided for @verifyMethodCallBody.
  ///
  /// In en, this message translates to:
  /// **'Call the number you already have, not the one in the message.'**
  String get verifyMethodCallBody;

  /// No description provided for @verifyMethodSms.
  ///
  /// In en, this message translates to:
  /// **'Send a text to the saved number'**
  String get verifyMethodSms;

  /// No description provided for @verifyMethodSmsBody.
  ///
  /// In en, this message translates to:
  /// **'Useful when the line is bad.'**
  String get verifyMethodSmsBody;

  /// No description provided for @verifyMethodQuestion.
  ///
  /// In en, this message translates to:
  /// **'Ask a private question'**
  String get verifyMethodQuestion;

  /// No description provided for @verifyMethodQuestionBody.
  ///
  /// In en, this message translates to:
  /// **'Something only the real person knows.'**
  String get verifyMethodQuestionBody;

  /// No description provided for @verifyMethodRelative.
  ///
  /// In en, this message translates to:
  /// **'Ask a relative who knows them'**
  String get verifyMethodRelative;

  /// No description provided for @verifyMethodRelativeBody.
  ///
  /// In en, this message translates to:
  /// **'Someone else who can reach the real person.'**
  String get verifyMethodRelativeBody;

  /// No description provided for @verifyDialFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the phone app. Dial the number yourself.'**
  String get verifyDialFailed;

  /// No description provided for @verifyNoSavedNumber.
  ///
  /// In en, this message translates to:
  /// **'Choose a trusted contact first so there is a number to call.'**
  String get verifyNoSavedNumber;

  /// No description provided for @verifyOutcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'What did you find out?'**
  String get verifyOutcomeTitle;

  /// No description provided for @verifyOutcomeSafe.
  ///
  /// In en, this message translates to:
  /// **'I reached them — it is really them'**
  String get verifyOutcomeSafe;

  /// No description provided for @verifyOutcomeUnsure.
  ///
  /// In en, this message translates to:
  /// **'I could not reach them'**
  String get verifyOutcomeUnsure;

  /// No description provided for @verifyOutcomeImpersonation.
  ///
  /// In en, this message translates to:
  /// **'It is not them — someone is pretending'**
  String get verifyOutcomeImpersonation;

  /// No description provided for @verifyOutcomeSafeNote.
  ///
  /// In en, this message translates to:
  /// **'Saved. Remember that verifying the person does not make the request itself sensible.'**
  String get verifyOutcomeSafeNote;

  /// No description provided for @verifyOutcomeUnsureNote.
  ///
  /// In en, this message translates to:
  /// **'Saved. Not reaching someone is not the same as it being safe — do not send anything yet.'**
  String get verifyOutcomeUnsureNote;

  /// No description provided for @verifyOutcomeImpersonationNote.
  ///
  /// In en, this message translates to:
  /// **'Saved. Do not send anything, and warn the real person that someone is using their name.'**
  String get verifyOutcomeImpersonationNote;

  /// No description provided for @verifySaveOutcome.
  ///
  /// In en, this message translates to:
  /// **'Save what I found'**
  String get verifySaveOutcome;

  /// No description provided for @verifyHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Past checks'**
  String get verifyHistoryTitle;

  /// No description provided for @verifyHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No checks recorded yet.'**
  String get verifyHistoryEmpty;

  /// No description provided for @verifyOutcomeSafeShort.
  ///
  /// In en, this message translates to:
  /// **'Verified safe'**
  String get verifyOutcomeSafeShort;

  /// No description provided for @verifyOutcomeUnsureShort.
  ///
  /// In en, this message translates to:
  /// **'Could not verify'**
  String get verifyOutcomeUnsureShort;

  /// No description provided for @verifyOutcomeImpersonationShort.
  ///
  /// In en, this message translates to:
  /// **'Impersonation'**
  String get verifyOutcomeImpersonationShort;

  /// No description provided for @verifyKnownContactBadge.
  ///
  /// In en, this message translates to:
  /// **'Saved as {name}'**
  String verifyKnownContactBadge(String name);

  /// No description provided for @verifyChooseNumber.
  ///
  /// In en, this message translates to:
  /// **'Which number are you checking?'**
  String get verifyChooseNumber;

  /// No description provided for @settingsDeleteContacts.
  ///
  /// In en, this message translates to:
  /// **'Delete trusted contacts'**
  String get settingsDeleteContacts;

  /// No description provided for @settingsDeleteContactsBody.
  ///
  /// In en, this message translates to:
  /// **'Removes everyone you have saved on this phone.'**
  String get settingsDeleteContactsBody;

  /// No description provided for @settingsDeleteContactsDone.
  ///
  /// In en, this message translates to:
  /// **'Trusted contacts deleted.'**
  String get settingsDeleteContactsDone;

  /// No description provided for @settingsDeleteVerifications.
  ///
  /// In en, this message translates to:
  /// **'Delete verification history'**
  String get settingsDeleteVerifications;

  /// No description provided for @settingsDeleteVerificationsBody.
  ///
  /// In en, this message translates to:
  /// **'Removes the record of numbers you have checked.'**
  String get settingsDeleteVerificationsBody;

  /// No description provided for @settingsDeleteVerificationsDone.
  ///
  /// In en, this message translates to:
  /// **'Verification history deleted.'**
  String get settingsDeleteVerificationsDone;
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
      <String>['en', 'kri'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'kri':
      return AppLocalizationsKri();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

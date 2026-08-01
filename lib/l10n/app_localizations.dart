import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

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

  /// No description provided for @screenshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan a screenshot'**
  String get screenshotTitle;

  /// No description provided for @screenshotIntro.
  ///
  /// In en, this message translates to:
  /// **'Pick a screenshot of the message. The text is read on your phone, and the app\'s copy of the picture is deleted straight afterwards.'**
  String get screenshotIntro;

  /// No description provided for @screenshotChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose a screenshot'**
  String get screenshotChoose;

  /// No description provided for @screenshotChooseAnother.
  ///
  /// In en, this message translates to:
  /// **'Choose a different picture'**
  String get screenshotChooseAnother;

  /// No description provided for @screenshotReading.
  ///
  /// In en, this message translates to:
  /// **'Reading the text…'**
  String get screenshotReading;

  /// No description provided for @screenshotReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Check the text'**
  String get screenshotReviewTitle;

  /// No description provided for @screenshotReviewBody.
  ///
  /// In en, this message translates to:
  /// **'Reading text from a picture is not perfect. Fix anything that came out wrong before you analyse it.'**
  String get screenshotReviewBody;

  /// No description provided for @screenshotEmpty.
  ///
  /// In en, this message translates to:
  /// **'No text could be read from that picture. Try a clearer screenshot, or type the message instead.'**
  String get screenshotEmpty;

  /// No description provided for @screenshotAnalyse.
  ///
  /// In en, this message translates to:
  /// **'Analyse this text'**
  String get screenshotAnalyse;

  /// No description provided for @screenshotFailed.
  ///
  /// In en, this message translates to:
  /// **'The text could not be read. The picture was not saved. You can try another one.'**
  String get screenshotFailed;

  /// No description provided for @screenshotPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'The picture is read on your phone and never uploaded. Your own photo stays in your gallery; only the app\'s copy is deleted.'**
  String get screenshotPrivacyNote;

  /// No description provided for @screenshotUnsupported.
  ///
  /// In en, this message translates to:
  /// **'That file type is not supported. Use a PNG, JPG or WEBP screenshot.'**
  String get screenshotUnsupported;

  /// No description provided for @linkCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Check a link'**
  String get linkCheckTitle;

  /// No description provided for @linkCheckIntro.
  ///
  /// In en, this message translates to:
  /// **'Paste a link, or the whole message it came in. The link is examined on your phone and never opened.'**
  String get linkCheckIntro;

  /// No description provided for @linkCheckHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the link here…'**
  String get linkCheckHint;

  /// No description provided for @linkCheckRun.
  ///
  /// In en, this message translates to:
  /// **'Check the link'**
  String get linkCheckRun;

  /// No description provided for @linkCheckEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Paste a link first.'**
  String get linkCheckEmptyError;

  /// No description provided for @linkCheckInvalid.
  ///
  /// In en, this message translates to:
  /// **'That does not look like a web address. Check it and try again.'**
  String get linkCheckInvalid;

  /// No description provided for @linkCheckTooLong.
  ///
  /// In en, this message translates to:
  /// **'That link is too long to check.'**
  String get linkCheckTooLong;

  /// No description provided for @linkCheckResultSafeTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing suspicious found'**
  String get linkCheckResultSafeTitle;

  /// No description provided for @linkCheckResultSafeBody.
  ///
  /// In en, this message translates to:
  /// **'This link has none of the warning signs the app knows about. That is not the same as safe — the app cannot see what the page actually does.'**
  String get linkCheckResultSafeBody;

  /// No description provided for @linkCheckResultWarnTitle.
  ///
  /// In en, this message translates to:
  /// **'This link has warning signs'**
  String get linkCheckResultWarnTitle;

  /// No description provided for @linkCheckResultDangerTitle.
  ///
  /// In en, this message translates to:
  /// **'Do not open this link'**
  String get linkCheckResultDangerTitle;

  /// No description provided for @linkCheckAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get linkCheckAddress;

  /// No description provided for @linkCheckDomain.
  ///
  /// In en, this message translates to:
  /// **'Real domain'**
  String get linkCheckDomain;

  /// No description provided for @linkCheckHttps.
  ///
  /// In en, this message translates to:
  /// **'Secure connection (https)'**
  String get linkCheckHttps;

  /// No description provided for @linkCheckHttpsYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get linkCheckHttpsYes;

  /// No description provided for @linkCheckHttpsNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get linkCheckHttpsNo;

  /// No description provided for @linkCheckFindings.
  ///
  /// In en, this message translates to:
  /// **'What we found'**
  String get linkCheckFindings;

  /// No description provided for @linkCheckWhatToDo.
  ///
  /// In en, this message translates to:
  /// **'What to do'**
  String get linkCheckWhatToDo;

  /// No description provided for @linkCheckAdviceDanger.
  ///
  /// In en, this message translates to:
  /// **'Do not open it. If you need the service, type the official address into your browser yourself.'**
  String get linkCheckAdviceDanger;

  /// No description provided for @linkCheckAdviceWarn.
  ///
  /// In en, this message translates to:
  /// **'Be careful. Do not sign in or enter any code or PIN on a page you reached from a message.'**
  String get linkCheckAdviceWarn;

  /// No description provided for @linkCheckAdviceSafe.
  ///
  /// In en, this message translates to:
  /// **'If you were not expecting this link, ask the sender on a number you trust before opening it.'**
  String get linkCheckAdviceSafe;

  /// No description provided for @linkCheckCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy the link'**
  String get linkCheckCopy;

  /// No description provided for @linkCheckCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied.'**
  String get linkCheckCopied;

  /// No description provided for @linkCheckAnother.
  ///
  /// In en, this message translates to:
  /// **'Check another link'**
  String get linkCheckAnother;

  /// No description provided for @linkCheckNotOpened.
  ///
  /// In en, this message translates to:
  /// **'Salone Shield never opens links for you.'**
  String get linkCheckNotOpened;

  /// No description provided for @linkCheckBrandWarning.
  ///
  /// In en, this message translates to:
  /// **'This address is made to look like {brand}, but it is not their real website.'**
  String linkCheckBrandWarning(String brand);

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a scam'**
  String get reportTitle;

  /// No description provided for @reportIntro.
  ///
  /// In en, this message translates to:
  /// **'Reporting helps warn other people. Nothing is sent until you have seen exactly what will be shared.'**
  String get reportIntro;

  /// No description provided for @reportUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Reporting is not switched on'**
  String get reportUnavailableTitle;

  /// No description provided for @reportUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'This build has no reporting backend configured, so nothing can be submitted. Every other check still works, and still works offline.'**
  String get reportUnavailableBody;

  /// No description provided for @reportSignInNeeded.
  ///
  /// In en, this message translates to:
  /// **'You need an account to report, so that moderators can follow up and so one person cannot flood the system.'**
  String get reportSignInNeeded;

  /// No description provided for @reportThreatType.
  ///
  /// In en, this message translates to:
  /// **'What kind of scam was it?'**
  String get reportThreatType;

  /// No description provided for @reportNumber.
  ///
  /// In en, this message translates to:
  /// **'The number that contacted you'**
  String get reportNumber;

  /// No description provided for @reportPaymentNumber.
  ///
  /// In en, this message translates to:
  /// **'The number they asked you to pay'**
  String get reportPaymentNumber;

  /// No description provided for @reportLink.
  ///
  /// In en, this message translates to:
  /// **'A link in the message'**
  String get reportLink;

  /// No description provided for @reportExcerpt.
  ///
  /// In en, this message translates to:
  /// **'A short piece of the message'**
  String get reportExcerpt;

  /// No description provided for @reportExcerptHelp.
  ///
  /// In en, this message translates to:
  /// **'Include only the part that shows the scam. Do not paste a whole conversation, and remove anything private about you or anyone else.'**
  String get reportExcerptHelp;

  /// No description provided for @reportExcerptCount.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} characters'**
  String reportExcerptCount(int count, int max);

  /// No description provided for @reportDistrict.
  ///
  /// In en, this message translates to:
  /// **'District (optional)'**
  String get reportDistrict;

  /// No description provided for @reportDistrictHelp.
  ///
  /// In en, this message translates to:
  /// **'Helps moderators see where a scam is spreading. Leave it out if you would rather not say.'**
  String get reportDistrictHelp;

  /// No description provided for @reportWhatIsSent.
  ///
  /// In en, this message translates to:
  /// **'What will be sent'**
  String get reportWhatIsSent;

  /// No description provided for @reportWhatIsSentBody.
  ///
  /// In en, this message translates to:
  /// **'Only the items listed below leave your phone. Phone numbers are turned into a code on our server and stored that way, never as the number itself.'**
  String get reportWhatIsSentBody;

  /// No description provided for @reportNothingToSend.
  ///
  /// In en, this message translates to:
  /// **'Add at least a number, a link, or a piece of the message.'**
  String get reportNothingToSend;

  /// No description provided for @reportConsent.
  ///
  /// In en, this message translates to:
  /// **'I understand what will be sent, and I am reporting this honestly.'**
  String get reportConsent;

  /// No description provided for @reportConsentRequired.
  ///
  /// In en, this message translates to:
  /// **'Tick the box to confirm you have read what will be sent.'**
  String get reportConsentRequired;

  /// No description provided for @reportSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get reportSubmit;

  /// No description provided for @reportSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get reportSubmitting;

  /// No description provided for @reportSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Report sent'**
  String get reportSubmittedTitle;

  /// No description provided for @reportSubmittedBody.
  ///
  /// In en, this message translates to:
  /// **'Thank you. A moderator will look at it. Your reference is {reference}.'**
  String reportSubmittedBody(String reference);

  /// No description provided for @reportDuplicateBody.
  ///
  /// In en, this message translates to:
  /// **'You already reported this number recently, so your earlier report still stands. There is no need to send it again.'**
  String get reportDuplicateBody;

  /// No description provided for @reportNotAccusation.
  ///
  /// In en, this message translates to:
  /// **'A report is not an accusation. Moderators check reports from several people before anything is marked as verified, and a single report never labels anyone.'**
  String get reportNotAccusation;

  /// No description provided for @reportFailedNetwork.
  ///
  /// In en, this message translates to:
  /// **'The report could not be sent and nothing was saved. Your report is still on this screen — try again when you have a connection.'**
  String get reportFailedNetwork;

  /// No description provided for @reportFailedRateLimited.
  ///
  /// In en, this message translates to:
  /// **'You have sent several reports in a short time. Please wait a while before sending another.'**
  String get reportFailedRateLimited;

  /// No description provided for @reportFailedSuspended.
  ///
  /// In en, this message translates to:
  /// **'This account cannot submit reports at the moment. Contact support if you think that is wrong.'**
  String get reportFailedSuspended;

  /// No description provided for @reportFailedUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong and nothing was saved. You can try again safely.'**
  String get reportFailedUnknown;

  /// No description provided for @reportHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'My reports'**
  String get reportHistoryTitle;

  /// No description provided for @reportHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have not sent any reports yet.'**
  String get reportHistoryEmpty;

  /// No description provided for @reportHistoryStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get reportHistoryStatus;

  /// No description provided for @reportStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for review'**
  String get reportStatusPending;

  /// No description provided for @reportStatusUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Being reviewed'**
  String get reportStatusUnderReview;

  /// No description provided for @reportStatusNeedsEvidence.
  ///
  /// In en, this message translates to:
  /// **'More evidence needed'**
  String get reportStatusNeedsEvidence;

  /// No description provided for @reportStatusVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get reportStatusVerified;

  /// No description provided for @reportStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Not upheld'**
  String get reportStatusRejected;

  /// No description provided for @reportStatusDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Already reported'**
  String get reportStatusDuplicate;

  /// No description provided for @reportStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get reportStatusArchived;

  /// No description provided for @threatTypeImpersonation.
  ///
  /// In en, this message translates to:
  /// **'Someone pretended to be a person I know'**
  String get threatTypeImpersonation;

  /// No description provided for @threatTypeHijackedAccount.
  ///
  /// In en, this message translates to:
  /// **'A friend\'s account was taken over'**
  String get threatTypeHijackedAccount;

  /// No description provided for @threatTypeFinancialHelpScam.
  ///
  /// In en, this message translates to:
  /// **'Asked me for money for an emergency'**
  String get threatTypeFinancialHelpScam;

  /// No description provided for @threatTypeVerificationCodeTheft.
  ///
  /// In en, this message translates to:
  /// **'Asked me for a verification code'**
  String get threatTypeVerificationCodeTheft;

  /// No description provided for @threatTypeQrCodeScam.
  ///
  /// In en, this message translates to:
  /// **'Asked me to scan a QR code'**
  String get threatTypeQrCodeScam;

  /// No description provided for @threatTypeMobileMoneyScam.
  ///
  /// In en, this message translates to:
  /// **'Mobile money scam'**
  String get threatTypeMobileMoneyScam;

  /// No description provided for @threatTypeMaliciousLink.
  ///
  /// In en, this message translates to:
  /// **'A dangerous link'**
  String get threatTypeMaliciousLink;

  /// No description provided for @threatTypeFakeJob.
  ///
  /// In en, this message translates to:
  /// **'A fake job offer'**
  String get threatTypeFakeJob;

  /// No description provided for @threatTypeFakeLoan.
  ///
  /// In en, this message translates to:
  /// **'A fake loan'**
  String get threatTypeFakeLoan;

  /// No description provided for @threatTypeFakeInvestment.
  ///
  /// In en, this message translates to:
  /// **'A fake investment'**
  String get threatTypeFakeInvestment;

  /// No description provided for @threatTypeFakePrize.
  ///
  /// In en, this message translates to:
  /// **'A prize I never entered for'**
  String get threatTypeFakePrize;

  /// No description provided for @threatTypeBlackmail.
  ///
  /// In en, this message translates to:
  /// **'Threats or blackmail'**
  String get threatTypeBlackmail;

  /// No description provided for @threatTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get threatTypeOther;

  /// No description provided for @authSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInTitle;

  /// No description provided for @authSignUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get authSignUpTitle;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters. Do not reuse the password from your email or your bank.'**
  String get authPasswordHelp;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authSignUp;

  /// No description provided for @authSwitchToSignUp.
  ///
  /// In en, this message translates to:
  /// **'I do not have an account'**
  String get authSwitchToSignUp;

  /// No description provided for @authSwitchToSignIn.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get authSwitchToSignIn;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'I forgot my password'**
  String get authForgotPassword;

  /// No description provided for @authResetSent.
  ///
  /// In en, this message translates to:
  /// **'If that email has an account, a reset link is on its way.'**
  String get authResetSent;

  /// No description provided for @authSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authSignOut;

  /// No description provided for @authSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Signed out.'**
  String get authSignedOut;

  /// No description provided for @authGuestNote.
  ///
  /// In en, this message translates to:
  /// **'You do not need an account for anything else. Checking messages, screenshots, links and people all work signed out.'**
  String get authGuestNote;

  /// No description provided for @authNeverAsksCode.
  ///
  /// In en, this message translates to:
  /// **'Salone Shield will never ask for your WhatsApp code or your mobile-money PIN — not on this screen, not anywhere.'**
  String get authNeverAsksCode;

  /// No description provided for @authErrorInvalid.
  ///
  /// In en, this message translates to:
  /// **'That email and password do not match. Check them and try again.'**
  String get authErrorInvalid;

  /// No description provided for @authErrorNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email address first. Check your inbox for the link.'**
  String get authErrorNotConfirmed;

  /// No description provided for @authErrorAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'That email already has an account. Try signing in instead.'**
  String get authErrorAlreadyRegistered;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a longer password — at least 8 characters.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a few minutes and try again.'**
  String get authErrorRateLimited;

  /// No description provided for @authErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Nothing was saved. Try again when you have a connection.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong and nothing was saved. You can try again safely.'**
  String get authErrorUnknown;

  /// No description provided for @authCheckEmail.
  ///
  /// In en, this message translates to:
  /// **'Account created. Check your email for the confirmation link before signing in.'**
  String get authCheckEmail;

  /// No description provided for @homeHeroEyebrow.
  ///
  /// In en, this message translates to:
  /// **'On this phone'**
  String get homeHeroEyebrow;

  /// No description provided for @homeHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Check before you send'**
  String get homeHeroTitle;

  /// No description provided for @homeHeroBody.
  ///
  /// In en, this message translates to:
  /// **'Every check runs on this phone. No message has been uploaded.'**
  String get homeHeroBody;

  /// No description provided for @homeStatChecks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{check saved} other{checks saved}}'**
  String homeStatChecks(int count);

  /// No description provided for @homeStatContacts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{trusted contact} other{trusted contacts}}'**
  String homeStatContacts(int count);

  /// No description provided for @homeSectionCheck.
  ///
  /// In en, this message translates to:
  /// **'Check something'**
  String get homeSectionCheck;

  /// No description provided for @homeSectionRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent checks'**
  String get homeSectionRecent;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get navContacts;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Salone Shield';

  @override
  String get appTagline => 'Check before you send.';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionNext => 'Next';

  @override
  String get actionBack => 'Back';

  @override
  String get actionSkip => 'Skip';

  @override
  String get actionGetStarted => 'Get started';

  @override
  String get actionDone => 'Done';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionClose => 'Close';

  @override
  String get actionTryAgain => 'Try again';

  @override
  String get actionCopy => 'Copy';

  @override
  String get actionCopied => 'Copied';

  @override
  String get languageTitle => 'Choose your language';

  @override
  String get languageSubtitle => 'You can change this later in Settings.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageKrio => 'Krio';

  @override
  String get onboardingTitle1 => 'Spot suspicious requests';

  @override
  String get onboardingBody1 =>
      'Paste any WhatsApp message and Salone Shield will show you the warning signs scammers use.';

  @override
  String get onboardingTitle2 => 'Verify before you send money';

  @override
  String get onboardingBody2 =>
      'A message asking for money is not proof of who sent it. Check the person on a number you already trust.';

  @override
  String get onboardingTitle3 => 'Protect your codes and QR access';

  @override
  String get onboardingBody3 =>
      'Nobody needs your six-digit code or your QR screen. Anyone who asks is trying to take your account.';

  @override
  String get onboardingTitle4 => 'Your messages stay on your phone';

  @override
  String get onboardingBody4 =>
      'Analysis runs on your device. Nothing is uploaded unless you choose to report a scam.';

  @override
  String get permissionsTitle => 'What this app needs';

  @override
  String get permissionsSubtitle =>
      'Salone Shield asks for as little as possible, and explains everything before asking.';

  @override
  String get permissionInternetTitle => 'Internet';

  @override
  String get permissionInternetBody =>
      'Only used for signing in and for sending a scam report. Message analysis works offline.';

  @override
  String get permissionPhotosTitle => 'Photos';

  @override
  String get permissionPhotosBody =>
      'Only when you choose a screenshot to scan. The image is read on your device and is not uploaded.';

  @override
  String get permissionContactsTitle => 'Contacts';

  @override
  String get permissionContactsBody =>
      'Only if you add a trusted contact. Your contact list is never uploaded.';

  @override
  String get permissionNotificationsTitle => 'Notification access';

  @override
  String get permissionNotificationsBody =>
      'Not used yet. When it arrives it will be off by default and you will be asked first.';

  @override
  String get permissionNoneRequestedNote =>
      'This version requests no sensitive permissions at all.';

  @override
  String get homeTitle => 'Salone Shield';

  @override
  String get homeGreeting => 'You are protected by checking, not by luck.';

  @override
  String get homeSecurityStatusTitle => 'Security status';

  @override
  String get homeSecurityStatusBody =>
      'Analysis runs on this phone. No message has been uploaded.';

  @override
  String get homeActionAnalyse => 'Analyse message';

  @override
  String get homeActionAnalyseSubtitle => 'Paste a suspicious WhatsApp message';

  @override
  String get homeActionScreenshot => 'Scan screenshot';

  @override
  String get homeActionScreenshotSubtitle => 'Read the text from a picture';

  @override
  String get homeActionLink => 'Check a link';

  @override
  String get homeActionLinkSubtitle => 'See if a link looks dangerous';

  @override
  String get homeActionVerify => 'Verify a person';

  @override
  String get homeActionVerifySubtitle => 'Confirm who really sent a message';

  @override
  String get homeActionReport => 'Report a scam';

  @override
  String get homeActionReportSubtitle => 'Warn other people';

  @override
  String get homeActionChecklist => 'Security checklist';

  @override
  String get homeActionChecklistSubtitle => 'Lock down your accounts';

  @override
  String get homeRecentTitle => 'Recent checks';

  @override
  String get homeRecentEmpty =>
      'No checks yet. Paste a message to get started.';

  @override
  String get homeRecentCleared => 'Recent checks cleared.';

  @override
  String get homeClearRecent => 'Clear';

  @override
  String get comingSoonTitle => 'Not ready yet';

  @override
  String get comingSoonBody =>
      'This feature arrives in a later release. It is listed here so you know it is planned, not hidden.';

  @override
  String get analyseTitle => 'Analyse message';

  @override
  String get analyseInstruction =>
      'Paste the message exactly as you received it.';

  @override
  String get analyseHint => 'Paste the WhatsApp message here…';

  @override
  String get analysePaste => 'Paste';

  @override
  String get analyseClear => 'Clear';

  @override
  String get analyseRun => 'Analyse';

  @override
  String get analysePrivacyNote =>
      'This text is checked on your phone and is not uploaded or saved after you leave the result.';

  @override
  String analyseCharacterCount(int count, int max) {
    return '$count of $max characters';
  }

  @override
  String get analyseEmptyError => 'Paste a message first, then tap Analyse.';

  @override
  String get analyseTooLongError =>
      'That message is too long to check. Paste the important part only.';

  @override
  String get analyseNothingToPaste => 'Your clipboard is empty.';

  @override
  String get resultTitle => 'Result';

  @override
  String resultScoreLabel(int score) {
    return 'Risk score $score out of 100';
  }

  @override
  String get resultSignalsTitle => 'What we found';

  @override
  String get resultSignalsEmpty =>
      'No known scam pattern matched this message.';

  @override
  String resultSignalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count warning signs',
      one: '1 warning sign',
      zero: 'No warning signs',
    );
    return '$_temp0';
  }

  @override
  String resultMatchedText(String text) {
    return 'Matched: “$text”';
  }

  @override
  String resultConfidence(int percent) {
    return 'Confidence $percent%';
  }

  @override
  String get resultNumbersTitle => 'Phone numbers in this message';

  @override
  String get resultNumbersNote =>
      'A number appearing here does not mean it belongs to a criminal.';

  @override
  String get resultLinksTitle => 'Links in this message';

  @override
  String get resultLinksNote => 'Links were examined but not opened.';

  @override
  String get resultActionsTitle => 'What to do now';

  @override
  String get resultLimitationsTitle => 'What we could not check';

  @override
  String get resultVerifyPerson => 'Verify the person';

  @override
  String get resultReport => 'Report this';

  @override
  String get resultMarkSafe => 'I verified it — mark safe';

  @override
  String get resultMarkedSafe => 'Marked as verified safe on this phone.';

  @override
  String get resultCopyWarning => 'Copy warning to share';

  @override
  String get resultCopiedWarning =>
      'Warning copied. You can paste it to warn someone.';

  @override
  String get resultAnalyseAnother => 'Check another message';

  @override
  String get riskLevelLow => 'Low risk';

  @override
  String get riskLevelCaution => 'Be careful';

  @override
  String get riskLevelHigh => 'High risk';

  @override
  String get riskLevelCritical => 'Critical risk';

  @override
  String get riskLevelLowShort => 'Low';

  @override
  String get riskLevelCautionShort => 'Caution';

  @override
  String get riskLevelHighShort => 'High';

  @override
  String get riskLevelCriticalShort => 'Critical';

  @override
  String get settingsTitle => 'Settings and privacy';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTheme => 'Appearance';

  @override
  String get settingsThemeSystem => 'Match my phone';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsPrivacyTitle => 'Privacy';

  @override
  String get settingsClearHistory => 'Delete local history';

  @override
  String get settingsClearHistoryBody =>
      'Removes every check stored on this phone.';

  @override
  String get settingsClearHistoryDone => 'Local history deleted.';

  @override
  String get settingsAnalytics => 'Share anonymous usage counts';

  @override
  String get settingsAnalyticsBody =>
      'Off by default. Never includes message content.';

  @override
  String get settingsAbout => 'About Salone Shield';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get privacyBody =>
      'Salone Shield analyses messages on your phone. Message text is never uploaded, and is not kept after you leave the result screen. Only a small record of the risk level and which rules matched is stored locally, and you can delete it at any time.\n\nSalone Shield will never ask you for a WhatsApp verification code, a two-step PIN, or a mobile-money PIN. Nobody legitimate ever will.';

  @override
  String get neverAskTitle =>
      'Salone Shield will never ask for your code or PIN';

  @override
  String get errorGeneric =>
      'Something went wrong. Nothing was saved. You can try again safely.';

  @override
  String get errorRulesFailed =>
      'The scam rules could not be loaded, so messages cannot be checked right now. Restarting the app usually fixes this.';

  @override
  String get urlFindingNoHttps => 'Not a secure (https) link';

  @override
  String get urlFindingIpAddress => 'Uses a raw IP address instead of a name';

  @override
  String get urlFindingPunycode => 'Uses look-alike foreign characters';

  @override
  String get urlFindingSubdomains => 'Unusually many subdomains';

  @override
  String get urlFindingBrandLookalike => 'Imitates a well-known brand';

  @override
  String get urlFindingShortener => 'Hidden behind a link shortener';

  @override
  String get urlFindingCredentials => 'Contains a username or password';

  @override
  String get urlFindingPort => 'Uses an unusual port';

  @override
  String get urlFindingRedirect => 'Sends you on to another address';

  @override
  String get urlFindingTld => 'Uses a domain ending often used by scams';

  @override
  String get urlFindingExecutable => 'Downloads an app file directly';

  @override
  String get urlFindingMismatch => 'Shows one address but goes to another';
}

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
      'Only if you turn on watching for scams as they arrive. Then Salone Shield can tell you a message is worth checking — the alert never repeats the message itself.';

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

  @override
  String get trustedContactsTitle => 'Trusted contacts';

  @override
  String get trustedContactsIntro =>
      'Save the people who might ask you for money. Salone Shield can then tell you when a message claims to be one of them but comes from a different number.';

  @override
  String get trustedContactsEmpty =>
      'No trusted contacts yet. Add the people you would actually send money to.';

  @override
  String get trustedContactsPrivacyNote =>
      'Only the people you add are saved, on this phone only. Your contact list is never read or uploaded.';

  @override
  String trustedContactsFull(int max) {
    return 'You have reached the limit of $max trusted contacts.';
  }

  @override
  String get trustedContactAdd => 'Add a trusted contact';

  @override
  String get trustedContactFromPhone => 'Choose from my contacts';

  @override
  String get trustedContactManually => 'Type it in myself';

  @override
  String get trustedContactPickerUnavailable =>
      'Could not open your contacts. You can type the number instead.';

  @override
  String get trustedContactName => 'Name';

  @override
  String get trustedContactNameHint => 'How you know them';

  @override
  String get trustedContactNumber => 'Phone number';

  @override
  String get trustedContactNumberHint => '076 123 456';

  @override
  String get trustedContactAddNumber => 'Add another number';

  @override
  String get trustedContactRelationship => 'Relationship (optional)';

  @override
  String get trustedContactRelationshipHint => 'Brother, boss, susu group…';

  @override
  String get trustedContactQuestion =>
      'Question only they can answer (optional)';

  @override
  String get trustedContactQuestionHint => 'Where did we meet last Christmas?';

  @override
  String get trustedContactQuestionNote =>
      'Never use a password, a PIN, or anything a bank would ask you.';

  @override
  String get trustedContactSave => 'Save contact';

  @override
  String get trustedContactSaved => 'Trusted contact saved.';

  @override
  String get trustedContactInvalid =>
      'Enter a name and at least one phone number we can read.';

  @override
  String get trustedContactRemove => 'Remove';

  @override
  String get trustedContactRemoved => 'Trusted contact removed.';

  @override
  String trustedContactRemoveConfirm(String name) {
    return 'Remove $name from your trusted contacts?';
  }

  @override
  String get trustedContactPrimary => 'Main number';

  @override
  String get trustedContactSetPrimary => 'Use as main number';

  @override
  String trustedContactNumberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count numbers',
      one: '1 number',
    );
    return '$_temp0';
  }

  @override
  String get verifyTitle => 'Verify the person';

  @override
  String get verifyIntro =>
      'Before you send anything, make sure the person is who they say they are.';

  @override
  String get verifyNumberInMessage => 'Number in this message';

  @override
  String get verifyWhoClaims => 'Who does the message claim to be?';

  @override
  String get verifyChooseContact => 'Choose a trusted contact';

  @override
  String get verifyNoContactsYet =>
      'You have not saved any trusted contacts yet.';

  @override
  String get verifyAddContactsFirst => 'Add trusted contacts';

  @override
  String get verifyClaimedNameHint => 'Name they used';

  @override
  String get verifyMatchTitle => 'Number check';

  @override
  String verifyMatchMatches(String name) {
    return 'This is a number $name already uses.';
  }

  @override
  String get verifyMatchMatchesBody =>
      'That is reassuring, but a stolen phone or a hijacked account still sends messages from the right number. If money is involved, call and hear their voice.';

  @override
  String verifyMatchDiffers(String name) {
    return 'This is NOT a number $name has used before.';
  }

  @override
  String get verifyMatchDiffersBody =>
      'This is the most common impersonation scam. Do not send anything. Call the number you already have saved for them.';

  @override
  String get verifyMatchUnknown => 'No saved number to compare against.';

  @override
  String get verifyMatchUnknownBody =>
      'Save this person as a trusted contact once you know their real number, and the next message can be checked automatically.';

  @override
  String get verifyPreviousImpersonation =>
      'You checked this number before and confirmed it was an impersonator.';

  @override
  String verifyPreviousChecks(int count) {
    return 'You have checked this number $count times before.';
  }

  @override
  String get verifyHowTitle => 'How to check';

  @override
  String get verifyMethodCall => 'Call the saved number';

  @override
  String get verifyMethodCallBody =>
      'Call the number you already have, not the one in the message.';

  @override
  String get verifyMethodSms => 'Send a text to the saved number';

  @override
  String get verifyMethodSmsBody => 'Useful when the line is bad.';

  @override
  String get verifyMethodQuestion => 'Ask a private question';

  @override
  String get verifyMethodQuestionBody =>
      'Something only the real person knows.';

  @override
  String get verifyMethodRelative => 'Ask a relative who knows them';

  @override
  String get verifyMethodRelativeBody =>
      'Someone else who can reach the real person.';

  @override
  String get verifyDialFailed =>
      'Could not open the phone app. Dial the number yourself.';

  @override
  String get verifyNoSavedNumber =>
      'Choose a trusted contact first so there is a number to call.';

  @override
  String get verifyOutcomeTitle => 'What did you find out?';

  @override
  String get verifyOutcomeSafe => 'I reached them — it is really them';

  @override
  String get verifyOutcomeUnsure => 'I could not reach them';

  @override
  String get verifyOutcomeImpersonation =>
      'It is not them — someone is pretending';

  @override
  String get verifyOutcomeSafeNote =>
      'Saved. Remember that verifying the person does not make the request itself sensible.';

  @override
  String get verifyOutcomeUnsureNote =>
      'Saved. Not reaching someone is not the same as it being safe — do not send anything yet.';

  @override
  String get verifyOutcomeImpersonationNote =>
      'Saved. Do not send anything, and warn the real person that someone is using their name.';

  @override
  String get verifySaveOutcome => 'Save what I found';

  @override
  String get verifyHistoryTitle => 'Past checks';

  @override
  String get verifyHistoryEmpty => 'No checks recorded yet.';

  @override
  String get verifyOutcomeSafeShort => 'Verified safe';

  @override
  String get verifyOutcomeUnsureShort => 'Could not verify';

  @override
  String get verifyOutcomeImpersonationShort => 'Impersonation';

  @override
  String verifyKnownContactBadge(String name) {
    return 'Saved as $name';
  }

  @override
  String get verifyChooseNumber => 'Which number are you checking?';

  @override
  String get settingsDeleteContacts => 'Delete trusted contacts';

  @override
  String get settingsDeleteContactsBody =>
      'Removes everyone you have saved on this phone.';

  @override
  String get settingsDeleteContactsDone => 'Trusted contacts deleted.';

  @override
  String get settingsDeleteVerifications => 'Delete verification history';

  @override
  String get settingsDeleteVerificationsBody =>
      'Removes the record of numbers you have checked.';

  @override
  String get settingsDeleteVerificationsDone => 'Verification history deleted.';

  @override
  String get screenshotTitle => 'Scan a screenshot';

  @override
  String get screenshotIntro =>
      'Pick a screenshot of the message. The text is read on your phone, and the app\'s copy of the picture is deleted straight afterwards.';

  @override
  String get screenshotChoose => 'Choose a screenshot';

  @override
  String get screenshotChooseAnother => 'Choose a different picture';

  @override
  String get screenshotReading => 'Reading the text…';

  @override
  String get screenshotReviewTitle => 'Check the text';

  @override
  String get screenshotReviewBody =>
      'Reading text from a picture is not perfect. Fix anything that came out wrong before you analyse it.';

  @override
  String get screenshotEmpty =>
      'No text could be read from that picture. Try a clearer screenshot, or type the message instead.';

  @override
  String get screenshotAnalyse => 'Analyse this text';

  @override
  String get screenshotFailed =>
      'The text could not be read. The picture was not saved. You can try another one.';

  @override
  String get screenshotPrivacyNote =>
      'The picture is read on your phone and never uploaded. Your own photo stays in your gallery; only the app\'s copy is deleted.';

  @override
  String get screenshotUnsupported =>
      'That file type is not supported. Use a PNG, JPG or WEBP screenshot.';

  @override
  String get linkCheckTitle => 'Check a link';

  @override
  String get linkCheckIntro =>
      'Paste a link, or the whole message it came in. The link is examined on your phone and never opened.';

  @override
  String get linkCheckHint => 'Paste the link here…';

  @override
  String get linkCheckRun => 'Check the link';

  @override
  String get linkCheckEmptyError => 'Paste a link first.';

  @override
  String get linkCheckInvalid =>
      'That does not look like a web address. Check it and try again.';

  @override
  String get linkCheckTooLong => 'That link is too long to check.';

  @override
  String get linkCheckResultSafeTitle => 'Nothing suspicious found';

  @override
  String get linkCheckResultSafeBody =>
      'This link has none of the warning signs the app knows about. That is not the same as safe — the app cannot see what the page actually does.';

  @override
  String get linkCheckResultWarnTitle => 'This link has warning signs';

  @override
  String get linkCheckResultDangerTitle => 'Do not open this link';

  @override
  String get linkCheckAddress => 'Address';

  @override
  String get linkCheckDomain => 'Real domain';

  @override
  String get linkCheckHttps => 'Secure connection (https)';

  @override
  String get linkCheckHttpsYes => 'Yes';

  @override
  String get linkCheckHttpsNo => 'No';

  @override
  String get linkCheckFindings => 'What we found';

  @override
  String get linkCheckWhatToDo => 'What to do';

  @override
  String get linkCheckAdviceDanger =>
      'Do not open it. If you need the service, type the official address into your browser yourself.';

  @override
  String get linkCheckAdviceWarn =>
      'Be careful. Do not sign in or enter any code or PIN on a page you reached from a message.';

  @override
  String get linkCheckAdviceSafe =>
      'If you were not expecting this link, ask the sender on a number you trust before opening it.';

  @override
  String get linkCheckCopy => 'Copy the link';

  @override
  String get linkCheckCopied => 'Link copied.';

  @override
  String get linkCheckAnother => 'Check another link';

  @override
  String get linkCheckNotOpened => 'Salone Shield never opens links for you.';

  @override
  String linkCheckBrandWarning(String brand) {
    return 'This address is made to look like $brand, but it is not their real website.';
  }

  @override
  String get reportTitle => 'Report a scam';

  @override
  String get reportIntro =>
      'Reporting helps warn other people. Nothing is sent until you have seen exactly what will be shared.';

  @override
  String get reportUnavailableTitle => 'Reporting is not switched on';

  @override
  String get reportUnavailableBody =>
      'This build has no reporting backend configured, so nothing can be submitted. Every other check still works, and still works offline.';

  @override
  String get reportSignInNeeded =>
      'You need an account to report, so that moderators can follow up and so one person cannot flood the system.';

  @override
  String get reportThreatType => 'What kind of scam was it?';

  @override
  String get reportNumber => 'The number that contacted you';

  @override
  String get reportPaymentNumber => 'The number they asked you to pay';

  @override
  String get reportLink => 'A link in the message';

  @override
  String get reportExcerpt => 'A short piece of the message';

  @override
  String get reportExcerptHelp =>
      'Include only the part that shows the scam. Do not paste a whole conversation, and remove anything private about you or anyone else.';

  @override
  String reportExcerptCount(int count, int max) {
    return '$count of $max characters';
  }

  @override
  String get reportDistrict => 'District (optional)';

  @override
  String get reportDistrictHelp =>
      'Helps moderators see where a scam is spreading. Leave it out if you would rather not say.';

  @override
  String get reportWhatIsSent => 'What will be sent';

  @override
  String get reportWhatIsSentBody =>
      'Only the items listed below leave your phone. Phone numbers are turned into a code on our server and stored that way, never as the number itself.';

  @override
  String get reportNothingToSend =>
      'Add at least a number, a link, or a piece of the message.';

  @override
  String get reportConsent =>
      'I understand what will be sent, and I am reporting this honestly.';

  @override
  String get reportConsentRequired =>
      'Tick the box to confirm you have read what will be sent.';

  @override
  String get reportSubmit => 'Send report';

  @override
  String get reportSubmitting => 'Sending…';

  @override
  String get reportSubmittedTitle => 'Report sent';

  @override
  String reportSubmittedBody(String reference) {
    return 'Thank you. A moderator will look at it. Your reference is $reference.';
  }

  @override
  String get reportDuplicateBody =>
      'You already reported this number recently, so your earlier report still stands. There is no need to send it again.';

  @override
  String get reportNotAccusation =>
      'A report is not an accusation. Moderators check reports from several people before anything is marked as verified, and a single report never labels anyone.';

  @override
  String get reportFailedNetwork =>
      'The report could not be sent and nothing was saved. Your report is still on this screen — try again when you have a connection.';

  @override
  String get reportFailedRateLimited =>
      'You have sent several reports in a short time. Please wait a while before sending another.';

  @override
  String get reportFailedSuspended =>
      'This account cannot submit reports at the moment. Contact support if you think that is wrong.';

  @override
  String get reportFailedUnknown =>
      'Something went wrong and nothing was saved. You can try again safely.';

  @override
  String get reportHistoryTitle => 'My reports';

  @override
  String get reportHistoryEmpty => 'You have not sent any reports yet.';

  @override
  String get reportHistoryStatus => 'Status';

  @override
  String get reportStatusPending => 'Waiting for review';

  @override
  String get reportStatusUnderReview => 'Being reviewed';

  @override
  String get reportStatusNeedsEvidence => 'More evidence needed';

  @override
  String get reportStatusVerified => 'Verified';

  @override
  String get reportStatusRejected => 'Not upheld';

  @override
  String get reportStatusDuplicate => 'Already reported';

  @override
  String get reportStatusArchived => 'Closed';

  @override
  String get threatTypeImpersonation =>
      'Someone pretended to be a person I know';

  @override
  String get threatTypeHijackedAccount => 'A friend\'s account was taken over';

  @override
  String get threatTypeFinancialHelpScam =>
      'Asked me for money for an emergency';

  @override
  String get threatTypeVerificationCodeTheft =>
      'Asked me for a verification code';

  @override
  String get threatTypeQrCodeScam => 'Asked me to scan a QR code';

  @override
  String get threatTypeMobileMoneyScam => 'Mobile money scam';

  @override
  String get threatTypeMaliciousLink => 'A dangerous link';

  @override
  String get threatTypeFakeJob => 'A fake job offer';

  @override
  String get threatTypeFakeLoan => 'A fake loan';

  @override
  String get threatTypeFakeInvestment => 'A fake investment';

  @override
  String get threatTypeFakePrize => 'A prize I never entered for';

  @override
  String get threatTypeBlackmail => 'Threats or blackmail';

  @override
  String get threatTypeOther => 'Something else';

  @override
  String get authSignInTitle => 'Sign in';

  @override
  String get authSignUpTitle => 'Create an account';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authPasswordHelp =>
      'At least 8 characters. Do not reuse the password from your email or your bank.';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSignUp => 'Create account';

  @override
  String get authSwitchToSignUp => 'I do not have an account';

  @override
  String get authSwitchToSignIn => 'I already have an account';

  @override
  String get authForgotPassword => 'I forgot my password';

  @override
  String get authResetSent =>
      'If that email has an account, a reset link is on its way.';

  @override
  String get authSignOut => 'Sign out';

  @override
  String get authSignedOut => 'Signed out.';

  @override
  String get authGuestNote =>
      'You do not need an account for anything else. Checking messages, screenshots, links and people all work signed out.';

  @override
  String get authNeverAsksCode =>
      'Salone Shield will never ask for your WhatsApp code or your mobile-money PIN — not on this screen, not anywhere.';

  @override
  String get authErrorInvalid =>
      'That email and password do not match. Check them and try again.';

  @override
  String get authErrorNotConfirmed =>
      'Confirm your email address first. Check your inbox for the link.';

  @override
  String get authErrorAlreadyRegistered =>
      'That email already has an account. Try signing in instead.';

  @override
  String get authErrorWeakPassword =>
      'Choose a longer password — at least 8 characters.';

  @override
  String get authErrorRateLimited =>
      'Too many attempts. Wait a few minutes and try again.';

  @override
  String get authErrorNetwork =>
      'Could not reach the server. Nothing was saved. Try again when you have a connection.';

  @override
  String get authErrorUnknown =>
      'Something went wrong and nothing was saved. You can try again safely.';

  @override
  String get authCheckEmail =>
      'Account created. Check your email for the confirmation link before signing in.';

  @override
  String get homeHeroEyebrow => 'On this phone';

  @override
  String get homeHeroTitle => 'Check before you send';

  @override
  String get homeHeroBody =>
      'Every check runs on this phone. No message has been uploaded.';

  @override
  String homeStatChecks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'checks saved',
      one: 'check saved',
    );
    return '$_temp0';
  }

  @override
  String homeStatContacts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'trusted contacts',
      one: 'trusted contact',
    );
    return '$_temp0';
  }

  @override
  String get homeSectionCheck => 'Check something';

  @override
  String get homeSectionRecent => 'Recent checks';

  @override
  String get navHome => 'Home';

  @override
  String get navReports => 'Reports';

  @override
  String get navContacts => 'Contacts';

  @override
  String get navSettings => 'Settings';

  @override
  String get notificationsTitle => 'Watch for scams as they arrive';

  @override
  String get notificationsIntro =>
      'Salone Shield can read the notifications from your messaging apps and tell you when a message that just arrived matches a known scam pattern.';

  @override
  String get notificationsUnavailableTitle => 'Not available in this build';

  @override
  String get notificationsUnavailableBody =>
      'Notification monitoring is switched off in this build of the app. Everything else works: paste a message, scan a screenshot, or share a message into Salone Shield to check it.';

  @override
  String get notificationsWhatItReads => 'What it reads';

  @override
  String get notificationsWhatItReadsBody =>
      'Only the notifications from the apps you tick below. Nothing from your bank, your email, or any app that sends you a one-time code.';

  @override
  String get notificationsWhereItGoes => 'Where it goes';

  @override
  String get notificationsWhereItGoesBody =>
      'The text is checked on this phone and held in memory for fifteen minutes at most. It is never saved to storage and never uploaded.';

  @override
  String get notificationsWhatYouSee => 'What you will see';

  @override
  String get notificationsWhatYouSeeBody =>
      'If a message looks like a scam, you get a notification saying it is worth checking. The message itself is never repeated in that notification.';

  @override
  String get notificationsNotAccessibility =>
      'Salone Shield cannot see inside WhatsApp. It reads the same notification you see on your lock screen, and nothing more.';

  @override
  String get notificationsAccessTitle => 'Notification access';

  @override
  String get notificationsAccessGranted => 'Granted in Android settings';

  @override
  String get notificationsAccessMissing => 'Not granted yet';

  @override
  String get notificationsAccessAction => 'Open Android settings';

  @override
  String get notificationsAccessUnavailable =>
      'This device has no notification-access screen.';

  @override
  String get notificationsAccessRevokeNote =>
      'You can withdraw this at any time in Android settings, without opening Salone Shield.';

  @override
  String get notificationsSwitchTitle => 'Watch my messages';

  @override
  String get notificationsSwitchBody =>
      'The master switch. Turning it off stops monitoring immediately and forgets anything already seen.';

  @override
  String get notificationsAppsTitle => 'Apps to watch';

  @override
  String get notificationsAppsBody =>
      'Nothing is read until you tick at least one.';

  @override
  String get notificationsStatusActive => 'Watching now';

  @override
  String get notificationsStatusInactive => 'Not watching';

  @override
  String get notificationsPendingTitle => 'Waiting to be checked';

  @override
  String get notificationsPendingEmpty =>
      'Nothing waiting. Messages appear here only when one arrives that is worth a look.';

  @override
  String get notificationsCheckNow => 'Check this message';

  @override
  String get notificationsDismiss => 'Ignore';

  @override
  String get notificationsForgetAll => 'Forget all waiting messages';

  @override
  String get notificationsForgotten => 'Waiting messages have been forgotten.';

  @override
  String notificationsWaitingBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages are waiting to be checked',
      one: '1 message is waiting to be checked',
    );
    return '$_temp0';
  }

  @override
  String get notificationsWaitingAction => 'See them';

  @override
  String get settingsNotifications => 'Watch for scams as they arrive';

  @override
  String get settingsNotificationsBody =>
      'Check messages as your phone receives them';

  @override
  String get settingsDataTitle => 'Your data';
}

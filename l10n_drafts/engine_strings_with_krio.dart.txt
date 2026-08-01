import 'models/risk_level.dart';

/// Text produced by the risk engine itself.
///
/// The engine is pure Dart with no Flutter dependency so it can be unit tested
/// and, later, run in an isolate. It therefore carries its own English and
/// Krio strings rather than reaching into the widget-tree localisations. UI
/// chrome (buttons, titles, labels) is localised normally through ARB files.
abstract final class EngineStrings {
  static const String defaultLanguage = 'en';
  static const List<String> supportedLanguages = ['en', 'kri'];

  static String _pick(Map<String, String> values, String languageCode) =>
      values[languageCode] ?? values[defaultLanguage]!;

  static String summary(String languageCode, RiskLevel level) {
    final text = switch (level) {
      RiskLevel.low => const {
        'en':
            'Nothing in this message matched a known scam pattern. Stay '
            'careful anyway — a clean result is not a guarantee.',
        'kri':
            'Notin na dis message nor match eni scam pattern wey wi no. '
            'Bot stil tek tem — dis nor min se i safe for tru.',
      },
      RiskLevel.caution => const {
        'en':
            'This message has some features scammers use. Check who really '
            'sent it before you do anything they ask.',
        'kri':
            'Dis message get sɔm tin dem wey scammer de yuz. Check udat '
            'sen am fos bifo yu du wetin dem aks.',
      },
      RiskLevel.high => const {
        'en':
            'This looks like a high-risk request. Do not send money or '
            'share anything until you have verified the person yourself.',
        'kri':
            'Dis luk lɛk big risk. Nor sen money en nor share notin te yu '
            'don check di person yusef.',
      },
      RiskLevel.critical => const {
        'en':
            'This has the strongest signs of a scam. Do not send money, '
            'codes, or scan anything. Verify on a number you already trust.',
        'kri':
            'Dis get di stronges sain dem se na scam. Nor sen money, nor '
            'code, en nor scan notin. Check pan nomba wey yu trust.',
      },
    };
    return _pick(text, languageCode);
  }

  static String signalCountLabel(String languageCode, int count) => _pick({
    'en': count == 1 ? '1 warning sign found' : '$count warning signs found',
    'kri': count == 1 ? '1 warnin sain' : '$count warnin sain dem',
  }, languageCode);

  // ---------------------------------------------------------------------
  // Recommended actions
  // ---------------------------------------------------------------------

  static String actionDoNotSendMoney(String languageCode) => _pick(const {
    'en': 'Do not send any money yet.',
    'kri': 'Nor sen eni money yet.',
  }, languageCode);

  static String actionNeverShareCode(String languageCode) => _pick(const {
    'en':
        'Never share a verification code, OTP, or PIN — not even with '
        'family. Salone Shield will never ask for one either.',
    'kri':
        'Nor eva share verification code, OTP or PIN — nɔto ivin to '
        'famili. Salone Shield sef nɔ go eva aks yu fɔ wan.',
  }, languageCode);

  static String actionDoNotScan(String languageCode) => _pick(const {
    'en':
        'Do not scan the QR code. Check WhatsApp > Linked Devices and '
        'remove any device you do not recognise.',
    'kri':
        'Nor scan di QR code. Go na WhatsApp > Linked Devices en rimuv '
        'eni divays wey yu nor no.',
  }, languageCode);

  static String actionCallKnownNumber(String languageCode) => _pick(const {
    'en':
        'Call the person on the number you already have saved — not the '
        'number in this message.',
    'kri':
        'Call di person pan di nomba wey yu don sev — nɔto di nomba na '
        'dis message.',
  }, languageCode);

  static String actionAskPrivateQuestion(String languageCode) => _pick(const {
    'en':
        'Ask something only the real person would know, and wait for the '
        'answer before you act.',
    'kri':
        'Aks am sontin wey na di tru person nɔmɔ go no, en wet fɔ di '
        'ansa bifo yu du enitin.',
  }, languageCode);

  static String actionDoNotOpenLink(String languageCode) => _pick(const {
    'en':
        'Do not open the link. Type the official address yourself if you '
        'really need the service.',
    'kri':
        'Nor opin di link. If yu rili nid di savis, tayp di real adres '
        'yusef.',
  }, languageCode);

  static String actionTellSomeone(String languageCode) => _pick(const {
    'en':
        'Tell one person you trust before you do anything the message '
        'asks for.',
    'kri': 'Tell wan person wey yu trust bifo yu du wetin di message aks.',
  }, languageCode);

  static String actionReport(String languageCode) => _pick(const {
    'en': 'Report this message so other people can be warned.',
    'kri': 'Ripot dis message so dat oda pipul go get warnin.',
  }, languageCode);

  static String actionKeepNormalCaution(String languageCode) => _pick(const {
    'en':
        'No action needed. If this message ever turns into a money or '
        'code request, analyse it again.',
    'kri':
        'Notin fɔ du naw. If dis message kam tɔn to money ɔ code '
        'rikwɛst, analyse am bak.',
  }, languageCode);

  static String actionCheckLinkedDevices(String languageCode) => _pick(const {
    'en':
        'Open WhatsApp > Linked Devices and log out anything you do not '
        'recognise.',
    'kri': 'Opin WhatsApp > Linked Devices en log out enitin wey yu nor no.',
  }, languageCode);

  // ---------------------------------------------------------------------
  // Limitations — what the app could not check
  // ---------------------------------------------------------------------

  static String limitationCannotVerifyIdentity(String languageCode) =>
      _pick(const {
        'en': 'Salone Shield cannot confirm who actually sent this message.',
        'kri': 'Salone Shield nɔ ebul kɔnfam udat rili sen dis message.',
      }, languageCode);

  static String limitationLocalOnly(String languageCode) => _pick(const {
    'en':
        'This check ran only on your phone, using the scam patterns the '
        'app knows today.',
    'kri':
        'Dis chek bin rɔn pan yu fon nɔmɔ, wit di scam pattern dem wey '
        'di app no naw.',
  }, languageCode);

  static String limitationNewScams(String languageCode) => _pick(const {
    'en': 'A new scam the app has not seen before can still look clean.',
    'kri': 'Nyu scam wey di app nɔ si bifo kin stil luk klin.',
  }, languageCode);

  static String limitationLinkNotOpened(String languageCode) => _pick(const {
    'en':
        'Links were examined but never opened, so the app cannot see '
        'what the page actually does.',
    'kri':
        'Wi luk di link dem bot wi nɔ opin dɛm, so di app nɔ no wetin di '
        'page de rili du.',
  }, languageCode);

  static String limitationNumbersUnverified(String languageCode) =>
      _pick(const {
        'en':
            'Numbers found in the message have not been checked against any '
            'operator or mobile-money record.',
        'kri':
            'Di nomba dem wey wi fen na di message, wi nɔ chek dɛm wit eni '
            'operator ɔ mobile money rikɔd.',
      }, languageCode);
}

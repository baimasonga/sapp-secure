/// Normalises message text so that patterns match reliably without letting an
/// attacker slip past the rules with spacing or punctuation tricks.
///
/// Normalisation is deliberately conservative: it must never change the
/// meaning of the message shown back to the user, and the user always sees
/// their own original text — normalisation is used for matching only.
abstract final class TextNormaliser {
  /// Characters people (and scammers) substitute for a plain apostrophe.
  static final RegExp _apostrophes = RegExp('[\\u2018\\u2019\\u02bc\\u00b4`]');

  /// Zero-width and bidirectional characters used to break up keywords.
  static final RegExp _invisible = RegExp(
    '[\\u200b-\\u200f\\u202a-\\u202e\\u2060\\ufeff]',
  );

  /// The various dash characters, normalised to a plain hyphen.
  static final RegExp _dashes = RegExp('[\\u2010-\\u2015]');

  static final RegExp _whitespace = RegExp(r'\s+');

  static String normalise(String input) {
    var text = input.toLowerCase();
    text = text.replaceAll(_invisible, '');
    text = text.replaceAll(_apostrophes, "'");
    text = text.replaceAll(_dashes, '-');
    text = text.replaceAll(_whitespace, ' ');
    return text.trim();
  }
}

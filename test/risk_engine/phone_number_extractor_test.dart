import 'package:flutter_test/flutter_test.dart';
import 'package:salone_shield/services/risk_engine/phone_number_extractor.dart';

void main() {
  List<String> extract(String text) => PhoneNumberExtractor.extract(
    text,
  ).map((number) => number.normalised).toList();

  group('Sierra Leone formats', () {
    test('+232XXXXXXXX is kept as E.164', () {
      expect(extract('Call +23276123456 now'), ['+23276123456']);
    });

    test('232XXXXXXXX gains a plus', () {
      expect(extract('Pay 23276123456'), ['+23276123456']);
    });

    test('0XXXXXXXX is converted to E.164', () {
      expect(extract('My number is 076123456'), ['+23276123456']);
    });

    test('a bare 8-digit national number is converted to E.164', () {
      expect(extract('Send to 76123456'), ['+23276123456']);
    });

    test('spacing, hyphens and brackets are tolerated', () {
      expect(extract('+232 76 123 456'), ['+23276123456']);
      expect(extract('076-123-456'), ['+23276123456']);
      expect(extract('(232) 76 123456'), ['+23276123456']);
    });

    test('the same number written two ways is reported once', () {
      final numbers = extract('076123456 or +232 76 123 456');
      expect(numbers, ['+23276123456']);
    });
  });

  group('international numbers', () {
    test('a foreign number with a plus is preserved, not assumed local', () {
      final results = PhoneNumberExtractor.extract('Ring +442071838750');
      expect(results.single.normalised, '+442071838750');
      expect(results.single.isSierraLeone, isFalse);
      expect(results.single.isNormalisedToE164, isTrue);
    });

    test('an over-long digit run is rejected', () {
      expect(extract('+1234567890123456789'), isEmpty);
    });
  });

  group('false positives', () {
    test('money amounts are not phone numbers', () {
      expect(extract('Please send Le 2,000 today'), isEmpty);
      expect(extract('It costs Le 2000000'), isEmpty);
    });

    test('short digit runs are ignored', () {
      expect(extract('The code is 123456'), isEmpty);
      expect(extract('Meet me at 5pm on 12/09/2026'), isEmpty);
    });

    test('text without digits yields nothing', () {
      expect(extract('Good morning my brother'), isEmpty);
    });
  });

  group('presentation and comparison', () {
    test('masking hides the middle of the number', () {
      final number = PhoneNumberExtractor.normaliseSingle('+23276123456')!;
      expect(number.masked, isNot(contains('76123')));
      expect(number.masked, endsWith('456'));
    });

    test('the raw form is preserved so the user recognises it', () {
      final results = PhoneNumberExtractor.extract('pay 076 123 456 now');
      expect(results.single.raw.trim(), '076 123 456');
    });

    test('numbers written differently compare equal after normalisation', () {
      final fromMessage = PhoneNumberExtractor.extract('076123456').single;
      final saved = PhoneNumberExtractor.normaliseSingle('+232 76 123 456')!;
      expect(fromMessage.normalised, saved.normalised);
      expect(fromMessage, saved);
    });

    test('normaliseSingle rejects empty and junk input', () {
      expect(PhoneNumberExtractor.normaliseSingle('   '), isNull);
      expect(PhoneNumberExtractor.normaliseSingle('abc'), isNull);
    });
  });
}

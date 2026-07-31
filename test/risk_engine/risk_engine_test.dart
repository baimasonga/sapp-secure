import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:salone_shield/services/risk_engine/models/risk_assessment.dart';
import 'package:salone_shield/services/risk_engine/models/risk_level.dart';
import 'package:salone_shield/services/risk_engine/risk_engine.dart';

/// Loads the shipped rules straight from disk so the tests exercise the same
/// data the application ships, not a hand-written fixture that can drift.
RiskEngine loadShippedEngine() => RiskEngine.fromJsonString(
  File('assets/scam_rules/initial_rules.json').readAsStringSync(),
);

void main() {
  late RiskEngine engine;

  setUp(() => engine = loadShippedEngine());

  group('rule set integrity', () {
    test('every shipped rule has a weight, an explanation and advice', () {
      expect(engine.rules, isNotEmpty);
      for (final rule in engine.rules) {
        expect(rule.weight, inInclusiveRange(0, 100), reason: rule.id);
        for (final language in ['en', 'kri']) {
          expect(
            rule.explanation(language),
            isNotEmpty,
            reason: '${rule.id} explanation.$language',
          );
          expect(
            rule.advice(language),
            isNotEmpty,
            reason: '${rule.id} advice.$language',
          );
        }
      }
    });

    test(
      'pattern rules ship at least one pattern, derived rules ship none',
      () {
        for (final rule in engine.rules) {
          if (rule.derived) {
            expect(rule.patterns, isEmpty, reason: rule.id);
          } else {
            expect(rule.patterns, isNotEmpty, reason: rule.id);
          }
        }
      },
    );

    test('duplicate rule ids are rejected', () {
      expect(
        () => RiskEngine.fromJsonString('''
          {"rules":[
            {"id":"a","category":"payment","weight":10,"patterns":["x"]},
            {"id":"a","category":"payment","weight":10,"patterns":["y"]}
          ]}
        '''),
        throwsA(isA<FormatException>()),
      );
    });

    test('an invalid weight is rejected rather than silently ignored', () {
      expect(
        () => RiskEngine.fromJsonString(
          '{"rules":[{"id":"a","category":"payment","weight":900}]}',
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('specification test messages (section 36)', () {
    test('test 1 — verification-code scam is critical', () {
      final result = engine.analyse(
        'I mistakenly sent a six digit code to your phone. '
        'Please send it to me urgently.',
      );

      expect(result.level, RiskLevel.critical);
      expect(result.ruleIds, contains('verification_code_request'));
      expect(result.ruleIds, contains('urgency'));
      expect(
        result.recommendedActions.join(' ').toLowerCase(),
        contains('never share'),
      );
    });

    test('test 2 — new-number money request is high or critical', () {
      final result = engine.analyse(
        'Hello, this is Mohamed. I lost my old phone. Save this new number. '
        'I need you to send Le 2,000 urgently to this Orange Money number.',
      );

      expect(result.score, greaterThanOrEqualTo(RiskLevel.high.minScore));
      expect(result.ruleIds, contains('new_number_claim'));
      expect(result.ruleIds, contains('financial_request'));
      expect(result.ruleIds, contains('urgency'));
    });

    test('test 3 — third-party payment with refusal to call is high risk', () {
      final result = engine.analyse(
        "Please send the money to my brother's Afrimoney number because my "
        'account is not working. Do not call now, I am in a meeting.',
      );

      expect(result.level, RiskLevel.high);
      expect(result.ruleIds, contains('financial_request'));
      expect(result.ruleIds, contains('third_party_payment'));
      expect(result.ruleIds, contains('refusal_to_call'));
    });

    test('test 4 — an ordinary message stays low', () {
      final result = engine.analyse(
        'Can you call me when you are free? I need to discuss something '
        'important.',
      );

      expect(result.level, RiskLevel.low);
      expect(result.ruleIds, isNot(contains('financial_request')));
      expect(result.ruleIds, isNot(contains('verification_code_request')));
      expect(result.recommendedActions, isNotEmpty);
    });

    test('test 5 — Krio scam pattern is detected', () {
      final result = engine.analyse(
        'Dis na mi new nomba. Nor call now. A need yu for send money quick '
        'pan Orange Money.',
        languageCode: 'kri',
      );

      expect(result.score, greaterThanOrEqualTo(RiskLevel.high.minScore));
      expect(result.ruleIds, contains('new_number_claim'));
      expect(result.ruleIds, contains('refusal_to_call'));
      expect(result.ruleIds, contains('financial_request'));
    });
  });

  group('scoring', () {
    test('an empty message scores zero and is low risk', () {
      final result = engine.analyse('');
      expect(result.score, 0);
      expect(result.level, RiskLevel.low);
      expect(result.signals, isEmpty);
    });

    test('the score is clamped to 100', () {
      final result = engine.analyse(
        'Send me the verification code urgently, scan this QR to link your '
        'whatsapp, do not call, do not tell anyone, this is my new number, '
        'send money to my brother\'s number, you have won, guaranteed profit, '
        'double your money, processing fee, i will expose you, '
        'recover my account. http://192.168.1.5/whatsapp-verify.apk',
      );
      expect(result.score, 100);
      expect(result.level, RiskLevel.critical);
    });

    test('score always equals the sum of signal weights, or the floor', () {
      const messages = [
        'send me money urgently',
        'this is my new number, do not call',
        'you have won a cash prize, pay the processing fee',
        'nothing suspicious here at all',
      ];
      for (final message in messages) {
        final result = engine.analyse(message);
        final sum = result.signals.fold<int>(0, (a, s) => a + s.weight);
        expect(result.score, sum.clamp(0, 100), reason: message);
      }
    });

    test('a verification-code request alone is escalated to critical', () {
      // 35 points on weights alone would only be "Caution". A single request
      // for a code is decisive, so the engine applies an escalation floor.
      final result = engine.analyse('please send the code');
      expect(result.signals.map((s) => s.ruleId), [
        'verification_code_request',
      ]);
      expect(result.level, RiskLevel.critical);
    });

    test('risk levels follow the documented thresholds', () {
      expect(RiskLevel.fromScore(0), RiskLevel.low);
      expect(RiskLevel.fromScore(24), RiskLevel.low);
      expect(RiskLevel.fromScore(25), RiskLevel.caution);
      expect(RiskLevel.fromScore(49), RiskLevel.caution);
      expect(RiskLevel.fromScore(50), RiskLevel.high);
      expect(RiskLevel.fromScore(74), RiskLevel.high);
      expect(RiskLevel.fromScore(75), RiskLevel.critical);
      expect(RiskLevel.fromScore(100), RiskLevel.critical);
    });
  });

  group('explainability (section 9.5)', () {
    test('every signal carries an explanation, advice and a confidence', () {
      final result = engine.analyse(
        'This is my new number, send money urgently to my brother\'s number.',
      );
      expect(result.signals, isNotEmpty);
      for (final signal in result.signals) {
        expect(signal.explanation, isNotEmpty);
        expect(signal.advice, isNotEmpty);
        expect(signal.confidence, inInclusiveRange(0.0, 1.0));
        expect(signal.matchedText, isNotNull);
      }
    });

    test('a low-risk result still states what could not be checked', () {
      final result = engine.analyse('Good morning, see you at church.');
      expect(result.level, RiskLevel.low);
      expect(result.limitations, isNotEmpty);
      expect(result.recommendedActions, isNotEmpty);
    });

    test('results are localised into Krio', () {
      final english = engine.analyse('send me money urgently');
      final krio = engine.analyse(
        'send me money urgently',
        languageCode: 'kri',
      );
      expect(krio.score, english.score);
      expect(krio.summary, isNot(english.summary));
      expect(
        krio.signals.first.explanation,
        isNot(english.signals.first.explanation),
      );
    });

    test('an unknown language falls back to English rather than failing', () {
      final result = engine.analyse('send me money', languageCode: 'zz');
      expect(result.signals.first.explanation, isNotEmpty);
      expect(result.summary, isNotEmpty);
    });

    test('the same input always produces the same score', () {
      const message = 'Send the OTP now, this is my new number.';
      final first = engine.analyse(message);
      final second = engine.analyse(message);
      expect(second.score, first.score);
      expect(second.ruleIds, first.ruleIds);
    });
  });

  group('context signals', () {
    test('an unknown sender adds the unverified-sender signal', () {
      final result = engine.analyse(
        'Good morning',
        context: const AnalysisContext(
          senderNumber: '+23276123456',
          trustedNumbersE164: {'+23277000000'},
        ),
      );
      expect(result.ruleIds, contains('unverified_sender'));
    });

    test('a trusted sender does not add the unverified-sender signal', () {
      final result = engine.analyse(
        'Good morning',
        context: const AnalysisContext(
          senderNumber: '076123456',
          trustedNumbersE164: {'+23276123456'},
        ),
      );
      expect(result.ruleIds, isNot(contains('unverified_sender')));
      expect(result.score, 0);
    });

    test('a number reported by the community raises the score', () {
      const message = 'Please pay 076123456 today.';
      final withoutCache = engine.analyse(message);
      final withCache = engine.analyse(
        message,
        context: const AnalysisContext(reportedIndicators: {'+23276123456'}),
      );
      expect(withCache.ruleIds, contains('reported_indicator'));
      expect(withCache.score, greaterThan(withoutCache.score));
    });
  });

  group('robustness', () {
    test('oversized input is truncated instead of hanging', () {
      final huge = 'send me money. ' * 20000;
      final stopwatch = Stopwatch()..start();
      final result = engine.analyse(huge);
      stopwatch.stop();
      expect(result.score, greaterThan(0));
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
    });

    test('zero-width characters cannot hide a keyword', () {
      final result = engine.analyse('send mon​ey urgently');
      expect(result.ruleIds, contains('financial_request'));
    });

    test('curly apostrophes still match', () {
      final result = engine.analyse('Please don’t call me about this');
      expect(result.ruleIds, contains('refusal_to_call'));
    });

    test('a keyword inside a longer word does not trigger a rule', () {
      final result = engine.analyse(
        'The insurgent group met at the urgency '
        'clinic',
      );
      expect(
        result.ruleIds,
        isNot(contains('urgency')),
        reason: '"insurgent" must not match "urgent"',
      );
    });

    test('metadata export contains no message content', () {
      final result = engine.analyse('send me money to 076123456 urgently');
      final json = result.toMetadataJson().toString();
      expect(json, isNot(contains('076123456')));
      expect(json, isNot(contains('send me money')));
      expect(json, contains('financial_request'));
    });
  });
}

extension on RiskAssessment {
  /// Convenience for asserting on which rules fired.
  List<String> get ruleIds =>
      signals.map((signal) => signal.ruleId).toList(growable: false);
}

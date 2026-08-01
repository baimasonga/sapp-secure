import 'package:flutter_test/flutter_test.dart';
import 'package:salone_shield/features/threat_reporting/domain/threat_report.dart';

void main() {
  ReportDraft draft({
    String? number,
    String? payment,
    String? link,
    String? excerpt,
    String? district,
    bool consent = true,
  }) => ReportDraft(
    threatType: ThreatType.impersonation,
    reportedNumber: number,
    paymentNumber: payment,
    reportedLink: link,
    messageExcerpt: excerpt,
    district: district,
    consentConfirmed: consent,
  );

  group('validation', () {
    test('a report without consent is refused', () {
      final errors = draft(number: '076123456', consent: false).validate();
      expect(errors, contains(ReportValidationError.consentRequired));
    });

    test('a report with nothing in it is refused', () {
      expect(
        draft().validate(),
        contains(ReportValidationError.nothingToReport),
      );
    });

    test('whitespace does not count as content', () {
      expect(
        draft(number: '   ', link: '  ').validate(),
        contains(ReportValidationError.nothingToReport),
      );
    });

    test('any one of number, payment number or link is enough', () {
      expect(draft(number: '076123456').isValid, isTrue);
      expect(draft(payment: '076123456').isValid, isTrue);
      expect(draft(link: 'https://claim-now.tk').isValid, isTrue);
    });

    test('an over-long excerpt is refused', () {
      final errors = draft(
        number: '076123456',
        excerpt: 'a' * (ReportDraft.maxExcerptLength + 1),
      ).validate();
      expect(errors, contains(ReportValidationError.excerptTooLong));
    });

    test('an excerpt at the limit is accepted', () {
      expect(
        draft(
          number: '076123456',
          excerpt: 'a' * ReportDraft.maxExcerptLength,
        ).isValid,
        isTrue,
      );
    });
  });

  group('what actually gets sent', () {
    test('empty fields are omitted entirely, not sent as blanks', () {
      final submission = draft(number: '076123456').toSubmission();

      expect(submission.containsKey('reported_number'), isTrue);
      expect(submission.containsKey('payment_number'), isFalse);
      expect(submission.containsKey('reported_link'), isFalse);
      expect(submission.containsKey('message_excerpt'), isFalse);
      expect(submission.containsKey('district'), isFalse);
    });

    test('values are trimmed', () {
      final submission = draft(number: '  076123456  ').toSubmission();
      expect(submission['reported_number'], '076123456');
    });

    test('only rule ids travel, never message text', () {
      const withSignals = ReportDraft(
        threatType: ThreatType.verificationCodeTheft,
        reportedNumber: '076123456',
        riskSignals: ['verification_code_request', 'urgency'],
        consentConfirmed: true,
      );

      final submission = withSignals.toSubmission();
      expect(submission['risk_signals'], [
        'verification_code_request',
        'urgency',
      ]);
      expect(submission.toString(), isNot(contains('send me the code')));
    });

    test('consent travels with the report so the server can check it too', () {
      expect(
        draft(number: '076123456').toSubmission()['consent_confirmed'],
        isTrue,
      );
      expect(
        draft(
          number: '076123456',
          consent: false,
        ).toSubmission()['consent_confirmed'],
        isFalse,
      );
    });

    test('the threat type is sent as its stable id', () {
      const report = ReportDraft(
        threatType: ThreatType.qrCodeScam,
        reportedLink: 'https://x.tk',
        consentConfirmed: true,
      );
      expect(report.toSubmission()['threat_type'], 'qr_code_scam');
    });
  });

  group('identifiers', () {
    test('every threat type has a unique, stable id', () {
      final ids = ThreatType.values.map((type) => type.id).toSet();
      expect(ids, hasLength(ThreatType.values.length));
      // These strings are also a database constraint; changing one silently
      // would start rejecting reports.
      expect(ThreatType.fromId('impersonation'), ThreatType.impersonation);
      expect(ThreatType.fromId('nonsense'), isNull);
    });

    test('every report status has a unique id and a safe fallback', () {
      final ids = ReportStatus.values.map((status) => status.id).toSet();
      expect(ids, hasLength(ReportStatus.values.length));
      // An unknown status from a newer server must not read as "verified".
      expect(ReportStatus.fromId('something_new'), ReportStatus.pending);
    });
  });

  group('reading a report back', () {
    test('parses a server row', () {
      final report = SubmittedReport.tryFromJson({
        'id': 'r1',
        'threat_type': 'mobile_money_scam',
        'status': 'under_review',
        'created_at': '2026-08-01T10:00:00Z',
      })!;

      expect(report.threatType, ThreatType.mobileMoneyScam);
      expect(report.status, ReportStatus.underReview);
    });

    test('a row with no recognisable type is dropped, not guessed', () {
      expect(
        SubmittedReport.tryFromJson({'id': 'r1', 'threat_type': 'unknown'}),
        isNull,
      );
    });
  });
}

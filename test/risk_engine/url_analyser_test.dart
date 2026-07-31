import 'package:flutter_test/flutter_test.dart';
import 'package:salone_shield/services/risk_engine/url_analyser.dart';

void main() {
  group('extraction', () {
    test('finds links with and without a scheme', () {
      expect(UrlAnalyser.extractUrls('Go to https://example.com/win now'), [
        'https://example.com/win',
      ]);
      expect(UrlAnalyser.extractUrls('visit www.example.com'), [
        'www.example.com',
      ]);
      expect(UrlAnalyser.extractUrls('open example.com today'), [
        'example.com',
      ]);
    });

    test('drops trailing sentence punctuation', () {
      expect(UrlAnalyser.extractUrls('see https://example.com/page.'), [
        'https://example.com/page',
      ]);
      expect(UrlAnalyser.extractUrls('(https://example.com)'), [
        'https://example.com',
      ]);
    });

    test('ordinary sentences are not turned into links', () {
      expect(UrlAnalyser.extractUrls('Hello. How are you today.'), isEmpty);
      expect(UrlAnalyser.extractUrls('I will be there at 5.30'), isEmpty);
    });

    test('the same link twice is reported once', () {
      expect(UrlAnalyser.extractUrls('example.com and again EXAMPLE.COM'), [
        'example.com',
      ]);
    });
  });

  group('local safety checks (section 12)', () {
    test('an IP-address host is flagged', () {
      final analysis = UrlAnalyser.analyse('http://192.168.10.4/login');
      expect(analysis.findings, contains(UrlFinding.ipAddressHost));
      expect(analysis.isHighlySuspicious, isTrue);
    });

    test('explicit http is flagged as missing HTTPS', () {
      expect(
        UrlAnalyser.analyse('http://example.com').findings,
        contains(UrlFinding.noHttps),
      );
    });

    test('a scheme-less link is not accused of missing HTTPS', () {
      expect(
        UrlAnalyser.analyse('example.com').findings,
        isNot(contains(UrlFinding.noHttps)),
      );
    });

    test('punycode is flagged', () {
      expect(
        UrlAnalyser.analyse('https://xn--whatspp-8za.com').findings,
        contains(UrlFinding.punycode),
      );
    });

    test('embedded credentials are flagged', () {
      expect(
        UrlAnalyser.analyse('https://user:pass@example.com').findings,
        contains(UrlFinding.embeddedCredentials),
      );
    });

    test('a non-standard port is flagged', () {
      expect(
        UrlAnalyser.analyse('https://example.com:8443/x').findings,
        contains(UrlFinding.nonStandardPort),
      );
    });

    test('excessive subdomains are flagged', () {
      expect(
        UrlAnalyser.analyse(
          'https://secure.login.verify.account.example.com',
        ).findings,
        contains(UrlFinding.excessiveSubdomains),
      );
    });

    test('URL shorteners are flagged', () {
      expect(
        UrlAnalyser.analyse('https://bit.ly/3xyz').findings,
        contains(UrlFinding.urlShortener),
      );
    });

    test('an encoded redirect is flagged', () {
      expect(
        UrlAnalyser.analyse(
          'https://example.com/go?url=https%3A%2F%2Fevil.tk',
        ).findings,
        contains(UrlFinding.encodedRedirect),
      );
    });

    test('an APK download link is flagged', () {
      expect(
        UrlAnalyser.analyse('https://example.com/whatsapp.apk').findings,
        contains(UrlFinding.executableDownload),
      );
    });

    test('a free abused TLD is flagged', () {
      expect(
        UrlAnalyser.analyse('https://claim-now.tk').findings,
        contains(UrlFinding.suspiciousTld),
      );
    });
  });

  group('brand impersonation', () {
    test('a WhatsApp lookalike host is flagged', () {
      final analysis = UrlAnalyser.analyse('https://whatsapp-verify.tk/login');
      expect(analysis.findings, contains(UrlFinding.brandLookalike));
      expect(analysis.impersonatedBrand, 'whatsapp');
    });

    test('an Orange Money lookalike host is flagged', () {
      expect(
        UrlAnalyser.analyse('https://orangemoney-sl-bonus.xyz').findings,
        contains(UrlFinding.brandLookalike),
      );
    });

    test('the genuine domain is not flagged as a lookalike', () {
      for (final url in [
        'https://www.whatsapp.com/download',
        'https://faq.whatsapp.com',
        'https://wa.me/23276123456',
        'https://africell.sl',
      ]) {
        final analysis = UrlAnalyser.analyse(url);
        expect(
          analysis.findings,
          isNot(contains(UrlFinding.brandLookalike)),
          reason: url,
        );
        expect(analysis.impersonatedBrand, isNull, reason: url);
      }
    });
  });

  group('display mismatch', () {
    test('visible text pointing elsewhere than the real link is caught', () {
      expect(
        UrlAnalyser.isDisplayMismatch(
          displayText: 'Log in at www.whatsapp.com',
          actualUrl: 'https://whatsapp-secure.tk/login',
        ),
        isTrue,
      );
    });

    test('matching display text and destination is not a mismatch', () {
      expect(
        UrlAnalyser.isDisplayMismatch(
          displayText: 'Log in at www.whatsapp.com',
          actualUrl: 'https://www.whatsapp.com/login',
        ),
        isFalse,
      );
    });
  });

  group('robustness', () {
    test('an unparseable link degrades safely instead of throwing', () {
      final analysis = UrlAnalyser.analyse('http://');
      expect(analysis.host, isEmpty);
      expect(analysis.isSuspicious, isTrue);
    });

    test('a plain safe link produces no findings', () {
      final analysis = UrlAnalyser.analyse('https://www.gov.sl/news');
      expect(analysis.findings, isEmpty);
      expect(analysis.isSuspicious, isFalse);
    });
  });
}

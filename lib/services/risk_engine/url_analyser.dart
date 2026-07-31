import 'models/text_normaliser.dart';

/// A named reason why a link looks dangerous.
///
/// Findings are never phrased as proof that a site is criminal — they describe
/// an observable property of the link and why it matters.
enum UrlFinding {
  noHttps,
  ipAddressHost,
  punycode,
  excessiveSubdomains,
  brandLookalike,
  urlShortener,
  embeddedCredentials,
  nonStandardPort,
  encodedRedirect,
  suspiciousTld,
  executableDownload,
  displayMismatch,
}

/// The outcome of analysing one link, entirely on the device.
class UrlAnalysis {
  const UrlAnalysis({
    required this.original,
    required this.normalised,
    required this.host,
    required this.isHttps,
    required this.findings,
    this.impersonatedBrand,
  });

  final String original;
  final String normalised;
  final String host;
  final bool isHttps;
  final List<UrlFinding> findings;

  /// Set when the host looks like a well-known brand without being it.
  final String? impersonatedBrand;

  bool get isSuspicious => findings.isNotEmpty;

  /// Findings that on their own justify telling the user not to open the link.
  static const Set<UrlFinding> _severe = {
    UrlFinding.ipAddressHost,
    UrlFinding.punycode,
    UrlFinding.brandLookalike,
    UrlFinding.embeddedCredentials,
    UrlFinding.executableDownload,
    UrlFinding.displayMismatch,
  };

  bool get isHighlySuspicious => findings.any(_severe.contains);
}

/// Local, offline link-safety checks.
///
/// No part of the message is ever sent to a third party here. External
/// reputation lookups are a separate, optional, opt-in feature.
abstract final class UrlAnalyser {
  /// Matches links with a scheme, protocol-relative links, and bare hosts that
  /// look like domains. Kept deliberately tight so ordinary sentences with
  /// full stops are not turned into links.
  static final RegExp _urlPattern = RegExp(
    r'\b(?:(?:https?|ftp):\/\/|www\.)[^\s<>"'
    r"'"
    r']+'
    r'|\b[a-z0-9](?:[a-z0-9-]*[a-z0-9])?(?:\.[a-z0-9-]+)*'
    r'\.(?:com|net|org|info|biz|xyz|top|online|site|club|shop|link|live|app|io|co|me|ru|cn|tk|ml|ga|cf|gq|sl|ng|gh|uk|us|ws|icu|cc|pw|sbs|cyou|rest|fit|monster)'
    r'(?:\/[^\s<>"'
    r"'"
    r']*)?\b',
    caseSensitive: false,
  );

  static const Set<String> _shorteners = {
    'bit.ly',
    'tinyurl.com',
    'goo.gl',
    't.co',
    'ow.ly',
    'is.gd',
    'buff.ly',
    'cutt.ly',
    'rb.gy',
    'shorturl.at',
    'rebrand.ly',
    'bl.ink',
    's.id',
    'tiny.cc',
    'x.co',
    'lnkd.in',
    'wa.link',
  };

  /// Free or heavily abused top-level domains.
  static const Set<String> _riskyTlds = {
    'tk',
    'ml',
    'ga',
    'cf',
    'gq',
    'xyz',
    'top',
    'icu',
    'sbs',
    'cyou',
    'rest',
    'monster',
    'fit',
    'pw',
  };

  /// Brands impersonated against Sierra Leonean users, with the domains that
  /// legitimately own them.
  static const Map<String, List<String>> _protectedBrands = {
    'whatsapp': ['whatsapp.com', 'whatsapp.net', 'wa.me'],
    'orangemoney': ['orange.com', 'orange.sl'],
    'orange': ['orange.com', 'orange.sl'],
    'afrimoney': ['africell.sl', 'afrimoney.africell.sl'],
    'africell': ['africell.sl'],
    'facebook': ['facebook.com', 'fb.com'],
    'meta': ['meta.com'],
    'google': ['google.com'],
    'ecobank': ['ecobank.com'],
    'unionbank': ['unionbank.sl'],
    'rokel': ['rokelbank.sl'],
  };

  static const Set<String> _executableExtensions = {
    '.apk',
    '.exe',
    '.scr',
    '.bat',
    '.msi',
    '.jar',
  };

  /// Extracts every distinct link from free text, preserving order.
  static List<String> extractUrls(String text) {
    final results = <String>[];
    final seen = <String>{};
    for (final match in _urlPattern.allMatches(text)) {
      var candidate = match.group(0)!;
      // Trailing sentence punctuation is part of the sentence, not the link.
      candidate = candidate.replaceFirst(RegExp(r'[.,;:!?)\]]+$'), '');
      if (candidate.isEmpty) continue;
      if (seen.add(candidate.toLowerCase())) results.add(candidate);
    }
    return results;
  }

  /// Runs every local check against a single link.
  static UrlAnalysis analyse(String rawUrl) {
    final trimmed = rawUrl.trim();
    final withScheme =
        RegExp(
          r'^[a-z][a-z0-9+.\-]*:\/\/',
          caseSensitive: false,
        ).hasMatch(trimmed)
        ? trimmed
        : 'http://$trimmed';

    final uri = Uri.tryParse(withScheme);
    if (uri == null || uri.host.isEmpty) {
      return UrlAnalysis(
        original: rawUrl,
        normalised: trimmed,
        host: '',
        isHttps: false,
        findings: const [UrlFinding.noHttps],
      );
    }

    final host = uri.host.toLowerCase();
    final findings = <UrlFinding>[];
    final hadExplicitScheme = trimmed == withScheme;
    final isHttps = uri.scheme == 'https';

    // A link written without any scheme is not itself evidence of phishing,
    // so only flag missing HTTPS when the sender chose http:// explicitly.
    if (!isHttps && hadExplicitScheme) findings.add(UrlFinding.noHttps);

    if (_isIpAddress(host)) findings.add(UrlFinding.ipAddressHost);
    if (host.contains('xn--')) findings.add(UrlFinding.punycode);
    if (uri.userInfo.isNotEmpty) findings.add(UrlFinding.embeddedCredentials);
    if (uri.hasPort && uri.port != 80 && uri.port != 443) {
      findings.add(UrlFinding.nonStandardPort);
    }

    final labels = host.split('.');
    if (labels.length > 4) findings.add(UrlFinding.excessiveSubdomains);
    if (_shorteners.contains(host) || _shorteners.contains(_stripWww(host))) {
      findings.add(UrlFinding.urlShortener);
    }
    if (labels.length > 1 && _riskyTlds.contains(labels.last)) {
      findings.add(UrlFinding.suspiciousTld);
    }

    final path = uri.path.toLowerCase();
    if (_executableExtensions.any(path.endsWith)) {
      findings.add(UrlFinding.executableDownload);
    }

    if (_hasEncodedRedirect(uri)) findings.add(UrlFinding.encodedRedirect);

    final brand = _lookalikeBrand(host);
    if (brand != null) findings.add(UrlFinding.brandLookalike);

    return UrlAnalysis(
      original: rawUrl,
      normalised: uri.toString(),
      host: host,
      isHttps: isHttps,
      findings: findings,
      impersonatedBrand: brand,
    );
  }

  /// Detects the classic `Click <b>www.bank.com</b>` trick where the visible
  /// text and the real destination disagree.
  static bool isDisplayMismatch({
    required String displayText,
    required String actualUrl,
  }) {
    final displayed = extractUrls(TextNormaliser.normalise(displayText));
    if (displayed.isEmpty) return false;
    final actualHost = analyse(actualUrl).host;
    return displayed
        .map((url) => analyse(url).host)
        .where((host) => host.isNotEmpty)
        .any(
          (host) => _registrableDomain(host) != _registrableDomain(actualHost),
        );
  }

  static bool _isIpAddress(String host) =>
      RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host) ||
      (host.startsWith('[') && host.endsWith(']'));

  static String _stripWww(String host) =>
      host.startsWith('www.') ? host.substring(4) : host;

  static bool _hasEncodedRedirect(Uri uri) {
    final query = uri.query.toLowerCase();
    if (query.isEmpty) return false;
    const redirectKeys = [
      'url=',
      'redirect=',
      'next=',
      'target=',
      'goto=',
      'r=',
    ];
    final hasRedirectKey = redirectKeys.any(query.contains);
    final hasEncodedScheme =
        query.contains('http%3a') || query.contains('https%3a');
    return (hasRedirectKey && query.contains('http')) || hasEncodedScheme;
  }

  /// Returns the brand a host is imitating, or null when the host is either
  /// unrelated to a protected brand or is the brand's real domain.
  static String? _lookalikeBrand(String host) {
    final registrable = _registrableDomain(host);
    for (final entry in _protectedBrands.entries) {
      final brand = entry.key;
      final legitimateDomains = entry.value;
      if (legitimateDomains.any(
        (domain) =>
            registrable == domain ||
            host == domain ||
            host.endsWith('.$domain'),
      )) {
        return null; // The real thing, or a genuine subdomain of it.
      }
      if (host.replaceAll(RegExp(r'[^a-z0-9]'), '').contains(brand)) {
        return brand;
      }
    }
    return null;
  }

  /// Best-effort registrable domain. This is not a public-suffix list; it is
  /// only used for comparison, never for a trust decision on its own.
  static String _registrableDomain(String host) {
    final labels = host.split('.');
    if (labels.length <= 2) return host;
    return labels.sublist(labels.length - 2).join('.');
  }
}

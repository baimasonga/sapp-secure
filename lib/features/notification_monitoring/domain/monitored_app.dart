/// The messaging apps Salone Shield can read notifications from.
///
/// The list is closed on purpose, and it is the same list the Kotlin service
/// enforces (`SupportedApps.kt`). An app that is not here cannot be monitored
/// even by mistake — which is what keeps one-time codes from banks, e-mail
/// clients and authenticators out of the app's reach entirely.
enum MonitoredApp {
  whatsApp('com.whatsapp', 'WhatsApp'),
  whatsAppBusiness('com.whatsapp.w4b', 'WhatsApp Business');

  const MonitoredApp(this.packageName, this.displayName);

  final String packageName;

  /// A product name, not a translated string: these are what the icons on the
  /// user's home screen say, in every language.
  final String displayName;
}

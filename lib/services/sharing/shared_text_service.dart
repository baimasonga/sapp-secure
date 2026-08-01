import 'package:flutter/services.dart';

/// Dart side of the share-to-Salone-Shield channel (section 6.2).
///
/// The user selects a message in WhatsApp, taps Share, and picks Salone
/// Shield. The text arrives here, is analysed locally, and is never persisted.
class SharedTextService {
  const SharedTextService({this.channel = defaultChannel});

  static const MethodChannel defaultChannel = MethodChannel(
    'com.gsit.saloneshield/shared_text',
  );

  static const String methodGetSharedText = 'getSharedText';
  static const String methodOnSharedText = 'onSharedText';

  /// Overridden in tests; the app uses [defaultChannel].
  final MethodChannel channel;

  /// Text from the share that launched the app, if any. Returns null on any
  /// platform where the channel is not implemented, so the app still runs.
  Future<String?> initialSharedText() async {
    try {
      final text = await channel.invokeMethod<String>(methodGetSharedText);
      return _clean(text);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// Called for shares that arrive while the app is already open.
  void listen(void Function(String text) onSharedText) {
    channel.setMethodCallHandler((call) async {
      if (call.method != methodOnSharedText) return null;
      final text = _clean(
        call.arguments is String ? call.arguments as String : null,
      );
      if (text != null) onSharedText(text);
      return null;
    });
  }

  void dispose() => channel.setMethodCallHandler(null);

  static String? _clean(String? text) {
    if (text == null) return null;
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

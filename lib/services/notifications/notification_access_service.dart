import 'package:flutter/services.dart';

/// A message the notification listener saw, on its way to the analyser.
///
/// This object is short-lived by design: it exists between the listener and
/// the risk engine and is never written anywhere.
class MonitoredMessage {
  const MonitoredMessage({
    required this.id,
    required this.packageName,
    required this.text,
    required this.receivedAt,
    required this.interrupt,
  });

  final int id;
  final String packageName;
  final String text;
  final DateTime receivedAt;

  /// True when the native filter judged this worth a notification. The score
  /// and the reasons still come from the engine, not from this flag.
  final bool interrupt;

  static MonitoredMessage? fromMap(Object? value) {
    if (value is! Map) return null;
    final text = value['text'];
    if (text is! String || text.trim().isEmpty) return null;
    final millis = value['received_at'];
    return MonitoredMessage(
      id: value['id'] is int ? value['id'] as int : 0,
      packageName: value['package'] is String ? value['package'] as String : '',
      text: text,
      receivedAt: millis is int
          ? DateTime.fromMillisecondsSinceEpoch(millis)
          : DateTime.now(),
      interrupt: value['interrupt'] == true,
    );
  }
}

/// Dart side of notification monitoring (specification section 14).
///
/// Every method here fails soft. Notification access is something the user
/// grants in Android's settings and can withdraw there without telling the
/// app, and on any other platform the channel does not exist at all — so a
/// missing implementation must read as "not available", never as an error the
/// user has to deal with.
class NotificationAccessService {
  const NotificationAccessService({
    this.channel = defaultChannel,
    this.events = defaultEvents,
  });

  static const MethodChannel defaultChannel = MethodChannel(
    'com.gsit.saloneshield/notification_access',
  );

  static const EventChannel defaultEvents = EventChannel(
    'com.gsit.saloneshield/notification_events',
  );

  final MethodChannel channel;
  final EventChannel events;

  /// Whether Android has granted notification access to the listener.
  Future<bool> isAccessGranted() async {
    try {
      return await channel.invokeMethod<bool>('isAccessGranted') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Opens Android's notification-access screen. The app cannot grant itself
  /// access; all it can do is take the user to where the decision is made.
  /// Returns false when the device has no such screen.
  Future<bool> openAccessSettings() async {
    try {
      return await channel.invokeMethod<bool>('openAccessSettings') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Takes everything the listener queued while the app was closed, emptying
  /// the native queue in the same step.
  Future<List<MonitoredMessage>> drainPending() async {
    try {
      final raw = await channel.invokeMethod<List<Object?>>('drainPending');
      if (raw == null) return const [];
      return raw
          .map(MonitoredMessage.fromMap)
          .whereType<MonitoredMessage>()
          .toList(growable: false);
    } on MissingPluginException {
      return const [];
    } on PlatformException {
      return const [];
    }
  }

  /// Throws away anything queued natively. Used when the user turns
  /// monitoring off, so switching it off also forgets what it saw.
  Future<void> clearPending() async {
    try {
      await channel.invokeMethod<void>('clearPending');
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  /// Messages arriving while the app is open.
  Stream<MonitoredMessage> stream() => events
      .receiveBroadcastStream()
      .map(MonitoredMessage.fromMap)
      .where((message) => message != null)
      .cast<MonitoredMessage>();
}

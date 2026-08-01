import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salone_shield/features/notification_monitoring/application/notification_monitor_controller.dart';
import 'package:salone_shield/services/notifications/notification_access_service.dart';

/// A notification listener with no Android behind it.
///
/// [cleared] is how the tests check the promise that switching monitoring off
/// forgets what it already saw.
class FakeNotificationAccess implements NotificationAccessService {
  FakeNotificationAccess({
    this.granted = false,
    this.settingsAvailable = true,
    List<MonitoredMessage>? queued,
  }) : queued = queued ?? [];

  bool granted;
  bool settingsAvailable;
  final List<MonitoredMessage> queued;

  int cleared = 0;
  int settingsOpened = 0;
  int drains = 0;

  final StreamController<MonitoredMessage> _live =
      StreamController<MonitoredMessage>.broadcast();

  /// Simulates a message arriving while the app is open.
  void emit(MonitoredMessage message) => _live.add(message);

  Future<void> close() => _live.close();

  @override
  Future<bool> isAccessGranted() async => granted;

  @override
  Future<bool> openAccessSettings() async {
    settingsOpened++;
    return settingsAvailable;
  }

  @override
  Future<List<MonitoredMessage>> drainPending() async {
    drains++;
    final pending = List<MonitoredMessage>.from(queued);
    queued.clear();
    return pending;
  }

  @override
  Future<void> clearPending() async {
    cleared++;
    queued.clear();
  }

  @override
  Stream<MonitoredMessage> stream() => _live.stream;

  /// The fake never touches a platform channel; reaching for one is a bug in
  /// the test, so it says so loudly rather than quietly doing nothing.
  @override
  MethodChannel get channel => throw UnsupportedError('no platform in tests');

  @override
  EventChannel get events => throw UnsupportedError('no platform in tests');
}

MonitoredMessage monitoredMessage({
  int id = 1,
  String text = 'send me the code',
  bool interrupt = true,
}) => MonitoredMessage(
  id: id,
  packageName: 'com.whatsapp',
  text: text,
  receivedAt: DateTime(2026),
  interrupt: interrupt,
);

/// Wires the fake in and forces the feature on, which real builds keep behind
/// a build flag until it has been exercised on hardware.
List<Override> notificationOverrides(FakeNotificationAccess access) => [
  notificationAccessServiceProvider.overrideWithValue(access),
  notificationMonitoringAvailableProvider.overrideWithValue(true),
];

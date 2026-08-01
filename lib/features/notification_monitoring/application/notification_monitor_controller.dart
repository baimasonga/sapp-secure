import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_config.dart';
import '../../../services/notifications/notification_access_service.dart';
import '../domain/monitored_app.dart';

final notificationAccessServiceProvider = Provider<NotificationAccessService>(
  (ref) => const NotificationAccessService(),
);

/// Whether this build offers notification monitoring at all.
///
/// Off by default, like reporting, and for the same reason: the feature reads
/// other applications' notifications, and it has not been exercised on real
/// hardware in this repository. Turning it on is a decision someone makes for
/// a build they can test — see docs/ANDROID_NOTIFICATION_SERVICE.md.
final notificationMonitoringAvailableProvider = Provider<bool>(
  (ref) => AppConfig.enableNotificationMonitoring,
);

/// What the monitoring screen shows.
class NotificationMonitorState {
  const NotificationMonitorState({
    this.accessGranted = false,
    this.enabled = false,
    this.monitoredApps = const {},
    this.pending = const [],
  });

  /// Android's grant. Only the user can give or withdraw this.
  final bool accessGranted;

  /// The app's own master switch, which is a separate decision.
  final bool enabled;

  final Set<String> monitoredApps;

  /// Messages waiting to be analysed, held in memory only.
  final List<MonitoredMessage> pending;

  /// Monitoring only actually reads anything when all three line up.
  bool get isActive => accessGranted && enabled && monitoredApps.isNotEmpty;

  NotificationMonitorState copyWith({
    bool? accessGranted,
    bool? enabled,
    Set<String>? monitoredApps,
    List<MonitoredMessage>? pending,
  }) => NotificationMonitorState(
    accessGranted: accessGranted ?? this.accessGranted,
    enabled: enabled ?? this.enabled,
    monitoredApps: monitoredApps ?? this.monitoredApps,
    pending: pending ?? this.pending,
  );
}

/// Holds the user's monitoring choices and the small queue of messages the
/// listener has handed over.
///
/// Nothing in here is persisted beyond the switches themselves: the messages
/// live in this object until they are analysed or the app is closed.
class NotificationMonitorController
    extends StateNotifier<NotificationMonitorState> {
  NotificationMonitorController(this._ref)
    : super(const NotificationMonitorState()) {
    unawaited(refresh());
  }

  final Ref _ref;
  StreamSubscription<MonitoredMessage>? _subscription;

  NotificationAccessService get _service =>
      _ref.read(notificationAccessServiceProvider);

  /// Re-reads Android's grant and the stored switches, then picks up anything
  /// the listener queued while the app was closed.
  Future<void> refresh() async {
    final preferences = _ref.read(preferencesServiceProvider);
    final granted = await _service.isAccessGranted();
    final enabled = preferences.notificationMonitoringEnabled;
    final apps = <String>{
      for (final app in MonitoredApp.values)
        if (preferences.isAppMonitored(app.packageName)) app.packageName,
    };

    if (!mounted) return;
    state = state.copyWith(
      accessGranted: granted,
      enabled: enabled,
      monitoredApps: apps,
    );

    if (granted && enabled && apps.isNotEmpty) {
      await _collectPending();
      _listen();
    } else {
      // Access withdrawn in Android's settings, or the user switched it off
      // here. Either way nothing already collected should linger.
      await _stopAndForget();
    }
  }

  Future<void> setEnabled(bool value) async {
    await _ref
        .read(preferencesServiceProvider)
        .setNotificationMonitoringEnabled(value);
    if (!mounted) return;
    state = state.copyWith(enabled: value);
    await refresh();
  }

  Future<void> setAppMonitored(MonitoredApp app, bool value) async {
    await _ref
        .read(preferencesServiceProvider)
        .setAppMonitored(app.packageName, value);
    if (!mounted) return;
    final apps = Set<String>.from(state.monitoredApps);
    if (value) {
      apps.add(app.packageName);
    } else {
      apps.remove(app.packageName);
    }
    state = state.copyWith(monitoredApps: apps);
    await refresh();
  }

  Future<bool> openAccessSettings() => _service.openAccessSettings();

  /// Drops a message once the user has dealt with it.
  void dismiss(int id) {
    state = state.copyWith(
      pending: state.pending
          .where((message) => message.id != id)
          .toList(growable: false),
    );
  }

  /// Forgets every queued message, in the app and natively.
  Future<void> clearPending() async {
    await _service.clearPending();
    if (!mounted) return;
    state = state.copyWith(pending: const []);
  }

  Future<void> _collectPending() async {
    final pending = await _service.drainPending();
    if (!mounted || pending.isEmpty) return;
    state = state.copyWith(pending: [...state.pending, ...pending]);
  }

  void _listen() {
    _subscription ??= _service.stream().listen((message) {
      if (!mounted) return;
      state = state.copyWith(pending: [...state.pending, message]);
    }, onError: (Object _) {});
  }

  Future<void> _stopAndForget() async {
    await _subscription?.cancel();
    _subscription = null;
    await _service.clearPending();
    if (!mounted) return;
    state = state.copyWith(pending: const []);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}

final notificationMonitorControllerProvider =
    StateNotifierProvider<
      NotificationMonitorController,
      NotificationMonitorState
    >((ref) => NotificationMonitorController(ref));

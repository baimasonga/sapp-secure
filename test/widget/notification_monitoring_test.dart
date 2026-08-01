import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salone_shield/app/providers.dart';
import 'package:salone_shield/core/storage/preferences_service.dart';
import 'package:salone_shield/features/notification_monitoring/application/notification_monitor_controller.dart';
import 'package:salone_shield/features/notification_monitoring/domain/monitored_app.dart';
import 'package:salone_shield/features/notification_monitoring/presentation/notification_monitoring_screen.dart';
import 'package:salone_shield/l10n/app_localizations.dart';

import '../support/fake_notification_access.dart';
import '../support/test_harness.dart';

/// Notification monitoring is the first feature that reads something the user
/// did not hand over deliberately, so these tests are mostly about the
/// conditions under which it reads nothing at all.
void main() {
  late AppLocalizations l10n;

  setUp(() async => l10n = await localisationsFor('en'));

  Future<ProviderContainer> containerWith({
    required FakeNotificationAccess access,
    required PreferencesService preferences,
  }) async {
    final container = ProviderContainer(
      overrides: [
        preferencesServiceProvider.overrideWithValue(preferences),
        ...notificationOverrides(access),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(access.close);
    return container;
  }

  group('the controller', () {
    test(
      'reads nothing until access, the switch and an app all line up',
      () async {
        final access = FakeNotificationAccess(granted: true);
        final preferences = await createTestPreferences();
        final container = await containerWith(
          access: access,
          preferences: preferences,
        );
        final controller = container.read(
          notificationMonitorControllerProvider.notifier,
        );
        await controller.refresh();

        // Android has granted access, but the user has not switched anything on.
        expect(
          container.read(notificationMonitorControllerProvider).isActive,
          isFalse,
        );

        await controller.setEnabled(true);
        expect(
          container.read(notificationMonitorControllerProvider).isActive,
          isFalse,
          reason: 'the master switch alone monitors no app',
        );

        await controller.setAppMonitored(MonitoredApp.whatsApp, true);
        expect(
          container.read(notificationMonitorControllerProvider).isActive,
          isTrue,
        );
      },
    );

    test('an Android grant on its own does not start monitoring', () async {
      final access = FakeNotificationAccess(granted: true);
      final preferences = await createTestPreferences();
      final container = await containerWith(
        access: access,
        preferences: preferences,
      );
      await container
          .read(notificationMonitorControllerProvider.notifier)
          .refresh();

      expect(preferences.notificationMonitoringEnabled, isFalse);
      expect(
        preferences.isAppMonitored(MonitoredApp.whatsApp.packageName),
        isFalse,
      );
    });

    test('access withdrawn in Android settings stops everything', () async {
      final access = FakeNotificationAccess(granted: true);
      final preferences = await createTestPreferences();
      final container = await containerWith(
        access: access,
        preferences: preferences,
      );
      final controller = container.read(
        notificationMonitorControllerProvider.notifier,
      );
      await controller.setEnabled(true);
      await controller.setAppMonitored(MonitoredApp.whatsApp, true);
      access.queued.add(monitoredMessage());
      await controller.refresh();
      expect(
        container.read(notificationMonitorControllerProvider).pending,
        hasLength(1),
      );

      // The user revokes notification access without opening the app.
      access.granted = false;
      await controller.refresh();

      final state = container.read(notificationMonitorControllerProvider);
      expect(state.isActive, isFalse);
      expect(state.pending, isEmpty);
      expect(access.cleared, greaterThan(0));
    });

    test('turning the switch off forgets what was already seen', () async {
      final access = FakeNotificationAccess(granted: true);
      final preferences = await createTestPreferences();
      final container = await containerWith(
        access: access,
        preferences: preferences,
      );
      final controller = container.read(
        notificationMonitorControllerProvider.notifier,
      );
      await controller.setEnabled(true);
      await controller.setAppMonitored(MonitoredApp.whatsApp, true);
      access.queued.add(monitoredMessage());
      await controller.refresh();
      expect(
        container.read(notificationMonitorControllerProvider).pending,
        hasLength(1),
      );

      await controller.setEnabled(false);

      expect(
        container.read(notificationMonitorControllerProvider).pending,
        isEmpty,
      );
      expect(access.cleared, greaterThan(0));
    });

    test('a message arriving while the app is open is queued', () async {
      final access = FakeNotificationAccess(granted: true);
      final preferences = await createTestPreferences();
      final container = await containerWith(
        access: access,
        preferences: preferences,
      );
      final controller = container.read(
        notificationMonitorControllerProvider.notifier,
      );
      await controller.setEnabled(true);
      await controller.setAppMonitored(MonitoredApp.whatsApp, true);

      access.emit(monitoredMessage(id: 7, text: 'send me the code'));
      await Future<void>.delayed(Duration.zero);

      final pending = container
          .read(notificationMonitorControllerProvider)
          .pending;
      expect(pending, hasLength(1));
      expect(pending.single.id, 7);
    });

    test('dismissing a message drops it', () async {
      final access = FakeNotificationAccess(granted: true);
      final preferences = await createTestPreferences();
      final container = await containerWith(
        access: access,
        preferences: preferences,
      );
      final controller = container.read(
        notificationMonitorControllerProvider.notifier,
      );
      await controller.setEnabled(true);
      await controller.setAppMonitored(MonitoredApp.whatsApp, true);
      access.queued.add(monitoredMessage(id: 3));
      await controller.refresh();
      expect(
        container.read(notificationMonitorControllerProvider).pending,
        hasLength(1),
      );

      controller.dismiss(3);

      expect(
        container.read(notificationMonitorControllerProvider).pending,
        isEmpty,
      );
    });
  });

  group('the screen', () {
    testWidgets('says so plainly when the build has the feature off', (
      tester,
    ) async {
      final access = FakeNotificationAccess();
      addTearDown(access.close);
      await tester.pumpWidget(
        wrapForTest(
          const NotificationMonitoringScreen(),
          preferences: await createTestPreferences(),
          overrides: [
            notificationAccessServiceProvider.overrideWithValue(access),
            notificationMonitoringAvailableProvider.overrideWithValue(false),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.notificationsUnavailableTitle), findsOneWidget);
      expect(find.byType(SwitchListTile), findsNothing);
    });

    testWidgets('explains what it reads before offering the switch', (
      tester,
    ) async {
      final access = FakeNotificationAccess();
      await tester.pumpWidget(
        wrapForTest(
          const NotificationMonitoringScreen(),
          preferences: await createTestPreferences(),
          overrides: notificationOverrides(access),
        ),
      );
      await tester.pumpAndSettle();
      addTearDown(access.close);

      expect(find.text(l10n.notificationsWhatItReadsBody), findsOneWidget);
      expect(find.text(l10n.notificationsWhereItGoesBody), findsOneWidget);
      expect(find.text(l10n.notificationsWhatYouSeeBody), findsOneWidget);
      // The promise that matters most on this screen.
      await scrollTo(tester, find.text(l10n.notificationsNotAccessibility));
      expect(find.text(l10n.notificationsNotAccessibility), findsOneWidget);
      await scrollTo(tester, find.text(l10n.notificationsAccessMissing));
      expect(find.text(l10n.notificationsAccessMissing), findsOneWidget);
    });

    testWidgets('per-app switches stay locked until monitoring is on', (
      tester,
    ) async {
      final access = FakeNotificationAccess(granted: true);
      await tester.pumpWidget(
        wrapForTest(
          const NotificationMonitoringScreen(),
          preferences: await createTestPreferences(),
          overrides: notificationOverrides(access),
        ),
      );
      await tester.pumpAndSettle();
      addTearDown(access.close);

      await scrollTo(tester, find.text(MonitoredApp.whatsApp.displayName));
      final appSwitch = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, MonitoredApp.whatsApp.displayName),
      );
      expect(appSwitch.onChanged, isNull);
      expect(appSwitch.value, isFalse);
    });
  });
}

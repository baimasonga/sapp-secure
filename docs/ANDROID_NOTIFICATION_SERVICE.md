# Notification monitoring

Specification section 14. This is the only part of Salone Shield that reads
something the user did not hand over deliberately, so it is also the part with
the most restraint built into it.

**It ships switched off.** `ENABLE_NOTIFICATION_MONITORING` defaults to
`false`, and the screen says so plainly rather than hiding. See
[Before you enable it](#before-you-enable-it) — the honest reason is that
nothing here has run on a physical Android device.

## What it does

A `NotificationListenerService` receives the notifications the user already
sees on their lock screen. For the messaging apps the user ticked, it takes the
message text, holds it in memory, and either hands it to the app (when the app
is open) or posts a content-free "worth checking" notification (when it is
not). The user taps that, the app opens, and the same risk engine that powers
paste-and-check explains what it found.

## What it does not do

| Not done | Why |
| --- | --- |
| Read anything inside WhatsApp | Only notifications are visible to the service. It sees what the lock screen sees. |
| Use an Accessibility Service | Forbidden by section 14, and the most abusable capability an app like this could ask for. CI fails the build if one appears in the manifest. |
| Read notifications from apps the user did not tick | The monitored set is a closed list of two messaging packages. A bank, an e-mail client or an authenticator can never be in it, which is how one-time codes stay out of reach. |
| Store message text | Held in memory for fifteen minutes at most, in a queue capped at twenty entries. Killing the process forgets everything. |
| Upload message text | Nothing from monitoring reaches the network at all. |
| Put message text in its own notification | The warning says only that something arrived worth checking. Repeating the message on a lock screen would undo the point. |
| Score messages natively | Scoring, explanation and advice come from the one Dart engine. |

## The three switches

Monitoring reads nothing unless all three are true, and they are deliberately
separate decisions:

1. **Android's grant.** Notification access, given in Android's own settings.
   The app cannot grant this to itself; the most it can do is open that screen.
   The user can withdraw it there without opening Salone Shield, and the app
   notices on next resume and forgets what it had.
2. **The app's master switch.** A system grant is permission to read, not an
   instruction to start. Turning this off stops monitoring on the very next
   notification and clears the queue.
3. **A per-app tick.** Nothing is read until at least one messaging app is
   ticked.

The Kotlin service reads switches 2 and 3 out of the same shared-preferences
file the Flutter settings write, on every notification rather than caching, so
switching off in the app takes effect immediately instead of whenever the
service happens to restart. The key names are fixed in two places and must
change together:

- `PreferencesService` — `notifications.monitoring_enabled`,
  `notifications.app.<package>`
- `MonitoringSettings.kt` — the same, with the `flutter.` prefix the
  shared_preferences plugin adds.

## The interrupt filter

Deciding *whether to interrupt* is not the same as deciding *how risky a
message is*, and only the first happens natively.

`InterruptFilter` loads its patterns from the same
`assets/scam_rules/initial_rules.json` the analyser uses, keeping only rules at
or above weight 30 — today that is `verification_code_request` and
`qr_code_request`, the two the specification treats as decisive on their own. A
message matching one of those earns a notification. Everything else waits
quietly for the next time the app is opened.

Because both sides read the same file, a pattern deleted from the rules stops
interrupting people in the same commit. `InterruptFilterTest` reads the real
asset for exactly this reason: change the rules and the test tells you what the
service will now do.

## Permissions

- `POST_NOTIFICATIONS` — to tell the user a message is worth checking. The
  notification carries no message text.
- `BIND_NOTIFICATION_LISTENER_SERVICE` — **not** a permission the app requests.
  It is the guard on the `<service>` element, signature-level and held only by
  the system, which is what stops any other application binding the listener.
  CI fails the build if that attribute goes missing, and separately fails if
  the permission ever appears as something the app requests for itself.

## Files

| File | Role |
| --- | --- |
| `NotificationSecurityService.kt` | The listener. Plumbing only. |
| `notifications/NotificationGuard.kt` | Every rule about what may be read. No Android types, so it is unit-tested on the JVM. |
| `notifications/InterruptFilter.kt` | Interrupt patterns, plus Kotlin twins of the Dart pattern matcher and text normaliser. |
| `notifications/NotificationInbox.kt` | The bounded in-memory queue. The only place text is held. |
| `notifications/MonitoringSettings.kt` | Reads the user's switches. |
| `notifications/NotificationAccessDelegate.kt` | The Dart bridge: grant status, settings intent, queue drain, live stream. |
| `lib/services/notifications/notification_access_service.dart` | Dart side of the same. Fails soft everywhere. |
| `lib/features/notification_monitoring/` | Controller, domain and screen. |

## Testing

Run the native tests:

```bash
cd android && ./gradlew :app:testDebugUnitTest
```

Run the Dart tests:

```bash
flutter test test/widget/notification_monitoring_test.dart
```

Both run in CI on every push.

## Before you enable it

Everything above is covered by unit and widget tests, and nothing above has run
on a physical Android device. The following need a real phone, and the flag
should stay off in any build that has not had them done:

- [ ] The service is bound at all — grant notification access and confirm
      `onNotificationPosted` fires.
- [ ] A WhatsApp message produces exactly one queued entry, not one per
      notification update as the conversation grows.
- [ ] `android.isFromSelf` actually suppresses the user's own outgoing
      messages on the WhatsApp versions in use.
- [ ] The "worth checking" notification appears, opens the app, and never
      shows message text on the lock screen.
- [ ] Revoking access in Android settings stops delivery and clears the queue.
- [ ] Battery: a day of ordinary messaging with monitoring on, measured
      against a day with it off (specification milestone 7).
- [ ] Performance: no dropped frames or ANRs on a low-end device while a busy
      group chat is active.
- [ ] Doze and background restrictions: whether the listener survives the
      device's aggressive-battery settings, which vary widely by manufacturer.

Then build with `--dart-define=ENABLE_NOTIFICATION_MONITORING=true`.

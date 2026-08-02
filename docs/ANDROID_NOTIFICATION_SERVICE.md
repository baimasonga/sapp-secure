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
on a physical Android device. The checks below need a real phone, and the flag
should stay off in any build that has not had them done.

### What you need

- An Android phone you can put a **second, disposable WhatsApp number** on, or
  a second phone to send from. Do not test with a real conversation: you will
  be reading your own notifications deliberately, and test messages need to
  look like scams.
- USB debugging on, and `adb devices` listing the phone.
- Ideally a low-end device as well — check 7 is about a phone with 2 GB of
  RAM, not the developer's own handset.

**Test messages.** These are the two patterns that interrupt (weight ≥ 30 in
`initial_rules.json`). Send them from the second number:

| For | Send |
| --- | --- |
| An interrupting message | `Please send the code I just sent you` |
| A second interrupting message | `Scan this QR to link your WhatsApp` |
| A non-interrupting message | `Hello, are you free this afternoon?` |

### Build and install

```bash
flutter build apk --debug \
  --dart-define=ENABLE_NOTIFICATION_MONITORING=true
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Use the **debug** build: release strips the app of anything that makes a
failure legible, and this is the one part of the app with no logging of its own
(deliberately — a log line is a copy of a message on disk).

Grant notification access on the phone, or from the desktop:

```bash
adb shell cmd notification allow_listener \
  com.gsit.saloneshield/com.gsit.saloneshield.NotificationSecurityService

# Confirm the grant took:
adb shell settings get secure enabled_notification_listeners
```

Then in Salone Shield: **Settings → Notification monitoring**, turn on the
master switch and tick WhatsApp. Nothing is read until all three are on.

### The checks

Each says what to do, and what counts as a pass. **A check with no observation
recorded is not done** — tick the box in a copy of this list, not from memory.

**1. The service is bound at all.**

```bash
adb shell dumpsys notification_listener | grep -i saloneshield
```

Send the non-interrupting message. Pass: the app's monitoring screen lists one
waiting message within a second or two. Fail with an empty list means the
service is not bound — recheck the grant, and force-stop and reopen, because
Android binds listeners lazily after an install.

**2. One entry per message, not one per update.**

Send the non-interrupting message, then have the sender send two more in the
same chat. WhatsApp re-posts one growing notification as a conversation
builds, so the risk is three notifications turning into six entries.

Pass: three messages, three entries. The guard's 60-second digest window
suppresses exact reposts; what this is really testing is whether WhatsApp
*changes* the text each time, in which case the digest will not match and you
will see duplicates the unit tests cannot predict.

**3. `android.isFromSelf` suppresses your own messages.**

Reply from the phone under test. Pass: no new entry. This extra is not
documented as stable across WhatsApp versions, which is exactly why it is on
this list — if it fails, the user's own outgoing messages get analysed, which
is noise rather than a leak.

**4. The interrupt notification, and what it does not say.**

Close Salone Shield entirely (swipe it from recents). Send the
verification-code message. Pass, all four:

- a "worth checking" notification appears;
- it contains **no part of the message text** — check on the lock screen, with
  the screen locked, which is where a leak would matter;
- tapping it opens the app;
- the message is waiting there and the risk result names the
  verification-code request.

**5. Backgrounded, not closed.** *(New — see the note below.)*

Open Salone Shield, then press Home so it is backgrounded but alive. Send the
QR message. Pass: the notification still appears. A build before this was
fixed will show nothing at all, and the message will only surface when the app
is next brought forward.

**6. Revoking access stops delivery.**

```bash
adb shell cmd notification disallow_listener \
  com.gsit.saloneshield/com.gsit.saloneshield.NotificationSecurityService
```

Send a message. Pass: nothing arrives, and reopening the app shows an empty
queue and an honest "access not granted" state — not a stale message from
before the revocation.

**7. Battery.**

A day of ordinary messaging with monitoring on, against a day with it off.

```bash
adb shell dumpsys batterystats --reset          # at the start of each day
adb shell dumpsys batterystats com.gsit.saloneshield > day-on.txt
```

Pass: no measurable difference. The service does no work per notification
beyond a preferences read and a regex pass, so a visible difference means
something is wrong rather than something is expensive.

**8. Performance on a low-end device.**

With a busy group chat active:

```bash
adb shell dumpsys gfxinfo com.gsit.saloneshield framestats
adb logcat -s ActivityManager | grep -i ANR
```

Pass: no ANRs, and no rise in janky frames while messages arrive.

**9. Doze and manufacturer battery restrictions.**

```bash
adb shell dumpsys deviceidle force-idle
# send a message, then:
adb shell dumpsys deviceidle unforce
```

Also test with the phone's own aggressive-battery setting on — Xiaomi, Oppo,
Tecno and Infinix are the ones that matter for Sierra Leone, and they differ
from each other more than they differ from stock Android.

Pass is **not** "it always survives". Pass is that you know what happens, and
the app does not claim to be watching when the system has stopped it. If the
listener dies under a manufacturer's battery saver, that belongs in the
monitoring screen as a warning to the user.

### Then

Build with the flag on:

```bash
flutter build apk --release --split-per-abi \
  --dart-define=APP_ENV=production \
  --dart-define=ENABLE_NOTIFICATION_MONITORING=true
```

and update `docs/PLAY_STORE.md` — the Data Safety answers change once
monitoring is on in the submitted build.

### Two defects found while writing this list

Both were found by reading the code against the checks, not on a phone, and
both are fixed:

- **A delivered message was queued as well.** `onNotificationPosted` enqueued
  the entry and *then* handed it to the app, leaving the copy in the queue. The
  next drain — any app resume within fifteen minutes — showed the user the same
  message twice. Check 2 would have found this and it would have looked like a
  WhatsApp quirk. `NotificationInbox` now separates `create` from `enqueue`, and
  an entry the app accepts is never queued.
- **A backgrounded app swallowed the interrupt.** The event channel stays
  registered until the activity is destroyed, so an app sitting in recents with
  the screen off still counted as "open", the message went to a screen nobody
  was looking at, and no notification was posted. The user would have seen
  nothing and had no reason to suspect anything — silence that reads as safety,
  which `INCIDENT_RESPONSE.md` classes as S1. The delegate now tracks whether
  the activity is resumed and declines the entry otherwise. Check 5 exists to
  confirm the fix on real hardware.

`NotificationInboxTest` covers both.

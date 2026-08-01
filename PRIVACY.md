# Privacy

Salone Shield exists to protect people from being manipulated into giving away
money and access. A tool like that only works if it is trustworthy itself. This
document describes what the app does with data as it is built today, not what
it might do later.

## Principles

- **Local-first.** Message analysis runs entirely on the device.
- **Data minimisation.** If a feature does not need a piece of data, the app
  does not collect it.
- **Explicit consent.** Nothing leaves the device without a deliberate action.
- **Purpose limitation.** Data collected for one purpose is not reused.
- **Limited retention.** Local records expire; message text is never retained.
- **User control.** Everything stored locally can be deleted from Settings.

## What the app never collects

- WhatsApp verification codes
- WhatsApp two-step verification PINs
- Mobile-money PINs
- Banking passwords
- Complete contact lists
- WhatsApp chat history
- Screenshots the user did not choose
- Clipboard history
- Background audio

Salone Shield will never ask for a code or a PIN. That statement appears on the
dashboard and in the in-app privacy screen so that users learn to treat any
request for those as an attack — including one that claims to come from us.

## What happens to a message you analyse

1. You paste or share the text yourself. The app never reads WhatsApp directly.
2. The text is matched against rules bundled inside the app. No network request
   is made, and analysis works with the phone in aeroplane mode.
3. The result is shown.
4. When you leave the result screen the text is dropped. It is not written to
   disk at any point.

The only thing kept is a **message-free record** of the analysis:

```json
{
  "score": 50,
  "level": "high",
  "rule_ids": ["financial_request", "new_number_claim", "urgency"],
  "phone_number_count": 1,
  "url_count": 0,
  "analysed_at": "2026-07-31T12:00:00.000Z"
}
```

No message text, no matched excerpts, no telephone numbers, no links. This is
enforced by a test that fails if any of those appear in stored data.

## Local retention

| Data | Retention |
|---|---|
| Message content | Not retained after analysis |
| Analysis metadata | 30 days, newest 20 entries |
| Trusted contacts | Until you delete them |
| Verification outcomes | 180 days, newest 100 records |
| Settings (language, theme, consent) | Until changed or the app is uninstalled |
| Threat cache | Not implemented yet; will be capped at 30 days |

Settings → **Delete local history** removes every stored analysis immediately.
**Delete trusted contacts** and **Delete verification history** do the same for
those, separately, so removing one does not silently remove the other.

### Trusted contacts

Only people you deliberately add are stored, in encrypted storage backed by the
Android Keystore. There is no server copy — a breach of Salone Shield must not
reveal who anyone's family is.

Adding from your phone uses the **system contact picker**: Android shows its own
UI, you tap one person, and only that person is handed to the app. Salone Shield
holds no contacts permission and cannot read the rest of your address book.

A verification record keeps the number you checked, who the message claimed to
be, and what you concluded. It holds no message text.

### Screenshots

You choose the image through the platform photo picker, which shows the
system's own UI and hands back only the picture you selected — so the app holds
no photo or storage permission and cannot browse your gallery.

The text is read on the device. The picture is never uploaded. The picker makes
a copy of your image in the app's cache; that copy is deleted as soon as the
text has been read, whether or not recognition succeeded. Your own photo is
left alone.

Recognised text is shown to you for correction before anything is analysed, and
is treated exactly like a pasted message after that: not retained.

### Links

Links are examined entirely on the device and are **never opened** by the app.
No part of a message and no URL is sent to a reputation service; that feature
stays optional and off.

## Permissions

This build declares `INTERNET` and `POST_NOTIFICATIONS`, and requests no other
runtime permission — not even for contacts, which is why the system picker is
used instead of `READ_CONTACTS`.
Internet access is used solely for optional Supabase sign-in, which is inert
until the app is configured with a backend. `POST_NOTIFICATIONS` lets the app
tell you that a message which just arrived is worth checking; that notification
never contains any part of the message.

Android cloud backup and device-to-device transfer are disabled for app data,
so nothing syncs to a Google account.

### Notification access

Reading other applications' notifications is not a runtime permission. It is a
grant you make in Android's own settings, and Salone Shield cannot make it for
you — the most the app can do is open that screen. You can withdraw it there at
any time without opening the app.

Even with the grant, nothing is read until you also turn monitoring on inside
the app and tick at least one messaging app. Those are three separate
decisions on purpose.

What monitoring can see is the notification you already see on your lock
screen — Salone Shield cannot look inside WhatsApp, and it does not use an
Accessibility Service. Text from a monitored notification is checked on the
phone, held in memory for fifteen minutes at most, and is never written to
storage or uploaded. Turning monitoring off forgets anything already seen.

Notifications from apps you did not tick are never read. The list of apps that
*can* be ticked is fixed in the code and contains messaging apps only, so
one-time codes from your bank, your email or an authenticator are outside the
app's reach entirely.

Notification monitoring is switched off in this build. See
[docs/ANDROID_NOTIFICATION_SERVICE.md](docs/ANDROID_NOTIFICATION_SERVICE.md).

## Analytics

Off by default and requires both a build flag and in-app consent. Only
aggregate counters are ever eligible — analysis started, risk level produced,
report submitted — never message content. Analytics can be switched off again
at any time.

## When data does leave the device

Community threat reporting is the only feature that sends anything, and it is
**switched off** in this build. When it is enabled:

- You need an account, so that moderators can follow up and so one person
  cannot flood the system. Nothing else in the app needs one.
- The report form lists **exactly** what will be sent, generated from the same
  code that builds the request, before you tick the consent box.
- Only what you entered is sent. Fields you left blank are omitted entirely.
- Telephone numbers are sent over TLS and hashed on the server with a secret
  the app never holds. The database stores the hash and a mask such as
  `+232 ** *** 456` — never the number.
- Only a short excerpt you chose and can edit is included, capped at 1000
  characters. Whole conversations are refused.
- Which rules matched is sent as rule identifiers, never as message text.
- District is optional and you can leave it out.
- A report is not an accusation. Moderators review reports from several
  independent people before anything is marked verified, and a single report
  never labels anyone.
- Deleting your account detaches your reports and clears their free text.

## Your rights

Delete local history, delete all local data, and — once accounts exist —
export your data and delete your account. These are product requirements, not
aspirations, and no milestone that stores user data ships without them.

## Contact

Report a privacy concern the same way as a security issue; see
[SECURITY.md](SECURITY.md).

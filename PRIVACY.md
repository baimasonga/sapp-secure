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
| Settings (language, theme, consent) | Until changed or the app is uninstalled |
| Threat cache | Not implemented yet; will be capped at 30 days |

Settings → **Delete local history** removes every stored analysis immediately.

## Permissions

This build declares `INTERNET` only, and requests **no runtime permissions**.
Internet access is used solely for optional Supabase sign-in, which is inert
until the app is configured with a backend.

Android cloud backup and device-to-device transfer are disabled for app data,
so nothing syncs to a Google account.

Future permissions (photos for screenshots, contacts for trusted contacts,
notification access) will each be explained on their own screen before they are
requested, and each will be optional.

## Analytics

Off by default and requires both a build flag and in-app consent. Only
aggregate counters are ever eligible — analysis started, risk level produced,
report submitted — never message content. Analytics can be switched off again
at any time.

## When data does leave the device

Only community threat reporting will send anything, and that feature is not
built yet. When it is:

- You will confirm exactly what is being submitted before it is sent.
- Telephone numbers will be normalised and hashed with a server-side pepper,
  never uploaded in the clear.
- Screenshots will be uploaded only if you explicitly attach them.
- Unrelated conversation content will be stripped.

## Your rights

Delete local history, delete all local data, and — once accounts exist —
export your data and delete your account. These are product requirements, not
aspirations, and no milestone that stores user data ships without them.

## Contact

Report a privacy concern the same way as a security issue; see
[SECURITY.md](SECURITY.md).

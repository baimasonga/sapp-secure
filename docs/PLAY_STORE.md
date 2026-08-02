# Play Store listing and Data Safety

Specification milestone 8. Everything here must match what the code does. A
listing that overstates the app is not marketing copy — for a security app it
is the same failure mode as a false negative, because a user who believes the
app is watching their messages will stop watching them themselves.

## Listing

**App name** — Salone Shield

**Short description** (80 characters max)

> Check a WhatsApp message for scams. Everything is checked on your phone.

**Full description**

> Salone Shield helps you decide whether a WhatsApp message is a scam, before
> you send money or share a code.
>
> Paste a message, share it into the app, or scan a screenshot. Salone Shield
> reads it **on your phone** and tells you what it found, why it matters, and
> what to do next. Your message is not uploaded. There is no account to create
> and nothing to pay.
>
> **What it looks for**
> • Someone asking for the six-digit code WhatsApp just sent you
> • "This is my new number" from someone claiming to be a person you know
> • Requests to scan a QR code or link your WhatsApp to another device
> • Mobile-money and payment requests, especially urgent ones
> • Links that pretend to be a site you trust
>
> **Verify who you are really talking to**
> Save the people you trust and their real numbers. When a message arrives
> from a new number claiming to be one of them, Salone Shield compares the two
> and helps you check by calling the number you already have.
>
> **What Salone Shield will never do**
> • It will never ask you for a WhatsApp verification code
> • It will never ask for your two-step PIN or your mobile-money PIN
> • It will never read your messages inside WhatsApp
> • It will never upload your conversations or your contact list
>
> If any app or person claiming to be Salone Shield asks you for a code or a
> PIN, it is not us.
>
> Salone Shield cannot read anything you do not show it, and it cannot promise
> to catch every scam. It is a second opinion, not a guarantee — the final
> judgement is always yours.

**Category** — Tools. Not "Security", which sets an expectation of
always-on protection this app deliberately does not offer.

**Tags** — scam, fraud, WhatsApp, safety, Sierra Leone

### Assets still to produce

These need a designer and are not invented here:

- [ ] App icon, 512×512
- [ ] Feature graphic, 1024×500
- [ ] Phone screenshots, at least two — the analyser and a risk result. Use
      the real app, not a mock-up, and use an invented number.
- [ ] Privacy policy hosted at a public URL. `PRIVACY.md` is the text; Play
      requires it reachable on the web.

## Data Safety

Answers must match the code. Where a feature is behind a build flag, the
answer describes the build actually being submitted.

### Does the app collect or share any user data?

**Yes** — but only in the builds where reporting is enabled. For a build with
`ENABLE_REPORTING=false` and `ENABLE_NOTIFICATION_MONITORING=false`, which is
the default and the current state, the honest answer is **no data collected
and no data shared**.

The rest of this section describes a build with reporting **on**.

| Data type | Collected | Shared | Required | Purpose |
|---|---|---|---|---|
| Email address | Yes | No | Optional | Account creation, only for submitting reports |
| Phone number | **No** | No | — | Numbers are hashed with a server-side pepper before storage. The raw number is never written |
| Messages (other in-app) | Yes | No | Optional | A short excerpt the user chooses to include with a report |
| App interactions | Optional | No | Optional | Only with in-app analytics consent, which is off by default |
| Crash logs | No | No | — | No crash reporting is wired up |
| Contacts | **No** | No | — | Chosen through the system picker; the app has no contacts permission and never uploads them |
| Photos | **No** | No | — | Chosen through the system photo picker, read on-device, and the copy is deleted |

### Security practices

- **Data is encrypted in transit** — yes, TLS to Supabase.
- **Users can request data deletion** — yes. Account deletion is in the app
  and removes the profile; reports survive detached from the reporter with
  the free text cleared.
- **Data is encrypted at rest on the device** — trusted contacts are held in
  the Android Keystore.
- **Committed to the Play Families policy** — not applicable; the app is not
  aimed at children.

### The two answers most likely to be got wrong

**"Phone number: collected"** is the tempting answer and it is wrong for this
app, but only because of a specific design decision: the number reaches the
Edge Function over TLS, is hashed with a pepper the client never sees, and the
hash is what is stored. If that ever changes — if a raw number is written for
any reason — this answer changes with it.

**"Messages: collected"** must stay **yes** whenever reporting is on, even
though the excerpt is short and user-chosen. It is message content, the user
typed or pasted it, and it leaves the device.

## Content rating

- Not aimed at children.
- No user-to-user communication, no user-generated content visible to other
  users. Reports go to moderators, never to a public feed — this matters for
  the rating questionnaire, which asks about sharing between users.
- References to crime in the context of prevention and education.

## Before submitting

- [ ] Confirm which flags the submitted build was compiled with, and check
      the Data Safety answers against *that* build.
- [ ] Privacy policy live at a public URL and linked in the listing.
- [ ] Signing key generated and stored outside this repository.
- [ ] `pubspec.yaml` version bumped; CI validates the `1.2.3+4` shape.
- [ ] Read `INCIDENT_RESPONSE.md` and fill in the contact table. Publishing
      without anyone named to respond is the part of this list most likely to
      be skipped and most likely to matter.

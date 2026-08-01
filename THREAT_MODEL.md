# Threat model

Scope: the Android application as built today (local analysis, no backend
traffic), plus the threats that the planned reporting and moderation features
will introduce. Each entry records the asset, the actor, the vector, impact,
likelihood, the mitigation in place, and what risk remains.

Likelihood and impact are rated Low / Medium / High for a typical user in
Sierra Leone, not for a hardened enterprise device.

---

### T1 — Attacker convinces the user to share a verification code

- **Asset:** the user's WhatsApp or mobile-money account
- **Actor:** scammer with a hijacked or spoofed contact
- **Vector:** a message asking the user to forward a six-digit code
- **Impact:** High — full account takeover, then the same scam sent to the
  victim's contacts
- **Likelihood:** High — this is the single most common scam in scope
- **Mitigation:** the highest rule weight (35) plus an escalation floor that
  makes any code request Critical on its own; the top recommended action is
  never to share a code; the dashboard states that Salone Shield itself will
  never ask
- **Residual risk:** Medium. A reworded request with no matching keyword scores
  nothing. The result screen always states that the app cannot confirm who sent
  a message.

### T2 — QR-code linking attack

- **Asset:** the user's WhatsApp session
- **Actor:** scammer running WhatsApp Web
- **Vector:** "scan this to vote / confirm your account"
- **Impact:** High — silent, persistent read access to conversations
- **Likelihood:** Medium
- **Mitigation:** dedicated rule with an escalation floor to Critical; advice
  directs the user to WhatsApp → Linked Devices
- **Residual risk:** Medium. The app cannot see what a QR code contains; it can
  only react to text that mentions one.

### T3 — Impersonation of a known contact from a new number

- **Asset:** the user's money
- **Actor:** scammer using a stolen name and story
- **Vector:** "this is my new number, I lost my phone, send money urgently"
- **Impact:** High
- **Likelihood:** High
- **Mitigation:** new-number, financial-request, urgency and third-party-payment
  rules combine to High risk; advice is always to call the previously saved
  number, never the one in the message. The verification workflow compares the
  number against the trusted contact the message claims to be and states
  plainly when it is one that person has never used, then offers to dial the
  saved number instead. A confirmed impersonation is remembered, so the same
  number is recognised next time.
- **Residual risk:** Medium. The comparison only helps for people the user has
  saved, and it depends on the user identifying who the message claims to be. A
  matching number is still not proof: a stolen phone or hijacked account sends
  from the right number, which the screen says explicitly.

### T4 — Malicious link

- **Asset:** device integrity, credentials
- **Actor:** phishing operator
- **Vector:** look-alike domain, shortener, APK download, encoded redirect
- **Impact:** High
- **Likelihood:** Medium
- **Mitigation:** twelve offline checks including brand look-alikes for
  WhatsApp, Orange Money and Afrimoney; flagged links are shown as plain text
  and are never tappable
- **Residual risk:** Medium. The analyser never opens or follows a link, so a
  clean-looking URL that redirects to a malicious page is not caught. The
  registrable-domain comparison is a heuristic, not a public-suffix list.

### T5 — False accusation of an innocent person

- **Asset:** a third party's reputation and safety
- **Actor:** a mistaken or malicious reporter; also the app itself
- **Vector:** a number appearing in a scam message, or a single unverified
  report, being presented as proof
- **Impact:** High — real-world harm to someone who did nothing
- **Likelihood:** Medium
- **Mitigation:** results are phrased as possibilities; extracted numbers carry
  an explicit note that appearing in a message does not mean the number belongs
  to a criminal; the community-indicator rule is capped at 30 points and can
  never on its own produce a Critical verdict; report counts alone will never
  produce a "verified" label
- **Residual risk:** Medium. Moderation policy, reporter reputation and an
  appeals path are required before community indicators are surfaced at all.

### T6 — Device theft or shoulder-surfing

- **Asset:** local analysis history, settings
- **Actor:** thief, or an abusive family member
- **Vector:** physical access to an unlocked phone
- **Impact:** Medium — history reveals that someone was checking messages and
  roughly when, and trusted contacts reveal who the user deals with
- **Likelihood:** Medium
- **Mitigation:** message text is never stored; analysis history holds no
  numbers, links or excerpts; trusted contacts and verification outcomes are in
  Keystore-backed encrypted storage; every category can be deleted separately
  from Settings; app data is excluded from backup and device transfer
- **Residual risk:** Medium until the optional biometric app lock ships.

### T7 — Screenshot containing unrelated private data

- **Asset:** third parties' messages inside the same screenshot
- **Actor:** the user, unintentionally
- **Vector:** importing a screenshot that shows a whole conversation
- **Impact:** Medium
- **Likelihood:** High once screenshot import ships
- **Mitigation:** not applicable yet — the feature is not built
- **Residual risk:** Deferred. Requirements are already fixed: OCR runs locally,
  extracted text is editable before analysis, the image is deleted unless the
  user saves it, and uploading needs separate consent.

### T8 — Contact-data over-collection

- **Asset:** the user's whole social graph
- **Actor:** a future careless implementation
- **Vector:** reading the device contact list wholesale
- **Impact:** High
- **Likelihood:** Low
- **Mitigation:** no contacts permission is declared, and none is needed: adding
  from the phone goes through the system contact picker, which returns only the
  single row the user tapped. Contacts are stored in the Keystore, capped at 50,
  never uploaded, and deletable in one tap. A CI check fails the build if any
  permission beyond INTERNET appears in the manifest.
- **Residual risk:** Low.

### T9 — Rule poisoning

- **Asset:** detection integrity
- **Actor:** an attacker who can influence the rule set
- **Vector:** a malicious or careless remote rule update that disables rules or
  floods the user with false positives
- **Impact:** High — a security tool that has been told to stay quiet
- **Likelihood:** Low today: rules ship inside the signed APK and there is no
  update channel
- **Mitigation:** rule loading validates every rule and rejects duplicate ids
  and out-of-range weights; a malformed set fails closed with a visible error
  rather than scoring zero
- **Residual risk:** Deferred. Remote rule updates must be signed and validated
  before that channel is opened.

### T10 — Denial of service through pathological input

- **Asset:** app availability on a low-end phone
- **Actor:** an attacker sending an enormous or adversarial message
- **Vector:** megabytes of text, or text crafted against the matcher
- **Impact:** Low-Medium
- **Likelihood:** Low
- **Mitigation:** input truncated at 20,000 characters; patterns are literal
  strings with fixed boundary assertions rather than user-supplied regular
  expressions, so catastrophic backtracking is not reachable; a test asserts a
  300,000-character input completes in under five seconds
- **Residual risk:** Low.

### T11 — Evasion through obfuscated text

- **Asset:** detection integrity
- **Actor:** any scammer who notices the app exists
- **Vector:** zero-width characters, look-alike punctuation, deliberate
  misspellings, or simply different words
- **Impact:** Medium
- **Likelihood:** High over time
- **Mitigation:** normalisation strips zero-width and bidirectional characters
  and folds smart quotes and dashes; rules carry many phrasings in English and
  Krio; tests cover the obfuscation cases
- **Residual risk:** High and permanent for a keyword engine. This is the main
  argument for the on-device classifier in a later milestone, and the reason
  every result states what the app could not check.

### T12 — Compromised user account (once accounts exist)

- **Asset:** the user's reports and profile
- **Actor:** credential thief, SIM-swap attacker
- **Vector:** password reuse, OTP interception
- **Impact:** Medium
- **Likelihood:** Medium
- **Mitigation:** deferred — guest mode needs no account, which keeps most users
  out of scope entirely
- **Residual risk:** Deferred to the authentication milestone.

### T13 — Malicious reporter / report flooding

- **Asset:** the integrity of community indicators
- **Actor:** a scammer discrediting a rival, or someone harassing a neighbour
- **Vector:** many reports against an innocent number
- **Impact:** High
- **Likelihood:** Medium
- **Mitigation:** deferred; confidence must combine independent reporters,
  evidence quality and moderator verification, never raw counts
- **Residual risk:** Deferred. Reporting will not ship without rate limiting,
  duplicate detection, reporter reputation and an appeals route.

### T14 — Moderator abuse and database breach

- **Asset:** all submitted reports and evidence
- **Actor:** insider, or an attacker with database access
- **Vector:** excessive privileges, missing row-level security, plaintext
  indicators
- **Impact:** High
- **Likelihood:** Low-Medium
- **Mitigation:** deferred; the design requires row-level security on every
  table, append-only moderation logs, private evidence storage, peppered hashes
  instead of plaintext numbers, and the service-role key never leaving the
  server
- **Residual risk:** Deferred, and gating for the reporting milestone.

### T15 — Reverse engineering and impersonation of the app

- **Asset:** users' trust in the brand
- **Actor:** a scammer distributing a fake "Salone Shield" APK that harvests
  codes and PINs
- **Vector:** side-loaded APK, look-alike listing
- **Impact:** High
- **Likelihood:** Medium
- **Mitigation:** the real app repeatedly states it will never ask for a code or
  PIN, which gives users a way to recognise the fake; the link analyser flags
  direct APK download links
- **Residual risk:** Medium. Requires Play Store distribution, a published
  signing fingerprint, and user education.

---

## Review

This document is reviewed at every milestone. A new feature that introduces a
new asset, actor or vector does not ship until its row is written and its
mitigation is real.

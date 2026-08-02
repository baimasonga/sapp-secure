/// Dashboard copy.
///
/// Plain Dart constants rather than ARB files, deliberately. The phone app is
/// translated because its audience is everyone in Sierra Leone; the dashboard's
/// audience is a named handful of moderators working in English, and putting
/// sixty internal strings through the app's localisation pipeline would grow
/// the mobile bundle for people who will never see this screen.
///
/// If moderation is ever staffed by people who do not read English, this file
/// is the thing to replace — not the phone app's ARB.
abstract final class Mod {
  static const appTitle = 'Salone Shield — Moderation';

  // Sign in
  static const signInTitle = 'Moderator sign-in';
  static const signInBody =
      'This dashboard is for moderators. Signing in with an ordinary account '
      'will not show you anything.';
  static const email = 'Email';
  static const password = 'Password';
  static const signIn = 'Sign in';
  static const signOut = 'Sign out';
  static const signInFailed = 'That email and password were not accepted.';
  static const notAModeratorTitle = 'This account cannot moderate';
  static const notAModeratorBody =
      'You are signed in, but this account is not a moderator. Ask an '
      'administrator to grant the role, then sign in again.';

  // Navigation
  static const navQueue = 'Queue';
  static const navAudit = 'Audit log';
  static const navRules = 'Rules';

  // Queue
  static const queueTitle = 'Reports waiting';
  static const queueEmpty =
      'Nothing waiting. Reports appear here as they are submitted.';
  static const queueOldestFirst = 'Oldest first — longest wait at the top';
  static const queueLoadFailed = 'The queue could not be loaded.';
  static const retry = 'Try again';
  static const filterAll = 'All open';
  static const filterPending = 'Pending';
  static const filterUnderReview = 'Under review';
  static const filterNeedsEvidence = 'Needs evidence';

  // Report detail
  static const reportTitle = 'Report';
  static const reportedNumber = 'Reported number';
  static const paymentNumber = 'Payment number';
  static const reportedLink = 'Reported link';
  static const excerpt = 'Excerpt the reporter chose to include';
  static const noExcerpt = 'No excerpt was included.';
  static const district = 'District';
  static const signals = 'Rules that fired on the reporter’s phone';
  static const noSignals = 'No rules were recorded with this report.';
  static const reporter = 'Reporter';
  static const reporterDeleted =
      'This reporter has deleted their account. The report stands on its own.';
  static const submitted = 'Submitted';
  static const hashOnlyNote =
      'Numbers are stored as a peppered hash. Neither this dashboard nor the '
      'database can show you the number itself.';

  // Indicator
  static const indicatorTitle = 'This number’s standing';
  static const indicatorNone =
      'No indicator yet — this report names no number.';
  static const indicatorReports = 'Reports';
  static const indicatorVerified = 'Verified reports';
  static const indicatorReporters = 'Distinct reporters';
  static const indicatorVisible = 'Visible to users';
  static const indicatorHidden = 'Not visible to users';
  static const indicatorSingleReporter =
      'One person has reported this. Repeated reports from the same person '
      'are not corroboration.';

  // Verdict
  static const verdictTitle = 'Decision';
  static const verdictVerify = 'Verify';
  static const verdictReject = 'Reject';
  static const verdictNeedsEvidence = 'Needs more evidence';
  static const verdictDuplicate = 'Mark duplicate';
  static const verdictArchive = 'Archive';
  static const noteLabel = 'What the reporter will be told';
  static const noteHelp =
      'Shown to the reporter, so write it to them. Your working notes go in '
      'the audit log entry automatically.';
  static const noteRequired =
      'Verifying or rejecting needs a reason. Someone is on the other end of '
      'this decision.';
  static const duplicateOfLabel = 'Duplicate of report id';
  static const verdictRecorded = 'Decision recorded.';
  static const verdictFailed =
      'The server refused that decision. Nothing was changed.';
  static const verifyWarning =
      'Verifying makes this number visible to every user of the app. It is the '
      'one action here that a stranger will see the result of.';
  static const alreadyDecided = 'Decided';

  // Audit
  static const auditTitle = 'Audit log';
  static const auditBody =
      'Every decision, in the order it was made. Entries cannot be edited or '
      'removed, by anyone.';
  static const auditEmpty = 'No decisions have been recorded yet.';

  // Rules
  static const rulesTitle = 'Detection rules';
  static const rulesBody =
      'Remote rules. The app ships with its own copy and does not yet read '
      'these, so a change here affects nothing until that lands.';
  static const rulesEmpty = 'No remote rules have been published.';
  static const rulesAdminOnly =
      'Rule changes affect detection for every user, so they are limited to '
      'administrators.';
  static const ruleWeight = 'Weight';
  static const ruleFloor = 'Floor';
  static const rulePatterns = 'Patterns';
  static const ruleEnabled = 'Enabled';
}

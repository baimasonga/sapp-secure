import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/threat_reporting/domain/threat_report.dart';
import '../domain/moderation_models.dart';
import 'moderation_gateway.dart';

/// The dashboard's only route to the database.
///
/// It uses the **anon key and the moderator's own session**, exactly like the
/// phone app. There is no service-role key in a web build and there must never
/// be one: a browser bundle is public, and a service-role key in it would hand
/// every report to anyone who opened the developer console. Everything this
/// class is allowed to do is therefore decided by row-level security, not by
/// the code below — which is the point. If a policy is wrong, this class
/// cannot paper over it.
class SupabaseModerationGateway implements ModerationGateway {
  SupabaseModerationGateway(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const ModerationFailure(ModerationFailureReason.notSignedIn);
    }
    return id;
  }

  @override
  Future<ModeratorRole> currentRole() async {
    final id = _client.auth.currentUser?.id;
    if (id == null) return ModeratorRole.user;
    try {
      final row = await _client
          .from('profiles')
          .select('role, is_suspended')
          .eq('id', id)
          .maybeSingle();
      if (row == null) return ModeratorRole.user;
      // A suspended moderator is not a moderator. The database says the same
      // thing inside is_moderator(); this keeps the UI honest about it too.
      if (row['is_suspended'] == true) return ModeratorRole.user;
      return ModeratorRole.fromId(row['role'] as String?);
    } on PostgrestException catch (error) {
      throw ModerationFailure(
        ModerationFailureReason.network,
        debugMessage: error.code,
      );
    }
  }

  @override
  Future<List<QueuedReport>> queue({
    Set<ReportStatus> statuses = const {
      ReportStatus.pending,
      ReportStatus.underReview,
      ReportStatus.needsMoreEvidence,
    },
  }) async {
    try {
      final rows = await _client
          .from('threat_reports')
          .select()
          .inFilter(
            'status',
            statuses.map((status) => status.id).toList(growable: false),
          )
          // Oldest first: the queue is a waiting list, not a news feed.
          .order('created_at', ascending: true)
          .limit(200);

      final reports = <QueuedReport>[];
      final standings = await _standingsFor(rows);
      for (final row in rows) {
        final map = Map<String, Object?>.from(row);
        final report = QueuedReport.tryFromJson(
          map,
          indicator: standings[map['reported_number_hash']],
        );
        if (report != null) reports.add(report);
      }
      return reports;
    } on PostgrestException catch (error) {
      throw ModerationFailure(
        ModerationFailureReason.network,
        debugMessage: error.code,
      );
    }
  }

  @override
  Future<QueuedReport?> reportById(String id) async {
    try {
      final row = await _client
          .from('threat_reports')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (row == null) return null;
      final map = Map<String, Object?>.from(row);
      final standings = await _standingsFor([row]);
      return QueuedReport.tryFromJson(
        map,
        indicator: standings[map['reported_number_hash']],
      );
    } on PostgrestException catch (error) {
      throw ModerationFailure(
        ModerationFailureReason.network,
        debugMessage: error.code,
      );
    }
  }

  /// Fetches indicator standings for a page of reports in one query, so a
  /// hundred-row queue does not become a hundred round trips.
  Future<Map<String, IndicatorStanding>> _standingsFor(
    List<Map<String, dynamic>> rows,
  ) async {
    final hashes = <String>{
      for (final row in rows)
        if (row['reported_number_hash'] is String)
          row['reported_number_hash'] as String,
    };
    if (hashes.isEmpty) return const {};

    final indicatorRows = await _client
        .from('threat_indicators')
        .select()
        .inFilter('indicator_hash', hashes.toList(growable: false));

    final standings = <String, IndicatorStanding>{};
    for (final row in indicatorRows) {
      final standing = IndicatorStanding.tryFromJson(
        Map<String, Object?>.from(row),
      );
      if (standing != null) standings[standing.hash] = standing;
    }
    return standings;
  }

  @override
  Future<void> recordVerdict({
    required QueuedReport report,
    required Verdict verdict,
    required String note,
    String? duplicateOf,
  }) async {
    final moderatorId = _userId;
    final trimmedNote = note.trim();

    try {
      // The audit entry is written first, on purpose. If the update then
      // fails, the log holds an attempt that did not take effect — which is
      // recoverable and visible. The other order can leave a decision with no
      // record of who made it, which is not.
      await _client.from('moderation_actions').insert({
        'moderator_id': moderatorId,
        'report_id': report.id,
        'action': verdict.action,
        'notes': trimmedNote.isEmpty ? null : trimmedNote,
        'previous_status': report.status.id,
        'new_status': verdict.status.id,
      });

      await _client
          .from('threat_reports')
          .update({
            'status': verdict.status.id,
            'moderator_note': trimmedNote.isEmpty ? null : trimmedNote,
            if (verdict == Verdict.markDuplicate) 'duplicate_of': duplicateOf,
          })
          .eq('id', report.id);
    } on PostgrestException catch (error) {
      throw ModerationFailure(
        ModerationFailureReason.rejectedByServer,
        debugMessage: error.code,
      );
    }
  }

  @override
  Future<List<ModerationEntry>> auditLog({int limit = 100}) async {
    try {
      final rows = await _client
          .from('moderation_actions')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return rows
          .map((row) => ModerationEntry.tryFromJson(Map.from(row)))
          .whereType<ModerationEntry>()
          .toList(growable: false);
    } on PostgrestException catch (error) {
      throw ModerationFailure(
        ModerationFailureReason.network,
        debugMessage: error.code,
      );
    }
  }

  @override
  Future<List<RemoteRule>> rules() async {
    try {
      final rows = await _client
          .from('scam_rules')
          .select()
          .order('rule_code', ascending: true);
      return rows
          .map((row) => RemoteRule.tryFromJson(Map.from(row)))
          .whereType<RemoteRule>()
          .toList(growable: false);
    } on PostgrestException catch (error) {
      throw ModerationFailure(
        ModerationFailureReason.network,
        debugMessage: error.code,
      );
    }
  }

  @override
  Future<void> setRuleEnabled({
    required String ruleId,
    required bool enabled,
  }) async {
    try {
      await _client
          .from('scam_rules')
          .update({
            'enabled': enabled,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', ruleId);
    } on PostgrestException catch (error) {
      throw ModerationFailure(
        ModerationFailureReason.rejectedByServer,
        debugMessage: error.code,
      );
    }
  }
}

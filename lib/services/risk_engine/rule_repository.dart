import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../../core/errors/app_failure.dart';
import 'risk_engine.dart';

/// Loads the scam rules that drive the engine.
///
/// The bundled asset is the offline source of truth so the app works with no
/// network at all. A later milestone will layer a signed Supabase rule update
/// on top of it; the interface is kept narrow so that change stays local.
class RuleRepository {
  const RuleRepository({this.bundle});

  /// Overridden in tests; the real app reads from the app bundle.
  final AssetBundle? bundle;

  static const String assetPath = 'assets/scam_rules/initial_rules.json';

  Future<RiskEngine> loadEngine() async {
    try {
      final json = await (bundle ?? rootBundle).loadString(assetPath);
      return RiskEngine.fromJsonString(json);
    } on FormatException catch (error) {
      // Malformed rules must fail loudly in development and degrade to a clear
      // message in production, never to a silent "everything looks safe".
      throw AnalysisFailure(debugMessage: 'invalid rule set: ${error.message}');
    } on Exception {
      throw const AnalysisFailure(debugMessage: 'rule asset unavailable');
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/storage/preferences_service.dart';
import '../../../features/trusted_contacts/application/trusted_contacts_controller.dart';
import '../../../services/risk_engine/models/risk_assessment.dart';
import '../../../services/risk_engine/risk_engine.dart';

/// Explicit loading, success and error states (section 20). There is no
/// implicit "nothing happened" success: a failed analysis must never look like
/// a clean result.
sealed class AnalysisState {
  const AnalysisState();
}

class AnalysisIdle extends AnalysisState {
  const AnalysisIdle();
}

class AnalysisRunning extends AnalysisState {
  const AnalysisRunning();
}

class AnalysisSuccess extends AnalysisState {
  const AnalysisSuccess(this.assessment);

  final RiskAssessment assessment;
}

class AnalysisFailed extends AnalysisState {
  const AnalysisFailed(this.failure);

  final AppFailure failure;
}

/// Runs a message through the risk engine and records message-free metadata.
class AnalysisController extends StateNotifier<AnalysisState> {
  AnalysisController(this._ref) : super(const AnalysisIdle());

  final Ref _ref;

  /// Guards against pathological input before any regex work happens.
  static const int maxInputLength = RiskEngine.maxAnalysedCharacters;

  Future<void> analyse(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      state = const AnalysisFailed(ValidationFailure(field: 'message'));
      return;
    }
    if (trimmed.length > maxInputLength) {
      state = const AnalysisFailed(
        ValidationFailure(field: 'message', debugMessage: 'input too long'),
      );
      return;
    }

    state = const AnalysisRunning();
    try {
      final engine = await _ref.read(riskEngineProvider.future);
      // Trusted numbers let the engine recognise a sender the user already
      // knows. They never leave the device.
      final trustedNumbers = await _ref
          .read(trustedContactRepositoryProvider)
          .trustedNumbers();
      final assessment = engine.analyse(
        trimmed,
        languageCode: _ref.read(engineLanguageProvider),
        context: AnalysisContext(trustedNumbersE164: trustedNumbers),
      );
      state = AnalysisSuccess(assessment);
      await _recordMetadata(assessment);
    } on AppFailure catch (failure) {
      state = AnalysisFailed(failure);
    } on Exception {
      state = const AnalysisFailed(AnalysisFailure());
    }
  }

  /// History is best-effort: a storage problem must not hide a result the user
  /// is waiting for.
  Future<void> _recordMetadata(RiskAssessment assessment) async {
    try {
      await _ref.read(preferencesServiceProvider).addAnalysis(assessment);
      _ref.invalidate(recentAnalysesProvider);
    } on Exception {
      return;
    }
  }

  void reset() => state = const AnalysisIdle();
}

final analysisControllerProvider =
    StateNotifierProvider<AnalysisController, AnalysisState>(
      AnalysisController.new,
    );

/// Message-free history shown on the dashboard.
final recentAnalysesProvider = Provider<List<Map<String, Object?>>>(
  (ref) => ref.watch(preferencesServiceProvider).recentAnalyses(),
);

/// Exposed so Settings can clear it and the dashboard can refresh.
final historyRetentionDaysProvider = Provider<int>(
  (ref) => PreferencesService.recentAnalysisRetention.inDays,
);

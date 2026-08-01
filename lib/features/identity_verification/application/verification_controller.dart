import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../trusted_contacts/application/trusted_contacts_controller.dart';
import '../../trusted_contacts/domain/trusted_contact.dart';
import '../data/verification_history_repository.dart';
import '../domain/verification_record.dart';

/// What the Verify Person screen is working on.
class VerificationState {
  const VerificationState({
    required this.numberInQuestionE164,
    this.claimedContact,
    this.claimedName = '',
    this.method,
    this.pastRecords = const [],
    this.saved = false,
  });

  /// The number the message came from, or the number it asked you to pay.
  final String numberInQuestionE164;

  /// The trusted contact the message claims to be. Null until chosen.
  final TrustedContact? claimedContact;

  /// Used when the claimed person is not a saved contact.
  final String claimedName;

  final VerificationMethod? method;

  /// Earlier checks of this same number.
  final List<VerificationRecord> pastRecords;

  final bool saved;

  /// The comparison that makes this feature worth having.
  NumberMatchStatus get matchStatus => claimedContact == null
      ? NumberMatchStatus.noTrustedContact
      : claimedContact!.match(numberInQuestionE164);

  /// True when someone claims to be a saved contact but is writing from a
  /// number that contact has never used.
  bool get isNumberMismatch =>
      matchStatus == NumberMatchStatus.differsFromTrusted;

  /// A previous check that already concluded this number was an impersonator.
  bool get wasPreviouslyImpersonation => pastRecords.any(
    (record) => record.outcome == VerificationOutcome.confirmedImpersonation,
  );

  String get effectiveClaimedName =>
      claimedContact?.displayName ?? claimedName.trim();

  VerificationState copyWith({
    TrustedContact? claimedContact,
    bool clearClaimedContact = false,
    String? claimedName,
    VerificationMethod? method,
    List<VerificationRecord>? pastRecords,
    bool? saved,
  }) {
    return VerificationState(
      numberInQuestionE164: numberInQuestionE164,
      claimedContact: clearClaimedContact
          ? null
          : (claimedContact ?? this.claimedContact),
      claimedName: claimedName ?? this.claimedName,
      method: method ?? this.method,
      pastRecords: pastRecords ?? this.pastRecords,
      saved: saved ?? this.saved,
    );
  }
}

class VerificationController extends StateNotifier<VerificationState> {
  VerificationController(this._history, String numberInQuestionE164)
    : super(VerificationState(numberInQuestionE164: numberInQuestionE164)) {
    _loadHistory();
  }

  final VerificationHistoryRepository _history;

  Future<void> _loadHistory() async {
    final records = await _history.forNumber(state.numberInQuestionE164);
    if (!mounted) return;
    state = state.copyWith(pastRecords: records);
  }

  void selectContact(TrustedContact? contact) {
    state = contact == null
        ? state.copyWith(clearClaimedContact: true)
        : state.copyWith(claimedContact: contact);
  }

  void setClaimedName(String name) => state = state.copyWith(claimedName: name);

  void selectMethod(VerificationMethod method) =>
      state = state.copyWith(method: method);

  /// Records what the user concluded. Storing the outcome is the point of the
  /// workflow: the next time this number appears, the app can say so.
  Future<void> recordOutcome(VerificationOutcome outcome) async {
    final record = VerificationRecord(
      id: TrustedContact.newId(),
      claimedName: state.effectiveClaimedName,
      numberInQuestionE164: state.numberInQuestionE164,
      matchStatus: state.matchStatus,
      outcome: outcome,
      method: state.method,
      contactId: state.claimedContact?.id,
      createdAt: DateTime.now(),
    );
    await _history.add(record);
    if (!mounted) return;
    state = state.copyWith(
      saved: true,
      pastRecords: [record, ...state.pastRecords],
    );
  }
}

final verificationHistoryRepositoryProvider =
    Provider<VerificationHistoryRepository>(
      (ref) => VerificationHistoryRepository(ref.watch(secureStorageProvider)),
    );

/// One controller per number under investigation.
final verificationControllerProvider = StateNotifierProvider.autoDispose
    .family<VerificationController, VerificationState, String>(
      (ref, numberE164) => VerificationController(
        ref.watch(verificationHistoryRepositoryProvider),
        numberE164,
      ),
    );

/// The full local verification history, newest first.
final verificationHistoryProvider = FutureProvider<List<VerificationRecord>>(
  (ref) => ref.watch(verificationHistoryRepositoryProvider).load(),
);

/// Past outcomes for a number, used to warn on the result screen.
final verificationsForNumberProvider =
    FutureProvider.family<List<VerificationRecord>, String>((
      ref,
      numberE164,
    ) async {
      final records = await ref.watch(verificationHistoryProvider.future);
      return records
          .where((record) => record.numberInQuestionE164 == numberE164)
          .toList();
    });

/// Re-exported so the verification screen can offer the user's contacts.
final verificationContactsProvider = Provider<List<TrustedContact>>(
  (ref) => ref.watch(trustedContactsControllerProvider).valueOrNull ?? const [],
);

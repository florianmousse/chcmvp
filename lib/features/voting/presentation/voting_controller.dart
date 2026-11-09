import 'package:chc_mvp/core/services/scoped_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';

part 'voting_controller.g.dart';

typedef VoteWriter =
    Future<void> Function(String path, Map<String, dynamic> data);
final voteWriterProvider = Provider<VoteWriter>(
  (ref) =>
      (path, data) => ref.read(firestoreProvider).doc(path).set(data),
);

@riverpod
class VoteSubmissionController extends _$VoteSubmissionController {
  @override
  FutureOr<void> build() {}

  /// Écrit le document votes/{voterUid} du match. Les règles Firestore
  /// interdisent toute modification ultérieure : un membre = un vote, définitif.
  Future<void> submit({
    required String matchId,
    required String firstPlaceUid,
    required String secondPlaceUid,
    required String thirdPlaceUid,
  }) async {
    final auth = ref.read(firebaseAuthProvider).currentUser;
    if (auth == null) throw StateError('Utilisateur non connecté');

    final pending = ref.keepAlive();
    try {
      state = const AsyncLoading();
      state = await AsyncValue.guard(() async {
        final path = scopedFirestorePath(
          'matches/$matchId/votes/${auth.uid}',
          ref.read(reviewSpaceUidProvider),
        );

        // set() sans merge : si le document existe déjà, les règles Firestore
        // bloquent de toute façon la ré-écriture (allow update: if false),
        // donc cet appel échouera proprement plutôt que d'écraser un vote existant.
        await ref.read(voteWriterProvider)(path, {
          'voterUid': auth.uid,
          'firstPlaceUid': firstPlaceUid,
          'secondPlaceUid': secondPlaceUid,
          'thirdPlaceUid': thirdPlaceUid,
          'votedAt': FieldValue.serverTimestamp(),
        });
      });
      // AsyncValue.guard capture l'erreur : la propager aussi à l'écran pour
      // qu'un refus réseau / Firestore ne soit jamais annoncé comme un succès.
      if (state.hasError) {
        Error.throwWithStackTrace(state.error!, state.stackTrace!);
      }
    } finally {
      pending.close();
    }
  }
}

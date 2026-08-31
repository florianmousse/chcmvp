import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';

part 'voting_controller.g.dart';

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

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final firestore = ref.read(firestoreProvider);
      final voteRef = firestore
          .collection('matches')
          .doc(matchId)
          .collection('votes')
          .doc(auth.uid);

      // set() sans merge : si le document existe déjà, les règles Firestore
      // bloquent de toute façon la ré-écriture (allow update: if false),
      // donc cet appel échouera proprement plutôt que d'écraser un vote existant.
      await voteRef.set({
        'voterUid': auth.uid,
        'firstPlaceUid': firstPlaceUid,
        'secondPlaceUid': secondPlaceUid,
        'thirdPlaceUid': thirdPlaceUid,
        'votedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}

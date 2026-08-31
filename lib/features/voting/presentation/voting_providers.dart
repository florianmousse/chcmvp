import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';

/// true si l'utilisateur connecté a déjà un document votes/{monUid} pour ce
/// match — permet à l'UI de remplacer le bouton "Voter" par "Déjà voté ✓"
/// sans jamais avoir à lire le contenu des votes des autres (les règles
/// Firestore l'interdisent de toute façon, voir firestore.rules).
final hasVotedProvider = StreamProvider.family<bool, String>((ref, matchId) {
  ref.watch(authStateProvider);
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return Stream.value(false);
  return ref
      .watch(firestoreProvider)
      .collection('matches')
      .doc(matchId)
      .collection('votes')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists);
});

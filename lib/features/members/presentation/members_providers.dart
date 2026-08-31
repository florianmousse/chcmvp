import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/models/user_model.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:chc_mvp/features/members/data/members_repository.dart';

final membersRepositoryProvider = Provider<MembersRepository>((ref) {
  return MembersRepository(
    ref.watch(firestoreProvider),
    ref.watch(serverClientProvider),
  );
});

/// [team] à null = tous les membres, toutes équipes confondues (utile pour
/// le tableau de bord admin ; passer une équipe pour filtrer, cf. bonus
/// "filtre par équipe" du cahier des charges).
final membersListProvider = StreamProvider.family<List<UserModel>, String?>((
  ref,
  team,
) {
  // Force la recréation du listener Firestore à chaque changement de compte
  // connecté (connexion/déconnexion/changement d'utilisateur). Sans ça, un
  // flux qui a déjà émis une erreur "permission-denied" (par ex. pendant la
  // brève fenêtre de déconnexion) reste mort indéfiniment — Firestore ne
  // relance pas tout seul un flux après une erreur de permission, et ce
  // provider n'étant pas recréé, l'app restait bloquée sur l'erreur même
  // après une reconnexion valide avec un autre compte.
  ref.watch(authStateProvider);
  return ref.watch(membersRepositoryProvider).watchMembers(team: team);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/models/user_model.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:chc_mvp/features/members/data/members_repository.dart';

final membersRepositoryProvider = Provider<MembersRepository>((ref) {
  return MembersRepository(
    ref.watch(firestoreProvider),
    ref.watch(serverClientProvider),
    reviewSpaceUid: ref.watch(reviewSpaceUidProvider),
  );
});

/// [team] à null = tous les membres, toutes équipes confondues (utile pour
/// le tableau de bord admin ; passer une équipe pour filtrer, cf. bonus
/// "filtre par équipe" du cahier des charges).
final membersListProvider = StreamProvider.autoDispose
    .family<List<UserModel>, String?>((ref, team) {
      // Cancel polling when the last consumer leaves or the identity changes.
      if (ref.watch(authStateProvider).value == null) return Stream.value([]);
      return ref.watch(membersRepositoryProvider).watchMembers(team: team);
    });

final managedMembersListProvider = StreamProvider<List<UserModel>>((ref) {
  if (!ref.watch(isAdminProvider)) return Stream.value([]);
  ref.watch(authStateProvider);
  return ref.watch(membersRepositoryProvider).watchAllMembers();
});

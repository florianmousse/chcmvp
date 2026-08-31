import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/models/team_model.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:chc_mvp/features/teams/data/teams_repository.dart';

final teamsRepositoryProvider = Provider<TeamsRepository>((ref) {
  return TeamsRepository(ref.watch(firestoreProvider));
});

final teamsListProvider = StreamProvider<List<TeamModel>>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(teamsRepositoryProvider).watchTeams();
});

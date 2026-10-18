import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/models/opponent_model.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:chc_mvp/features/opponents/data/opponents_repository.dart';

final opponentsRepositoryProvider = Provider<OpponentsRepository>((ref) {
  return OpponentsRepository(ref.watch(firestoreProvider));
});

final opponentsListProvider = StreamProvider<List<OpponentModel>>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(opponentsRepositoryProvider).watchOpponents();
});

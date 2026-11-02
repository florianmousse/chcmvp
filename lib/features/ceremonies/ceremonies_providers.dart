import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'ceremony_model.dart';

final ceremoniesProvider = StreamProvider<List<Ceremony>>((ref) {
  ref.watch(authStateProvider);
  final collection = ref.watch(appDatabaseProvider).collection('ceremonies');
  final query = ref.watch(isAdminProvider)
      ? collection
      : collection.where('status', whereIn: ['open', 'closed', 'cancelled']);
  return query.snapshots().map(
    (s) =>
        s.docs.map((d) => Ceremony.fromMap(d.id, d.data())).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
  );
});
final myCeremonyVoteProvider = StreamProvider.autoDispose
    .family<List<String>?, String>((ref, id) {
      final uid = ref.watch(currentUserProfileProvider).value?.uid;
      if (uid == null) return Stream.value(null);
      final revision =
          ref
              .watch(ceremoniesProvider)
              .value
              ?.where((e) => e.id == id)
              .firstOrNull
              ?.revision ??
          0;
      return ref
          .watch(appDatabaseProvider)
          .collection('ceremonies')
          .doc(id)
          .collection('votes')
          .doc(uid)
          .snapshots()
          .map(
            (d) => d.exists && (d.data()?['revision'] ?? 0) == revision
                ? List<String>.from(d.data()!['choices'])
                : null,
          );
    });

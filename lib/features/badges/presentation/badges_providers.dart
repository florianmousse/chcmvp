import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:chc_mvp/features/badges/data/badges_repository.dart';

final badgesRepositoryProvider = Provider<BadgesRepository>((ref) {
  return BadgesRepository(
    ref.watch(firestoreProvider),
    reviewSpaceUid: ref.watch(reviewSpaceUidProvider),
  );
});

/// Stream des badges gagnés pour un utilisateur donné.
/// Retourne Map<String (BadgeType.name), DateTime (date d'obtention)>.
final userBadgesProvider = StreamProvider.family<Map<String, DateTime>, String>(
  (ref, userId) {
    ref.watch(authStateProvider);
    return ref.watch(badgesRepositoryProvider).watchBadges(userId);
  },
);

/// Une seule écoute pour les distinctions affichées dans les classements.
final allBadgesProvider = StreamProvider<Map<String, Map<String, DateTime>>>((
  ref,
) {
  ref.watch(authStateProvider);
  return ref
      .watch(appDatabaseProvider)
      .collection('userBadges')
      .snapshots()
      .map(
        (s) => {
          for (final d in s.docs)
            d.id: {
              for (final e
                  in (d.data()['earned'] as Map<String, dynamic>? ?? {})
                      .entries)
                if (e.value is Timestamp)
                  e.key: (e.value as Timestamp).toDate(),
            },
        },
      );
});

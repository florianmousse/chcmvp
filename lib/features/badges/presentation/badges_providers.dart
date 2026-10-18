import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:chc_mvp/features/badges/data/badges_repository.dart';

final badgesRepositoryProvider = Provider<BadgesRepository>((ref) {
  return BadgesRepository(ref.watch(firestoreProvider));
});

/// Stream des badges gagnés pour un utilisateur donné.
/// Retourne Map<String (BadgeType.name), DateTime (date d'obtention)>.
final userBadgesProvider =
    StreamProvider.family<Map<String, DateTime>, String>((ref, userId) {
  ref.watch(authStateProvider);
  return ref.watch(badgesRepositoryProvider).watchBadges(userId);
});

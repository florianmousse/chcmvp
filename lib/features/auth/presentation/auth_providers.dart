import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chc_mvp/core/services/scoped_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/models/user_model.dart';
import 'package:chc_mvp/core/services/auth_service.dart';
import 'package:chc_mvp/core/services/server_client.dart';
import 'package:chc_mvp/core/utils/firestore_json.dart';

final firebaseAuthProvider = Provider<fb.FirebaseAuth>((ref) {
  return fb.FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Défini ici (plutôt que dans members_providers.dart, qui l'utilisait avant)
// pour qu'AuthService puisse aussi en dépendre sans créer d'import circulaire
// entre les deux fichiers.
final authServerClientProvider = Provider<ServerClient>(
  (ref) => ServerClient(),
);
final serverClientProvider = Provider<ServerClient>((ref) {
  final scope = ref.watch(reviewSpaceUidProvider);
  return ServerClient(reviewSpace: () => scope);
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(authServerClientProvider),
  );
});

/// Émet null si déconnecté, sinon le firebase_auth.User courant.
final authStateProvider = StreamProvider<fb.User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Charge le profil Firestore (rôle, équipe, etc.) correspondant à l'utilisateur connecté.
/// C'est CE provider qu'il faut utiliser dans l'UI pour savoir si l'utilisateur est admin,
/// pas le User Firebase Auth brut qui ne contient pas le rôle métier.
final accountProfileProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return Stream.value(null);

  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(authState.uid)
      .snapshots()
      .map(
        (doc) => doc.exists
            ? UserModel.fromJson(
                sanitizeFirestoreJson({...doc.data()!, 'uid': doc.id}),
              )
            : null,
      );
});

final isAdminProvider = Provider<bool>((ref) {
  final profile = ref.watch(currentUserProfileProvider).value;
  return profile?.isAdmin == true || profile?.isReviewer == true;
});

final isReviewerProvider = Provider<bool>(
  (ref) => ref.watch(currentUserProfileProvider).value?.isReviewer ?? false,
);
final canManageMatchesProvider = Provider<bool>(
  (ref) => ref.watch(isAdminProvider) || ref.watch(isReviewerProvider),
);

// A reviewer cannot choose or leave their namespace. Only real admins can inspect another space.
final inspectedReviewSpaceProvider = StateProvider<String?>((ref) {
  ref.watch(authStateProvider.select((state) => state.asData?.value?.uid));
  return null;
});
final reviewSpaceUidProvider = Provider<String?>((ref) {
  final account = ref.watch(accountProfileProvider).value;
  if (account?.isReviewer == true) return account!.uid;
  return account?.isAdmin == true
      ? ref.watch(inspectedReviewSpaceProvider)
      : null;
});
final appDatabaseProvider = Provider<ScopedFirestore>(
  (ref) => ScopedFirestore(
    ref.watch(firestoreProvider),
    ref.watch(reviewSpaceUidProvider),
  ),
);
final reviewSpaceReadyProvider = FutureProvider<void>((ref) async {
  if (ref.watch(reviewSpaceUidProvider) != null) {
    await ref.read(serverClientProvider).post('/review-space', {});
  }
});
final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final account = ref.watch(accountProfileProvider).value;
  if (account == null ||
      !account.isActive ||
      ref.watch(reviewSpaceUidProvider) == null) {
    return Stream.value(account);
  }
  return ref
      .watch(appDatabaseProvider)
      .collection('users')
      .doc(account.uid)
      .snapshots()
      .map(
        (doc) => doc.exists
            ? UserModel.fromJson(
                sanitizeFirestoreJson({
                  ...doc.data()!,
                  'uid': account.uid,
                  'role': account.role.name,
                  'isActive': account.isActive,
                }),
              )
            : account,
      );
});

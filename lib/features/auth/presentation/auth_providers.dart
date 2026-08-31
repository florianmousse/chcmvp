import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
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
final serverClientProvider = Provider<ServerClient>((ref) => ServerClient());

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(serverClientProvider),
  );
});

/// Émet null si déconnecté, sinon le firebase_auth.User courant.
final authStateProvider = StreamProvider<fb.User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Charge le profil Firestore (rôle, équipe, etc.) correspondant à l'utilisateur connecté.
/// C'est CE provider qu'il faut utiliser dans l'UI pour savoir si l'utilisateur est admin,
/// pas le User Firebase Auth brut qui ne contient pas le rôle métier.
final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
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
  return ref.watch(currentUserProfileProvider).value?.isAdmin ?? false;
});

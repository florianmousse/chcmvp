import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:chc_mvp/core/services/server_client.dart';

/// Fine couche au-dessus de FirebaseAuth : centralise les erreurs traduites
/// en français et garde `data/` indépendant du SDK dans le reste de l'app.
class AuthService {
  AuthService(this._auth, this._server);
  final FirebaseAuth _auth;
  final ServerClient _server;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// À appeler une seule fois au démarrage de l'app (voir main.dart), avant
  /// tout appel à signInWithGoogle — obligatoire depuis google_sign_in v7.
  Future<void> initializeGoogleSignIn() => _googleSignIn.initialize();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapError(e));
    }
  }

  /// La création de compte membre se fait normalement via l'admin
  /// (voir MembersRepository.inviteMember côté serveur), mais cette méthode
  /// reste utile pour un flux d'auto-inscription si le club le souhaite.
  Future<UserCredential> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapError(e));
    }
  }

  /// Passe par notre serveur (e-mail personnalisé au nom et à la couleur du
  /// club) plutôt que par Firebase directement, qui enverrait sinon depuis
  /// noreply@chc-mvp.firebaseapp.com — voir server/src/routes/auth.ts.
  /// Route volontairement publique côté serveur : quelqu'un qui a oublié
  /// son mot de passe n'est par définition pas connecté.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _server.post('/auth/forgot-password', {'email': email});
    } catch (e) {
      throw AuthFailure('Une erreur est survenue, réessaie dans un instant.');
    }
  }

  /// Membre déjà invité par l'admin qui préfère se connecter via son compte
  /// Google plutôt que par mot de passe (même e-mail des deux côtés).
  Future<UserCredential> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw AuthFailure(
          'cancelled',
        ); // annulé par l'utilisateur, pas une vraie erreur
      }
      throw AuthFailure(
        'Connexion Google échouée : ${e.code} — ${e.description ?? "(pas de détail)"}',
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw AuthFailure(
          'Ce compte utilise déjà une connexion par e-mail/mot de passe. '
          'Utilise plutôt cette option, ou contacte un administrateur.',
        );
      }
      throw AuthFailure(_mapError(e));
    } catch (e) {
      throw AuthFailure('Connexion Google échouée : $e');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Aucun compte ne correspond à cet e-mail.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cet e-mail.';
      case 'weak-password':
        return 'Le mot de passe est trop faible (6 caractères minimum).';
      case 'user-disabled':
        return 'Ce compte a été désactivé par un administrateur.';
      default:
        return 'Une erreur est survenue (${e.code}).';
    }
  }
}

class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/models/match_model.dart';
import 'package:chc_mvp/core/navigation/navigator_key.dart';
import 'package:chc_mvp/core/services/local_notifications_service.dart';
import 'package:chc_mvp/core/services/messaging_service.dart';
import 'package:chc_mvp/core/utils/firestore_json.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:chc_mvp/features/members/presentation/members_providers.dart';
import 'package:chc_mvp/features/voting/presentation/vote_screen.dart';

final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

final localNotificationsServiceProvider = Provider<LocalNotificationsService>((
  ref,
) {
  return LocalNotificationsService();
});

final messagingServiceProvider = Provider<MessagingService>((ref) {
  return MessagingService(
    ref.watch(firebaseMessagingProvider),
    ref.watch(firestoreProvider),
    ref.watch(localNotificationsServiceProvider),
  );
});

/// À observer une fois quelque part en haut de l'arbre de widgets (voir
/// HockeyClubApp dans main.dart) pour enregistrer/retirer le token FCM à la
/// connexion/déconnexion, ET pour amener directement sur l'écran de vote
/// quand on tape une notification d'ouverture de vote — dans les 3 cas
/// possibles : app fermée, en arrière-plan, ou déjà ouverte.
final messagingSyncProvider = Provider<void>((ref) {
  ref.listen(authStateProvider, (previous, next) {
    final service = ref.read(messagingServiceProvider);
    final wasSignedIn = previous?.value != null;
    final nowSignedIn = next.value != null;

    if (!wasSignedIn && nowSignedIn) {
      service.initForUser(
        next.value!.uid,
        onNotificationTap: (matchId) => _openVoteFromNotification(ref, matchId),
      );
    } else if (wasSignedIn && !nowSignedIn) {
      service.clearTokenForUser(previous!.value!.uid);
    }
  });

  // Cas 2 : l'app tournait en arrière-plan et l'utilisateur tape la notif.
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    _openVoteFromNotification(ref, message.data['matchId']);
  });

  // Cas 3 : l'app était complètement fermée et s'est lancée via la notif.
  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      _openVoteFromNotification(ref, message.data['matchId']);
    }
  });
});

Future<void> _openVoteFromNotification(Ref ref, String? matchId) async {
  if (matchId == null) return;
  final navigator = rootNavigatorKey.currentState;
  if (navigator == null) return;

  try {
    final firestore = ref.read(firestoreProvider);
    final matchDoc = await firestore.collection('matches').doc(matchId).get();
    if (!matchDoc.exists) return;

    final match = MatchModel.fromJson(
      sanitizeFirestoreJson({...matchDoc.data()!, 'id': matchDoc.id}),
    );
    if (match.status != MatchStatus.votingOpen)
      return; // vote déjà clôturé entre-temps

    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid != null) {
      final voteDoc = await firestore
          .collection('matches')
          .doc(matchId)
          .collection('votes')
          .doc(uid)
          .get();
      if (voteDoc.exists) return; // déjà voté, rien à faire
    }

    final members = await ref.read(membersListProvider(null).future);
    final candidates = members
        .where((m) => match.presentPlayerIds.contains(m.uid))
        .toList();

    navigator.push(
      MaterialPageRoute(
        builder: (_) => VoteScreen(match: match, candidates: candidates),
      ),
    );
  } catch (e) {
    debugPrint('Erreur navigation depuis notification : $e');
  }
}

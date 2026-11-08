# Notifications web

Le client web utilise le même projet Firebase `chc-mvp` et les mêmes tableaux
`users/{uid}.fcmTokens` que l'application Android. Le serveur existant envoie
déjà les messages FCM avec `notification` et `data` : aucun changement serveur
n'est requis pour les notifications web.

La clé **publique** VAPID fournie pour ce projet est intégrée au client.
Pour un autre projet, configurer sa clé avec
`--dart-define=WEB_PUSH_VAPID_KEY=...`. Le script Vercel accepte également la
variable de build `WEB_PUSH_VAPID_KEY`. Ne pas fournir de clé privée.

Le déploiement doit servir `firebase-messaging-sw.js` en JavaScript à la racine
du même domaine HTTPS, sans redirection ni authentification. Firebase enregistre
ce worker lors de l'abonnement. Sa version SDK doit rester cohérente avec
`firebase_core_web` (actuellement SDK JS 10.11.1).

## Vérification sur iPhone après déploiement

1. Sur iOS 16.4 minimum, ouvrir le site dans Safari : le guide apparaît.
2. Fermer le guide : il reste masqué après rechargement ; les instructions
   restent accessibles dans Profil et dans le tutoriel.
3. Partager → Sur l'écran d'accueil, puis ouvrir l'icône CHC MVP.
4. Se connecter avec un membre actif et toucher « Activer les notifications ».
   La demande système doit apparaître uniquement après cette action.
5. Accepter : vérifier la confirmation dans Profil et l'ajout d'un token dans
   la fiche du membre. En cas de refus, vérifier les instructions de réglage.
6. Avec un compte administrateur, utiliser un match de test pour déclencher
   une alerte sans notifier les membres. Tester au premier plan (bandeau),
   en arrière-plan et avec l'application fermée (notification système).
7. Toucher la notification : vérifier l'ouverture du match. Tester aussi une
   cérémonie. Si la session a expiré, le lien attend la reconnexion.
8. Se déconnecter : le token est invalidé et retiré du profil. Vérifier que
   cet appareil ne reçoit plus les alertes de l'ancien compte.
9. Vérifier le parcours existant Android et un navigateur sans support push.

Tests automatisés : `node --test scripts/web-push.test.mjs`,
`flutter test test/web_compatibility_test.dart test/participation_help_test.dart`,
et `flutter build web --release --no-web-resources-cdn`.
La compilation et les tests de navigation simulés ne remplacent pas un test
de réception réelle sur iPhone avec l'autorisation système accordée.

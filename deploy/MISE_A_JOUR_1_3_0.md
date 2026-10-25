# Version 1.3.0 (6) : corriger un bulletin et mieux lire le suivi

## Réinitialiser le vote d'un joueur

Avec un compte administrateur, ouvrir **Voir le suivi → Ont voté** sur le match. Cliquer **Réinitialiser le vote** sous le nom du joueur, puis confirmer. Seul ce bulletin est supprimé ; le match, ses participants et les autres bulletins restent intacts. Le joueur revient dans **En attente** et son bouton de vote redevient disponible grâce au suivi Firestore existant.

L'action est autorisée uniquement pour un administrateur actif, lorsque le match est au statut **Vote ouvert** et que sa période de participation n'est pas expirée. Sur un match terminé, utiliser d'abord **Rouvrir le vote**, puis clôturer manuellement après correction. Une réinitialisation ne prolonge pas la période d'un vote ordinaire.

Le compteur et les listes sont rechargés après l'action. Les résultats définitifs seront calculés à la clôture habituelle ; les matchs ouverts ne contribuent pas au classement. Aucune reconstruction manuelle n'est nécessaire pour cette fonctionnalité. Les matchs de test restent isolés et leur bulletin peut également être réinitialisé depuis le suivi admin.

## Nouveau suivi

- Deux vues : **En attente** et **Ont voté**.
- Noms en gras dans des cartes séparées, sur plusieurs lignes si nécessaire.
- Les joueurs sans compte sont regroupés en bas des non-votants ; ils restent inclus dans le total des présents.
- Le suivi expose les noms et l'état de participation, jamais les trois choix d'un bulletin réel.
- Une confirmation périmée ne peut pas supprimer un nouveau bulletin : le serveur compare la version exacte du vote dans une transaction, en vérifiant aussi le statut du match. Les clics répétés et les changements intervenus pendant la confirmation sont refusés avec un message d'actualisation.

## Installer

1. Installer **le backend en premier** avec `build/chc-backend-update.tar.gz`, selon [la procédure VPS](AUDIT_STATS_CLASSEMENTS.md#installer-cette-version). Le nouveau fichier `src/resetVote.ts` est nécessaire. Le suivi ajoute `voted` et `canReset` ; la route admin `POST /matches/:matchId/votes/:voterUid/reset` reçoit `voteVersion`.
2. Publier les changements Git pour redéployer Vercel, puis distribuer la nouvelle version Android. Le numéro de version du profil devient **1.3.0 (6)**. Si un numéro Android supérieur a déjà été distribué, utiliser un numéro de build supérieur.
3. Vérifier avec un match de test : simuler deux bulletins, réinitialiser l'un d'eux et vérifier que l'autre reste présent ; enregistrer un nouveau bulletin puis clôturer. Vérifier que la réinitialisation disparaît après clôture.

Aucun changement de `.env`, d'index ni des règles Firestore n'est requis par rapport à 1.2.0. Les suppressions directes par les clients restent interdites, y compris pour les admins : seule la route serveur peut supprimer un bulletin après vérification. Les anciennes versions continuent à lire le suivi sans disposer du nouveau bouton. Les textes d'aide et les conditions d'utilisation décrivent désormais cette correction possible pendant le vote.

## Vérifications

Les tests serveur utilisent uniquement l'émulateur local avec le projet fictif `demo-chc-audit`. Les tests de règles utilisent `demo-chc-web`. Ils couvrent permissions, état et échéances du match, conservation des autres bulletins, nouveau vote, ancienne confirmation, doubles clics, confidentialité et isolation des tests. Les tests Flutter couvrent annulation/confirmation/refus, actualisation du compteur, tri des joueurs sans compte, noms longs et texte agrandi sur téléphone, ainsi que la présentation sur ordinateur.

Validation du 26 octobre 2026 : **60 tests Flutter, 17 tests unitaires serveur, 17 tests d'intégration serveur et 19 tests de règles Firestore réussis**. Compilation TypeScript, web release et APK Android debug réussies. L'analyse Dart ciblée ne signale aucune erreur, seulement la dépréciation préexistante de `TickerMode.of`. L'APK debug valide la compilation ; la distribution Android doit suivre la procédure de signature habituelle. Aucun déploiement en production n'a été effectué pendant ces vérifications.

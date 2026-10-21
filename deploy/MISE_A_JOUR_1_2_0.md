# Version 1.2.0 (4) : réouverture des votes

## Utilisation

Dans **Administration → Matchs → menu d'un vote terminé → Rouvrir le vote**, confirmer la réouverture. Les bulletins sont conservés. Sur un vrai match, les joueurs ayant déjà voté ne peuvent pas voter une seconde fois ; les autres présents peuvent compléter leur vote.

Le serveur retire les anciens résultats et reconstruit les classements, statistiques et badges sans ce match. Le menu **Clôturer le vote** déclenche leur recalcul à partir de tous les bulletins conservés et ajoutés. Le libellé **Vote rouvert · clôture manuelle** reste visible tant que le vote est ouvert.

Une réouverture désactive définitivement la clôture automatique de cette session de vote, y compris après redémarrage du VPS ou modification des durées du club. Les admins reçoivent un premier rappel au prochain passage du serveur (toutes les 10 minutes), puis au plus un rappel toutes les 24 heures. La date du dernier rappel est conservée en base. Les rappels s'arrêtent à la clôture ou à la suppression. Sur Android, toucher le rappel ouvre la gestion des matchs, même si l'admin a déjà voté. Les push nécessitent un token valide et l'autorisation Android ; le web conserve son fonctionnement sans push.

Les tests restent isolés : réouverture via le même bouton, bulletins simulés modifiables, notifications **[TEST]** aux seuls admins, aucun effet sur les résultats du club.

Le classement masque désormais les joueurs à zéro point, y compris dans un ancien cache. Un joueur hors podium conserve ses votes reçus dans ses statistiques. Les ex æquo ayant des points restent tous affichés, même s'ils sont plus de trois.

## Installation

1. Installer d'abord le **backend VPS** à partir de `build/chc-backend-update.tar.gz`, selon [la procédure existante](AUDIT_STATS_CLASSEMENTS.md#installer-cette-version). L'archive inclut le nouveau module `src/votingLifecycle.ts` et la route admin `POST /matches/:matchId/reopen`. Aucun changement de `.env` n'est nécessaire. Conserver le compte de service existant.
2. Publier les **règles Firestore** depuis la racine du projet :

   ```powershell
   firebase deploy --only firestore:rules --project chc-mvp
   ```

   La transition d'un vote terminé vers un vote ouvert est réservée au serveur. Les clients ne peuvent pas désactiver le marqueur de clôture manuelle ou lui réattribuer une échéance. Les anciennes versions pourront toujours consulter les matchs et clôturer un vote, mais leur ancienne réouverture directe des tests sera refusée.
3. Publier les changements Git pour redéployer **Vercel**, puis distribuer l'application **Android** avec la procédure habituelle. La version passe à `1.2.0+4` ; choisir un numéro de build supérieur si une version Android plus récente a déjà été distribuée.
4. Dans Administration, utiliser une fois **Reconstruire les classements maintenant** pour retirer également les entrées à zéro des caches existants.
5. Vérifier d'abord avec un **match de test** : clôturer, rouvrir, constater la mention de clôture manuelle, simuler un autre bulletin, puis clôturer à nouveau. Vérifier la réception du rappel sur un appareil admin autorisant les notifications.

La reconstruction des agrégats est progressive, pas une transaction globale. En cas d'erreur après la transition, le vote reste protégé de la clôture automatique ; relancer **Reconstruire les classements maintenant** termine la correction des totaux réels. La route de réouverture accepte aussi une nouvelle tentative sur un vote déjà rouvert sans effacer ses bulletins ni réinitialiser ses rappels. Le serveur doit continuer à tourner en un seul processus pour partager la file des recalculs.

## Vérifications locales

Les suites Flutter, serveur et règles utilisent des fixtures et l'émulateur local, sans données de production. Les nouveaux cas couvrent la conservation des votes, l'exclusion puis le retour des points, le retrait des badges, les permissions, les doubles votes, les rappels répétés/concurrents, les échecs d'envoi, l'isolation des tests et les lignes à zéro. Aucun push réel n'est envoyé par les tests.

Validation du 21 octobre 2026 : **55 tests Flutter, 17 tests unitaires serveur, 15 tests d'intégration serveur et 18 tests de règles Firestore réussis**. Compilation TypeScript, compilation web release et APK Android debug réussies. L'analyse ciblée des écrans, du classement et des nouveaux tests ne signale aucune anomalie ; les avertissements préexistants du reste du projet ne sont pas corrigés dans cette version. L'APK debug est une vérification de compilation, pas une publication Android signée pour distribution.

```powershell
flutter test --no-pub
npm --prefix server run build
npm --prefix server test
# Avec l'émulateur local démarré et les règles chargées :
$env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8087'
npm --prefix server run test:emulator
node --test firestore/vote-rules.test.mjs
```

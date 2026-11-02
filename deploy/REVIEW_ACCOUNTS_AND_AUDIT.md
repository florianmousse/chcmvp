# Comptes de validation et journal

## Comportement

- Rôle `reviewer`, distinct de `admin`. La création se fait dans **Administration → Compte de validation**. L’adresse proposée est `chcmvp.chateaubourghockeyclub@gmail.com`.
- Le serveur crée un nouveau compte Firebase Auth, sans modifier un compte existant et sans envoyer d’e-mail. Le mot de passe aléatoire est affiché une seule fois à l’admin ; il n’est pas stocké dans Firestore ni dans les logs.
- Les testeurs consultent l’application et gèrent **leurs propres matchs** via l’onglet Validation : création, modification, présence, score, statistiques, simulation de votes, clôture, réouverture et suppression.
- Toute création est forcée dans `test_matches`, avec un ID `test:…`. Le serveur inscrit `reviewCreatedBy` et `reviewSource`. Les admins voient la mention « Équipe de validation ». Les membres n’ont accès ni au match ni à ses sous-collections, même via une ancienne app.
- Ces matchs ne déclenchent aucune notification, y compris aux admins, lors de l’ouverture, de la clôture ou des rappels. Les tests ordinaires créés par les admins conservent leur comportement existant.
- Les matchs de validation restent exclus des classements et badges. Les comptes de validation sont retirés des listes de joueurs de l’app et ne peuvent pas être inscrits à un match réel ou voter dans un match/cérémonie réel.
- Le testeur ne peut pas créer ou modifier des membres, équipes, adversaires, cérémonies ou réglages du club. Il peut modifier son propre profil. Il utilise les équipes et adversaires existants pour ses matchs de test.
- Un admin peut désactiver ou supprimer le compte depuis Membres. Sa promotion en admin est bloquée. Supprimer le compte ne supprime pas ses matchs : ceux-ci restent identifiés, silencieux et accessibles aux admins pour nettoyage.

## Journal

**Administration → Journal des actions** : dernières entrées d’abord, heure locale avec secondes, UID et nom de l’auteur, rôle, action, objet, état, détails, recherche dans les entrées chargées et chargement progressif.

- Les créations/modifications de matchs, statistiques, profils, équipes et adversaires passent par `/data`. L’écriture et l’entrée avant/après sont dans la même transaction Firestore.
- Les actions serveur de gestion des membres, matchs et cérémonies sont enregistrées avant exécution, puis marquées réussies ou échouées avec le statut HTTP et l’identifiant retourné, si présent. Le contenu de la requête n’est jamais conservé. Une erreur peut avoir des effets partiels (ex. compte créé mais invitation non remise) ; le journal ne promet pas un rollback de Firebase Auth ou des e-mails.
- Une interruption peut laisser une entrée `pending` : l’interface affiche « En cours / résultat inconnu », jamais un succès supposé. Vérifier l’objet avant de réessayer. Les erreurs de mise à jour de l’état sont aussi inscrites dans les logs du serveur.
- L’ouverture et la clôture automatiques portent l’auteur `system` et sont enregistrées atomiquement avec le changement de statut.
- Les choix de votes, mots de passe, tokens FCM et jetons de connexion sont exclus. Les votes ordinaires de matchs, déposés directement dans Firestore, ne sont pas recopiés dans ce journal ; les actions serveur de simulation, réinitialisation et votes de cérémonies y figurent sans leurs choix. Les recalculs dérivés et la maintenance des tokens ne génèrent pas une entrée par document.
- Lecture réservée aux admins actifs ; aucune création, modification ou suppression du journal par un client, même admin. Les credentials Admin SDK gardent leurs privilèges : ce journal n’est pas une protection contre un opérateur ayant accès au serveur/Firebase.
- Pas de reconstitution de l’historique antérieur au déploiement, ni d’effacement automatique des journaux.

## Mise en service coordonnée

1. Déployer le backend incluant `/data` et `/members/review-account` (`npm ci`, `npm run build`, redémarrage du service selon le guide VPS).
2. Publier l’app Flutter actualisée et sa version web. Vérifier depuis le compte admin la création/modification d’un match et son apparition dans le journal.
3. Déployer `firestore/firestore.rules`. Cette étape ferme les anciennes écritures directes de gestion : **les anciennes versions de l’app ne pourront plus gérer matchs/profils/équipes/adversaires**. Les lectures et votes ordinaires restent disponibles.
4. Avant de créer le compte, s’assurer que les clients ont reçu le nouveau modèle de rôle : les anciens binaires décodent uniquement `admin`/`member` et risquent une erreur en lisant une fiche `reviewer`. Prévoir une mise à jour obligatoire avant l’activation en production.
5. Créer le compte depuis Administration → Compte de validation, conserver le mot de passe dans un gestionnaire de mots de passe et remplacer les identifiants fournis dans l’accès à l’application de Google Play Console. Les identifiants de l’admin précédemment partagés doivent être renouvelés et ses sessions révoquées.
6. Se connecter avec le compte de validation, créer un match, simuler puis clôturer les votes. Vérifier le marquage depuis l’admin, l’absence depuis un compte membre et l’absence de notifications.

Le code ne crée pas de compte en production au build et ne déploie pas les règles automatiquement. Aucun nettoyage automatique des anciens matchs réels créés lors de la validation : leur identification et leur suppression nécessitent une vérification admin.

## Tests locaux

Depuis `server` : `npm run build`, `npm test`.

Depuis la racine, avec Java 21+ :

```powershell
firebase emulators:exec --config firestore/emulator.json --project demo-chc-web --only firestore "node --test firestore/vote-rules.test.mjs server/test/rankings.emulator.test.cjs server/test/ceremonies.emulator.test.cjs server/test/review-audit.emulator.test.cjs"
flutter test --no-pub
```

Les tests d’intégration exigent un émulateur loopback et utilisent exclusivement des projets `demo-*`.

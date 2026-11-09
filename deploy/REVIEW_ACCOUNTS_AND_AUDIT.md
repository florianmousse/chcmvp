# Comptes de validation et journal

## Espace de démonstration complet

- Le compte réel garde le rôle `reviewer`, distinct de `admin`. Sa création reste dans **Administration → Compte de validation**, avec l'adresse proposée `chcmvp.chateaubourghockeyclub@gmail.com`. Le seul véritable compte Firebase Auth créé est ce compte d'accès ; son mot de passe aléatoire est affiché une fois, jamais inscrit dans les logs.
- À sa première connexion, le serveur prépare atomiquement `review_spaces/{uid}` avec le profil du testeur, cinq joueurs fictifs, une équipe et un adversaire de démonstration. Aucun historique ou profil de membre du club n'est copié.
- Le testeur utilise les mêmes écrans que l'application habituelle : création de matchs et de cérémonies, présence, scores, statistiques, votes en son nom, clôture, réouverture, révélation, trophées, classements, badges, gestion des membres, équipes et adversaires.
- Il dispose des fonctions d'administration **dans son espace seulement**. Son rôle et ses permissions réels restent `reviewer`. Il ne peut ni sélectionner l'espace d'un autre testeur ni sortir vers les données réelles. Le choix du namespace est imposé côté serveur d'après l'identité Firebase, même si l'application n'envoie aucun en-tête.
- Les classements, badges, trophées et statistiques fonctionnent normalement, dans des collections locales à cet espace. Un match ordinaire de démonstration n'a donc pas besoin d'être coché « Match de test » ; cette option conserve son usage de simulation de bulletins, hors classement de l'espace.
- Les comptes de membres créés/invités dans cet espace sont des simulations : **aucun utilisateur Firebase Auth supplémentaire, aucun e-mail envoyé, aucun mot de passe de membre réel modifié**. Même saisir l'adresse ou l'identifiant d'un vrai membre n'agit que sur les données de démonstration.
- Toutes les notifications sont coupées : matchs, rappels automatiques, résultats, cérémonies et badges. Les cérémonies ne créent pas de tâche de notification ; leur processeur refuse aussi les bases de démonstration. Les fonctions d'envoi SMTP/FCM ont une garde supplémentaire liée au contexte.
- Le bandeau permanent « Validation · données de démonstration » rappelle l'isolation et les invitations simulées. Les admins du club ouvrent **Administration → Espaces de validation** pour consulter ou modifier les données de chaque testeur, puis utilisent « Revenir au club ». Le journal affiché est celui de l'espace sélectionné.
- Un admin peut désactiver le compte réel depuis Membres ; le serveur et les règles Firestore coupent immédiatement l'accès du testeur. L'admin peut toujours inspecter un espace désactivé. La suppression du compte ne supprime pas automatiquement ses données de démonstration.
- Les anciens matchs de validation éventuellement présents dans la collection racine `test_matches` ne sont ni déplacés ni supprimés automatiquement. Les admins du club les conservent dans leur ancienne liste ; le nouveau parcours du testeur utilise son espace complet.

## Isolation technique

- Le contexte asynchrone de chaque requête authentifiée sélectionne une façade Firestore qui préfixe les chemins par `review_spaces/{uid}/`. Les services métier réutilisent leurs validations existantes. Toute nouvelle fonction serveur doit importer `getFirestore` depuis `database.ts`, et non directement depuis le SDK Admin.
- Seul un véritable admin actif peut demander un espace par `X-Review-Space`. L'en-tête d'un testeur ne peut pas remplacer son propre espace. Le frontend conserve un client serveur par espace pour qu'une action encore en cours ne bascule pas vers le club lors d'un changement d'écran.
- Les règles Firestore refusent au testeur les collections réelles du club (hors sa propre fiche d'authentification et les anciens tests dont il était propriétaire). Elles n'autorisent la lecture que de son espace et les votes normaux dans ses matchs. Les écritures de gestion restent exclusivement côté serveur.
- Les tâches automatiques des espaces tournent toutes les dix minutes, avec les mêmes calculs mais sans notifications. Les files de recalcul sont séparées de celle du club. Les listeners de production ne surveillent pas les sous-collections des espaces.
- Les règles bloquent toujours les écritures directes sur `settings` et `seasons` ; aucune interface supplémentaire d'édition de ces collections n'a été ajoutée.

## Journal

**Administration → Journal des actions** : dernières entrées d'abord, heure locale avec secondes, UID et nom de l'auteur, rôle, action, objet, état, détails, recherche dans les entrées chargées et chargement progressif.

- Les créations/modifications de matchs, statistiques, profils, équipes et adversaires passent par `/data`. L'écriture et l'entrée avant/après sont dans la même transaction Firestore.
- Les actions serveur de gestion des membres, matchs et cérémonies sont enregistrées avant exécution, puis marquées réussies ou échouées avec le statut HTTP et l'identifiant retourné, si présent. Le contenu de la requête n'est jamais conservé. Une erreur peut avoir des effets partiels (ex. compte créé mais invitation non remise) ; le journal ne promet pas un rollback de Firebase Auth ou des e-mails.
- Une interruption peut laisser une entrée `pending` : l'interface affiche « En cours / résultat inconnu », jamais un succès supposé. Vérifier l'objet avant de réessayer. Les erreurs de mise à jour de l'état sont aussi inscrites dans les logs du serveur.
- L'ouverture et la clôture automatiques portent l'auteur `system` et sont enregistrées atomiquement avec le changement de statut.
- Les choix de votes, mots de passe, tokens FCM et jetons de connexion sont exclus. Les votes ordinaires de matchs, déposés directement dans Firestore, ne sont pas recopiés dans ce journal ; les actions serveur de simulation, réinitialisation et votes de cérémonies y figurent sans leurs choix. Les recalculs dérivés et la maintenance des tokens ne génèrent pas une entrée par document.
- Le journal réel est réservé aux admins actifs. Le testeur peut lire uniquement le journal de son propre espace ; aucune création, modification ou suppression du journal par un client, même admin. Les credentials Admin SDK gardent leurs privilèges : ce journal n'est pas une protection contre un opérateur ayant accès au serveur/Firebase.
- Pas de reconstitution de l'historique antérieur au déploiement, ni d'effacement automatique des journaux.

## Mise en service coordonnée

1. Déployer le backend incluant `/data`, `/review-space`, `/members/review-account` et le contexte isolé (`npm ci`, `npm run build`, redémarrage du service selon le guide VPS).
2. Publier l'app Flutter actualisée et sa version web. Vérifier depuis le compte admin la création/modification d'un match et son apparition dans le journal.
3. Déployer `firestore/firestore.rules`. Cette étape ferme les anciennes écritures directes de gestion : **les anciennes versions de l'app ne pourront plus gérer matchs/profils/équipes/adversaires**. Les lectures et votes ordinaires des membres du club restent disponibles. Les anciennes versions du compte de validation doivent être mises à jour pour utiliser son espace.
4. Avant de créer le compte, s'assurer que les clients ont reçu le nouveau modèle de rôle : les anciens binaires décodent uniquement `admin`/`member` et risquent une erreur en lisant une fiche `reviewer`. Prévoir une mise à jour obligatoire avant l'activation en production.
5. Créer le compte depuis Administration → Compte de validation, conserver le mot de passe dans un gestionnaire de mots de passe et remplacer les identifiants fournis dans l'accès à l'application de Google Play Console. Les identifiants de l'admin précédemment partagés doivent être renouvelés et ses sessions révoquées.
6. Se connecter avec le compte de validation. Créer un match ordinaire et une cérémonie, voter puis clôturer. Vérifier les résultats dans l'espace, son bandeau depuis l'admin, l'absence depuis un compte membre et l'absence de notifications. Tester aussi une invitation : elle doit rester simulée.

Le code ne crée pas de compte en production au build et ne déploie pas les règles automatiquement. Aucun nettoyage automatique des anciens matchs réels créés lors de la validation : leur identification et leur suppression nécessitent une vérification admin.

## Tests locaux

Depuis `server` : `npm run build`, `npm test`.

Depuis la racine, avec Java 21+ :

```powershell
firebase emulators:exec --config firestore/emulator.json --project demo-chc-web --only firestore "node --test firestore/vote-rules.test.mjs server/test/rankings.emulator.test.cjs server/test/ceremonies.emulator.test.cjs server/test/review-audit.emulator.test.cjs server/test/review-space.emulator.test.cjs"
flutter test --no-pub
```

Les tests d'intégration exigent un émulateur loopback et utilisent exclusivement des projets `demo-*`.

## Transition des lectures de profils

La route `/members/directory` utilise aussi la base isolée du testeur. Voir [AUDIT_CORRECTIONS.md](AUDIT_CORRECTIONS.md) pour les permissions, les nouveaux tests et la mise en service coordonnée Android/web.

# Audit complémentaire - 9 novembre 2026

Les constats ci-dessous décrivent l'état avant correction. Les changements locaux du 10 novembre et leurs vérifications figurent dans [AUDIT_CORRECTIONS_PHASE_2.md](AUDIT_CORRECTIONS_PHASE_2.md). Ils ne sont pas encore déployés.

## Périmètre et état

Référence examinée : `9af0810`, version locale `1.5.4+16`. Arbre Git propre avant cet audit. Les constats ci-dessous concernent le code local ; ils ne prouvent pas que chaque condition de déclenchement existe en production.

Aucune publication, mutation de données de production, demande de réinitialisation réelle, notification ni modification de l'historique Git n'a été effectuée. Les reproductions utilisent des valeurs synthétiques et des dépendances simulées, sans Firebase ni SMTP réels.

## Défauts à corriger

### 1. P1 - Liens de réinitialisation dans les journaux si SMTP manque

`server/src/mailer.ts:68-73` et `:105-110` journalisent le destinataire et le lien complet lorsque SMTP n'est pas configuré, puis retournent sans erreur. Ce lien permet de choisir un mot de passe. Une invitation peut également être annoncée comme réussie sans aucun envoi.

Reproduction locale sur le module compilé : appeler les deux fonctions avec SMTP absent et un lien synthétique produit deux journaux contenant le marqueur du lien ; les deux promesses se résolvent. Aucun message réel envoyé. La configuration SMTP de production et ses journaux n'ont pas été inspectés.

Correction attendue : refuser explicitement l'envoi si la configuration manque, ne journaliser aucun lien ni destinataire, conserver la réponse publique non discriminante du parcours de réinitialisation. Tester les fonctions d'envoi elles-mêmes, pas seulement un expéditeur injecté dans le contrôleur. Si cette configuration a réellement manqué en production, vérifier en privé la présence de liens dans les journaux et traiter les liens encore utilisables avec le responsable.

### 2. P1 - Traitements de vote perdus après panne ou redémarrage

`server/src/matchListeners.ts:27-36` ignore les traitements du premier instantané. Aux lignes 49-68, le statut est mémorisé avant la réussite du traitement et les échecs sont seulement journalisés. Le cron de `server/src/scheduledVoting.ts` examine les matchs à venir et ouverts, mais ne répare pas les matchs clos en production. La maintenance des espaces de review, elle, recalcule les matchs clos.

Reproduction du module compilé avec Firestore simulé : un match déjà clos au démarrage déclenche zéro recomputation ; une clôture dont le calcul échoue, suivie d'un événement de même statut, ne produit qu'une tentative. Un arrêt entre la clôture et son calcul peut donc laisser les résultats incomplets. Une ouverture manuelle interrompue avant l'initialisation de l'échéance peut également rester sans clôture automatique, car le cron ignore les votes sans `votingClosesAt`.

Correction attendue : travail durable et rejouable, réconciliation au démarrage et reprise bornée. Séparer la réparation des résultats de l'envoi des notifications pour éviter un renvoi à tout le club. Tester interruption, redémarrage, échec transitoire et absence de double attribution.

### 3. P1 - Calendrier des votes dépendant du fuseau du serveur

`server/src/scheduledVoting.ts:14-18` combine la date et l'heure avec `Date.setHours`, qui utilise le fuseau du processus. Le formulaire Flutter conserve la date locale du sélecteur (`lib/features/matches/presentation/match_form_screen.dart:449-455`, `:487`) puis l'envoie sous forme d'instant UTC. Le service systemd du dépôt ne fixe pas de fuseau.

Reproduction avec la fonction compilée : pour le 11 juillet 2026 à minuit en France (`2026-07-10T22:00:00Z`) et l'heure `15:00`, un processus UTC obtient `2026-07-10T15:00:00Z`, contre `2026-07-11T13:00:00Z` sous Europe/Paris. L'écart atteint 22 heures. Le fuseau effectif du VPS n'a pas été vérifié.

Correction attendue : définir explicitement la date civile et Europe/Paris, maintenir la compatibilité des données existantes, tester été/hiver et appareils dans un autre fuseau. Ne pas convertir en masse les dates existantes sans inventaire et procédure de migration.

### 4. P2 - Résultats périmés après modification d'un match clos

`server/src/routes/data.ts:14` autorise notamment la date, les présences et le barème sur un match clos. Le recalcul après écriture aux lignes 94-98 ne concerne que les espaces de review. Le listener de production ne réagit qu'au changement de statut ou de type (`server/src/matchListeners.ts:52-57`). Une date modifiée sans changement de type/statut peut laisser les classements mensuels et saisonniers dans l'ancienne période ; un barème modifié via l'API peut laisser les anciens points.

Constat par lecture des chemins d'écriture et de calcul, sans mutation d'un match réel. Correction attendue : recalcul rejouable des données dérivées lorsqu'un champ pertinent change, ou interdiction explicite de ces modifications avec un parcours dédié. Vérifier la même sémantique en production et dans les espaces de validation.

### 5. P2 - Abonnements aux notifications conservés après déconnexion

`lib/core/services/messaging_service.dart:50-61` crée des abonnements à chaque initialisation sans les conserver ni les annuler. `clearTokenForUser` retire seulement le token courant. `lib/core/providers/messaging_providers.dart:69-78` rappelle cette initialisation après chaque reconnexion.

Après plusieurs connexions, plusieurs callbacks restent enregistrés ; les anciens callbacks de rotation conservent l'ancien UID. Cela peut provoquer des traitements répétés et des erreurs de permissions non prises en charge. Les règles limitent l'écriture sur les anciens profils, mais ne libèrent pas les abonnements. Constat statique, non reproduit sur téléphone.

Correction attendue : cycle de vie explicite des abonnements, annulation à la déconnexion/destruction et protection contre une initialisation asynchrone terminant après un changement de compte. Tester connexion, déconnexion, changement de compte et rotation sur Android ; vérifier séparément le parcours web.

### 6. P2 - Coordonnées réelles copiées dans un espace de validation

`server/src/reviewSpace.ts:15-16` copie nom, prénom et e-mail du profil racine. À la ligne 28, la première visite d'un administrateur réel crée sa fiche dans l'espace du reviewer. Cette fiche est ensuite accessible dans cet espace, contrairement au commentaire annonçant qu'aucun document de production n'est copié.

Constat statique : cela ne démontre pas un accès aux autres données du club ni une élévation de privilèges hors de l'espace. Correction attendue : identité synthétique pour les visiteurs dans les fixtures et traitement explicite des copies déjà présentes, sans supprimer aveuglément les données existantes.

### 7. P2 - Rappel de vote élargi quand la présence est vide

`server/src/scheduledVoting.ts:161` transforme une liste de présents vide en `onlyUids: undefined`. Le filtre de `server/src/notificationAudience.ts` interprète cette absence comme aucune restriction de présence. Pour un match réel ouvert avec une liste vide, les membres actifs de l'équipe n'ayant pas voté peuvent donc recevoir un rappel alors qu'ils ne peuvent pas voter. Le serveur accepte cette liste vide, même si le formulaire impose au moins trois joueurs.

Constat statique, aucun envoi effectué. Correction attendue : ne notifier personne si aucun votant n'est éligible et valider les transitions d'ouverture côté serveur. Tester aussi une présence supprimée après ouverture.

### 8. P2 - Suite Flutter en échec après le passage aux saisons

La suite complète actuelle termine avec 115 tests réussis et 6 échecs. Les tests concernés se trouvent dans `test/club_record_navigation_test.dart`, `test/match_types_test.dart` et `test/product_updates_test.dart`. Plusieurs scénarios injectent encore `matchesListProvider`, alors que `MatchesScreen` lit désormais `matchSeasonsProvider` puis `seasonMatchesProvider`. Les attentes sur les cartes, podiums et filtres ne trouvent plus les éléments attendus.

Correction attendue : adapter les fixtures partagées et les scénarios spécifiques aux nouveaux fournisseurs, en conservant les assertions de comportement et la couverture multi-saison. Ces échecs de tests ne démontrent pas à eux seuls une panne du chargement en production. Ils empêchent en revanche de déclarer la suite de non-régression réussie sur la révision actuelle.

## Contrôles de production en lecture seule

URL web confirmée par le responsable : `https://chc-mvp.vercel.app/`.

| Contrôle HTTPS | Résultat observé |
| --- | --- |
| Page web `/` | 200, HTML |
| `/version.json` | 200, version `1.5.4`, build `16`, cohérent avec `pubspec.yaml` |
| `/firebase-messaging-sw.js` | 200, JavaScript |
| API `https://chc-mvp.duckdns.org/health` | 200, `status: ok` |
| API `/members/directory` sans authentification | 401 |

Le frontend fournit HSTS et `X-Frame-Options: DENY`. Aucune CSP n'a été observée sur ces réponses ; l'API ne fournit pas HSTS sur les deux réponses examinées. Ce sont des points de durcissement à évaluer avec le proxy et Flutter Web, pas une preuve d'exploitation. La validation TLS standard était activée.

Ces requêtes ne valident ni l'état de Firestore, ni SMTP/FCM, ni les permissions des utilisateurs connectés, ni la révision exacte du serveur déployé. Le endpoint health est un contrôle de disponibilité HTTP, pas un contrôle des dépendances.

## Historique Git et publication publique

- Clone non superficiel : 37 commits accessibles via les références locales examinées.
- Analyse des 866 blobs uniques accessibles, soit 10 342 990 octets ; 34 blobs binaires exclus de l'analyse textuelle.
- Recherche ciblée de clés privées, comptes de service, formats de jetons connus et affectations de mots de passe. Les deux correspondances de secrets littéraux dans `server/test/review-audit.emulator.test.cjs:112` et `:116` sont des fixtures synthétiques de test d'audit.
- Aucun chemin sensible correspondant aux motifs examinés de fichiers de secrets/signature trouvé dans cet historique accessible.
- Aucun secret réel identifié par ces contrôles. Cela ne garantit pas leur absence : motifs incomplets, fichiers binaires, références supprimées, forks, pull requests distantes et fichiers ignorés hors Git ne sont pas couverts. Il s'agit d'un scan de l'historique accessible, pas d'une revue sémantique exhaustive des 37 commits.
- Aucun fichier de licence repéré dans les fichiers suivis avec les noms LICENSE/NOTICE/COPYING. Les droits sur les logos et images ainsi que le choix d'une éventuelle licence restent à confirmer par le propriétaire avant publication publique. Aucune licence n'a été choisie automatiquement.

## Vérifications locales et limites

- `npm run build` : réussi.
- `flutter analyze --no-pub` : aucun signalement.
- `flutter test --no-pub --reporter compact` : 115 réussites et 6 échecs, détaillés au point 8. Ne pas confondre ce résultat actuel avec les 115 réussites de la première phase sur une révision antérieure.
- `npm test` : 34 tests réussis après autorisation du loopback. La première exécution dans le bac à sable avait deux échecs réseau `EACCES` ; ce n'étaient pas des assertions métier échouées.
- `npm audit --json` : zéro vulnérabilité connue signalée le 9 novembre 2026 pour l'arbre verrouillé du serveur. Ce résultat ne prouve pas l'absence de vulnérabilités inconnues et ne couvre pas les dépendances Flutter.
- Reproductions locales supplémentaires : fuite synthétique du mailer, dépendance au fuseau et absence de reprise du listener, décrites ci-dessus.
- Les 75 tests d'émulateur de la première phase restent un résultat antérieur ; ils n'ont pas été rejoués pour ce rapport et ne prouvent pas les règles actuellement déployées.
- Validation visuelle web non terminée : le contrôle de Firefox a été arrêté par l'outil, faute de prise en charge de la politique d'URL pour ce navigateur Windows. Cette restriction n'a pas été contournée.
- Validation visuelle Android non effectuée : un Pixel est détecté, mais aucun parcours ni rendu connecté n'a été validé. Aucun APK n'a été installé et aucun état de compte n'a été modifié.
- Restent à exécuter avec les comptes de validation : parcours connecté Android/web, formats mobile/ordinateur, clavier, texte agrandi, thèmes, absence de notifications réelles, accès aux fonctionnalités depuis l'espace de review et vérification de la version distribuée sur les pistes Google Play.

L'audit ne peut donc pas être déclaré complet sur les volets visuels et production authentifiée. Corriger d'abord les points P1, puis les incohérences P2 ; exécuter les scénarios de reprise et de permissions sur émulateur avant tout nouveau déploiement.

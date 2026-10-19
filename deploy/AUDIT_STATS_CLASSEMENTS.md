# Statistiques, badges, classements et matchs de test

## Ce qui a été corrigé

- **Fair-play** : les cartons verts, jaunes et rouges excluent tous un joueur de la carte « 0 carton ». Une feuille manquante n'est pas assimilée à une feuille sans carton. Les résultats partiels pendant le chargement ne sont plus utilisés pour désigner un joueur. Le classement fair-play utilise les trois couleurs, puis le nombre de matchs renseignés pour départager deux totaux égaux.
- **Périodes** : les records, temps forts et statistiques hebdomadaires de l'accueil utilisent la saison courante (septembre à août). Le classement général et les statistiques personnelles restent cumulés sur l'historique. Les buts et passes sont les totaux des feuilles renseignées des joueurs présents ; le nombre de matchs renseignés est indiqué lorsqu'il accompagne ces totaux.
- **Votes reçus** : compte les bulletins qui désignent le joueur, y compris s'il ne termine pas sur le podium. Le nombre de podiums reste disponible séparément. Les points sont attribués une fois par match selon le podium et le barème, indépendamment du nombre de votants.
- **Autres cartes** : correction du numéro de semaine ISO, de la confusion entre votes et matchs dans le texte insolite, du titre « meilleure moyenne », et du record personnel de série top 3. Le joueur en forme attend tous les résultats de ses trois matchs de référence. La progression exige au moins un match antérieur. Un résultat pas encore calculé n'est plus présenté comme zéro vote.
- **Dates** : le serveur affecte mois et saisons selon le calendrier de `Europe/Paris`, notamment pour un match saisi le 1er septembre à minuit.
- **Adversaire depuis le bouton +** : largeur explicite de la fenêtre, nom obligatoire, blocage des doubles soumissions, erreur affichée dans la fenêtre. Le nouvel adversaire et son logo sont sélectionnés immédiatement, même si le flux de la liste tarde à se mettre à jour.
- **Saisie des statistiques** : enregistrement désactivé tant que les valeurs existantes ne sont pas chargées, pour éviter de les remplacer accidentellement par des zéros.

Les scores `scoreHome` et `scoreAway` représentent respectivement **CHC** et **l'adversaire** dans le formulaire existant, même pour une rencontre à l'extérieur. Les bilans respectent cette convention. Le taux de vote moyen est la moyenne des pourcentages par match (bulletins / joueurs présents), et non le taux d'ouverture de comptes.

## Suppression et reconstruction

La suppression depuis l'application passe maintenant par `DELETE /matches/:matchId`, réservé aux administrateurs. Le serveur supprime le match et ses sous-collections, puis reconstruit les classements. Le listener prend aussi en charge les suppressions faites par une ancienne version de l'application.

Le bouton **Administration → Reconstruire les classements maintenant** :

1. Retrouve les parents de matchs supprimés qui ont encore des sous-collections et les supprime récursivement : votes, résultats et statistiques de jeu.
2. Recalcule les résultats à partir des votes des seuls matchs encore présents et clôturés.
3. Remplace les totaux général, mensuels et par saison, ainsi que les statistiques personnelles et historiques ; enlève les anciennes périodes et entrées sans source restante.
4. Conserve les votes des matchs ouverts, sans leur attribuer de points. Retire leurs éventuels anciens résultats définitifs.
5. Recalcule les badges à partir des matchs réels restants, saison par saison. Retire les badges dont les critères ne sont plus remplis et conserve la date des badges encore valides.

Les reconstructions et clôtures utilisent la même file d'exécution dans le processus du VPS. Les écritures sont découpées en lots de 400 au maximum. Les feuilles et bulletins des matchs conservés ne sont pas supprimés. Si aucun match clôturé ne reste, les anciens classements et historiques deviennent vides. Rejouer la reconstruction ne double pas les points ni les votes reçus.

Le recalcul des badges est aussi exécuté après une suppression, une clôture ou l'enregistrement des statistiques d'un match clôturé depuis cette version. Les badges d'anciennes saisons restent acquis si les matchs restants les justifient encore. Les cartons verts comptent pour le fair-play et une feuille manquante ne vaut pas zéro carton. Le profil lit les badges du serveur ; il ne peut plus réattribuer un badge retiré.

La reconstruction n'est pas une transaction globale : pendant le traitement, plusieurs documents sont mis à jour successivement. En cas d'interruption, la relancer restaure les agrégats depuis les votes. La file d'exécution suppose un seul processus backend, comme le service systemd actuel ; ne pas activer plusieurs workers écrivant ces classements sans verrou distribué.

## Utiliser les matchs de test

1. Dans **Administration → Matchs → Créer un match**, activer **Match de test**, puis choisir l'adversaire, l'équipe et les joueurs présents. Sélectionner au moins quatre joueurs pour un top 3 sans auto-vote.
2. Le match apparaît avec **[TEST]** dans la liste d'administration. Dans son menu, ouvrir **Simuler les votes / résultats**.
3. Ouvrir le vote, choisir le **joueur qui vote**, puis ses **1er, 2e et 3e choix**. Enregistrer le bulletin. Répéter pour les autres votants. Un nouvel enregistrement remplace le bulletin du votant sélectionné pour ce test.
4. Cliquer **Clôturer et calculer les résultats**. Le test peut être rouvert pour changer les bulletins, puis clôturé à nouveau.
5. Supprimer le test depuis le menu du match pour enlever aussi ses votes, résultats et feuilles de statistiques.

Les tests sont dans la collection `test_matches`, avec un identifiant commençant par `test:`. Ils sont visibles uniquement par les administrateurs actifs, même si un membre utilise une ancienne application ou tente d'accéder directement à Firestore. Ils n'apparaissent pas dans les listes publiques du club et ne participent à aucun classement, statistique ou badge réel. Le mode réel/test est fixé à la création.

Les notifications d'ouverture, rappel et clôture portent **[TEST]** et ciblent uniquement les administrateurs actifs ayant un token de notification, indépendamment des joueurs simulés et de l'équipe. Les rappels de présence restent également réservés aux admins. Les notifications push restent disponibles sur l'application mobile ; le web n'envoie pas de push dans cette version. Une application mobile à jour ouvre l'écran de simulation en touchant une notification de test.

La simulation est contrôlée par le serveur : administrateur actif, match de test ouvert, période de vote valide, joueurs présents, trois choix distincts et respect de l'option d'auto-vote. Elle ne permet pas de voter au nom d'un joueur dans un vrai match.

## Installer cette version

**Ordre : VPS, règles Firestore, puis Vercel et application mobile.** La suppression, la simulation et les badges sont côté serveur. Modifier seulement le frontend ne répare pas les anciens totaux.

Depuis le projet sur le PC, l'archive peut être recréée avec :

```powershell
tar -czf build/chc-backend-update.tar.gz -C server src public test package.json package-lock.json tsconfig.json
```

Elle ne contient ni `.env`, ni compte de service Firebase, ni `node_modules`. Transférer cette archive sur le VPS dans `/tmp/chc-backend-update.tar.gz`, puis :

```bash
sudo -u hockey tar -xzf /tmp/chc-backend-update.tar.gz -C /opt/hockey-club-server
cd /opt/hockey-club-server
sudo -u hockey npm ci && sudo -u hockey npm run build && sudo systemctl restart hockey-club-server
sudo systemctl status hockey-club-server --no-pager
```

Depuis la racine du projet sur le PC, publier les nouvelles règles (avec Firebase CLI connecté au compte du projet) :

```powershell
firebase deploy --only firestore:rules --project chc-mvp
```

Ces règles autorisent les admins à utiliser `test_matches` et réservent l'écriture de `userBadges` au serveur. Ne pas créer de test avant leur installation. Les anciennes applications qui calculaient et écrivaient les badges dans le profil doivent être mises à jour : ces anciennes écritures seront refusées, tandis que les badges calculés par le serveur restent lisibles.

Publier ensuite les changements Git pour redéployer Vercel et distribuer la nouvelle version mobile. Dans l'administration, cliquer **une fois sur Reconstruire les classements maintenant** pour nettoyer les anciens matchs supprimés, corriger les compteurs historiques et recalculer les badges existants. Les nouvelles attributions réelles peuvent produire les notifications habituelles de badges. Aucun changement de `.env` n'est requis.

## Tests

```powershell
flutter test --no-pub
npm --prefix server run build
npm --prefix server test
flutter build web --release --no-web-resources-cdn --dart-define=SERVER_BASE_URL=https://chc-mvp.duckdns.org
```

Les tests d'intégration utilisent exclusivement un émulateur local et le projet fictif `demo-chc-audit`. Démarrer l'émulateur Firestore, puis dans PowerShell :

```powershell
$env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8087'
npm --prefix server run test:emulator
node --test firestore/vote-rules.test.mjs
```

Le port doit correspondre à celui de l'émulateur, démarré avec `firestore/firestore.rules`. Les tests serveur utilisent `demo-chc-audit` ; ceux des règles utilisent `demo-chc-web`. Ces tests refusent une adresse distante et ne manipulent que ces projets fictifs. Ils couvrent notamment les anciens matchs supprimés, les historiques sans parent, le dernier match, 510 historiques, les reconstructions simultanées et répétées, le retrait de badges, la préservation des dates, les bulletins simulés et l'isolation des tests. Les tests Flutter couvrent la création et la simulation sur mobile et ordinateur. La sélection des destinataires des notifications est testée sans envoyer de push réel.

La gestion des tailles du dialogue suit la [documentation Flutter sur AlertDialog](https://api.flutter.dev/flutter/material/AlertDialog-class.html). Le nettoyage s'appuie sur les méthodes `listDocuments` (parents manquants inclus) et `recursiveDelete` du [SDK Firestore officiel](https://github.com/googleapis/nodejs-firestore/blob/main/types/firestore.d.ts).

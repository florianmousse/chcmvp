# Correctifs des statistiques, adversaires et classements

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

Les reconstructions et clôtures utilisent la même file d'exécution dans le processus du VPS. Les écritures sont découpées en lots de 400 au maximum. Les feuilles et bulletins des matchs conservés ne sont pas supprimés. Si aucun match clôturé ne reste, les anciens classements et historiques deviennent vides. Rejouer la reconstruction ne double pas les points ni les votes reçus.

La reconstruction ne révoque pas les badges déjà obtenus. Elle n'est pas une transaction globale : pendant le traitement, plusieurs documents sont mis à jour successivement. En cas d'interruption, la relancer restaure les agrégats depuis les votes. La file d'exécution suppose un seul processus backend, comme le service systemd actuel ; ne pas activer plusieurs workers écrivant ces classements sans verrou distribué.

## Installer cette version

**Mettre le VPS à jour avant Vercel** : la nouvelle route de suppression et les calculs sont côté serveur. Modifier seulement le frontend ne répare pas les anciens totaux.

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

Publier ensuite les changements Git pour redéployer Vercel. Dans l'administration, cliquer **une fois sur Reconstruire les classements maintenant** pour nettoyer les anciens matchs supprimés et corriger les compteurs historiques. Aucun changement de `.env` ou des règles Firestore n'est requis pour ces correctifs.

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
```

Le port doit correspondre à celui de l'émulateur. Ces tests refusent une adresse distante et effacent uniquement les données fictives de leur projet de test. Ils couvrent notamment les anciens matchs supprimés, les historiques sans parent, le dernier match, 510 historiques, les reconstructions simultanées et répétées et un recalcul retardé après suppression.

La gestion des tailles du dialogue suit la [documentation Flutter sur AlertDialog](https://api.flutter.dev/flutter/material/AlertDialog-class.html). Le nettoyage s'appuie sur les méthodes `listDocuments` (parents manquants inclus) et `recursiveDelete` du [SDK Firestore officiel](https://github.com/googleapis/nodejs-firestore/blob/main/types/firestore.d.ts).

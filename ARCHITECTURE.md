# App Club Hockey — Architecture & Feuille de route

## 1. Stack

- **Flutter** (Android + iOS depuis une seule base de code)
- **Riverpod** (`flutter_riverpod` + `riverpod_generator`) pour la gestion d'état
- **Firebase** : Authentication, Cloud Firestore, Cloud Messaging
- **Clean Architecture** : `domain` (entités + règles métier, pur Dart) / `data` (repositories +
  sources Firebase) / `presentation` (widgets + controllers Riverpod)
- **freezed** + `json_serializable` pour les modèles immuables
- **Backend** : Node.js / Express / TypeScript auto-hébergé sur VPS Oracle Cloud Free Tier

## 2. Arborescence

```
lib/
  core/
    config/            # server_config, club_config, team_logos_catalog
    models/            # entités partagées (UserModel, MatchModel, PointsScale...)
    services/          # wrappers Firebase (Auth, Firestore, Messaging)
    providers/         # providers Riverpod transverses (auth, messaging)
    theme/             # Material 3, thème clair/sombre
    utils/             # constantes, formatters, validators, season helpers
    widgets/           # widgets partagés (opponent_logo)
  features/
    auth/              # connexion, inscription, mot de passe oublié
    home/              # écran d'accueil enrichi (stats avancées, badges, temps forts)
      domain/          # badge_model, badge_calculator, advanced_stats_calculator
      presentation/    # home_screen, highlight_cards, season_records, fun_stat_card,
                       #   badges_section, vote_rate_indicator
    members/           # gestion des membres (CRUD admin)
    matches/           # affichage des matchs, statut, vote rate par match
    voting/            # écran de vote, logique d'attribution des points
    ranking/           # classement général / mensuel / par saison, stats joueur
    profile/           # profil joueur avec badges
    admin/             # tableau de bord admin (création match/membre)

server/
  src/
    firebase.ts        # initialisation firebase-admin, constantes d'env
    index.ts           # Express app, cron jobs, listeners
    matchListeners.ts  # listener Firestore temps réel (onSnapshot), calcul des résultats
    matchTally.ts      # logique de décompte des votes
    scheduledVoting.ts # cycle automatique des votes (4 phases)
    notify.ts          # notifications push (FCM) — notifyMembers, notifyAdmins
    season.ts          # calcul de l'identifiant de saison
    rebuildRankings.ts # reconstruction complète des classements
    mailer.ts          # envoi d'emails (inscription)
    middleware/auth.ts # vérification token Firebase + rôle admin
    routes/            # auth, matches (recompute, rebuild), members (CRUD)

deploy/
  DEPLOY_ORACLE_VPS.md          # guide de déploiement VPS (version publique, sans IP)
  DEPLOY_ORACLE_VPS.local.md    # guide avec les vraies valeurs (gitignored)
  PLAYSTORE_DEPLOYMENT.md       # guide de publication Play Store
  hockey-club-server.service    # fichier systemd
  nginx.conf.example            # configuration nginx reverse proxy
```

## 3. Modèle de données Firestore

```
users/{uid}
  firstName, lastName, photoUrl, jerseyNumber, team,
  role ("admin"|"member"), isActive, createdAt,
  fcmTokens: [string...]

matches/{matchId}
  date (Timestamp), time (string "HH:mm"), opponent, isHome, team,
  status ("upcoming"|"voting_open"|"voting_closed"),
  presentPlayerIds: [uid...],
  votingOpensAt, votingClosesAt,
  pointsScale: {first, second, third},
  allowSelfVote: bool,
  opponentLogoAsset: string?,
  reminderSentAt, adminReminderSentAt  ← flags anti-doublon pour les notifications

matches/{matchId}/votes/{voterUid}
  firstPlaceUid, secondPlaceUid, thirdPlaceUid, voterUid, votedAt

matches/{matchId}/results/summary   ← calculé par le serveur
  entries: {uid: {points, firstCount, secondCount, thirdCount}},
  mvpUids: [uid...], totalVotes, voteRate,
  distinctVotersMap: {uid: count}, computedAt

rankings_cache/{scope}   ← "general", "2025-2026", "2026-08"
  entries: {uid: {points, firstCount, secondCount, thirdCount}}

player_stats/{uid}
  matchesPlayed, totalPoints, votesReceived, distinctVoters,
  firstCount, secondCount, thirdCount

player_stats/{uid}/history/{matchId}
  matchId, matchDate, points, rank, distinctVotersThisMatch, presentCount

settings/global   ← réglages modifiables par l'admin
  voteDurationHours, reminderBeforeHours, voteOpenDelayHours,
  adminReminderBeforeHours
```

## 4. Cycle de vie automatique des votes

Le serveur gère le cycle de vie complet via un cron toutes les 10 minutes
(`scheduledVoting.ts`) + un listener temps réel (`matchListeners.ts`) :

```
Match créé (upcoming)
     │
     ├── 1h avant le match  → 📱 Notification admins si feuille de présence vide
     │
     ├── +2h après le match → Statut → voting_open (si présence remplie)
     │                        📱 Notification joueurs présents : "Vote ouvert !"
     │
     ├── +26h               → 📱 Rappel joueurs présents qui n'ont pas voté
     │
     └── +50h               → Statut → voting_closed
                              🏆 Classement recalculé
                              📱 Notification joueurs présents : "MVP : [nom]"
```

**Notifications ciblées** : seuls les joueurs listés dans `presentPlayerIds` reçoivent
les notifications de vote. Les admins reçoivent les rappels de feuille de présence
indépendamment de leur participation au match.

## 5. Écran d'accueil

L'écran d'accueil est organisé en sections avec des cartes swipables :

1. **Mon classement** — position, médailles, points
2. **📅 À l'affiche** (swipable) — votes ouverts, prochain match, dernier résultat
3. **🎲 Le coin des stats** (swipable) — stat insolite hebdomadaire, duel de la semaine
4. **Les temps forts** (swipable) — joueur en forme, révélation, plébiscité, meilleure série
5. **Records de la saison** — meilleur buteur, plus longue série
6. **Ma participation aux votes** — taux + série en cours

## 6. Badges

8 badges calculés côté client (pas persistés en Firestore) :

| Badge | Emoji | Condition | Quand |
|-------|:-----:|-----------|-------|
| MVP de la saison | 🏆 | 1ᵉʳ au classement général | Fin de saison |
| En feu | 🔥 | 5+ matchs consécutifs dans le top 3 | En cours |
| Plébiscité | 🤝 | 80%+ des coéquipiers ont voté pour lui sur un match | En cours |
| Révélation | 🚀 | Moyenne +40% vs 5 premiers matchs | En cours |
| Votant assidu | 🗳️ | 100% de participation aux votes sur une saison | Fin de saison |
| Centurion | 💯 | 100+ points cumulés | En cours |
| Podium Master | 🥇 | 10+ premières places | En cours |
| Régularité | 📊 | Écart-type le plus faible (min. 5 matchs) | En cours |

Les badges non gagnés apparaissent verrouillés (opacité réduite + « ? ») dans le profil.

## 7. Règles de sécurité Firestore

- Un membre ne peut lire/écrire que son propre profil ; seul un admin peut modifier `role`,
  `isActive`, ou le profil d'un autre membre.
- Un membre ne peut créer un vote que pour `voterUid == request.auth.uid`, seulement si
  le statut du match est `voting_open`, et seulement une fois.
- Personne ne peut lire les votes individuels des autres — seul le serveur (admin SDK) y
  accède pour calculer `results/summary`.
- Seul un admin peut écrire dans `matches/`, `users/*.role`, `settings/`.

## 8. Backend VPS — remplace Cloud Functions

**Pourquoi** : Firebase Cloud Functions exige le plan payant Blaze (carte bancaire
obligatoire). Le club préfère un VPS Oracle Cloud Free Tier, gratuit et toujours allumé.

| Cloud Functions | Équivalent VPS |
|---|---|
| Trigger Firestore (`onDocumentUpdated`) | `onSnapshot` longue durée (`matchListeners.ts`) |
| Tâche planifiée (Cloud Scheduler) | `node-cron` toutes les 10 min (`scheduledVoting.ts`) |
| Fonction `onCall` | Route Express + auth middleware (`routes/*.ts`) |

Côté Flutter, `cloud_functions` est remplacé par des requêtes HTTP
(`core/services/server_client.dart`) avec le token Firebase en en-tête `Authorization`.

**Mise en route** : voir `deploy/DEPLOY_ORACLE_VPS.md`.

## 9. Navigation

`main.dart` bascule Connexion → (profil manquant ? écran dédié : coquille principale)
selon `authStateProvider` + `currentUserProfileProvider`. La coquille utilise un
`IndexedStack` : `HomeScreen`, `MatchesScreen`, `RankingScreen`, `ProfileScreen`, et
`AdminDashboardScreen` (visible si admin).

## 10. Feuille de route — ce qu'il reste à construire

| Fonctionnalité | Où la brancher |
|---|---|
| Export Excel / PDF | Nouvelle route HTTP admin sur le serveur, génère et renvoie le fichier directement |
| Partage réseaux sociaux du MVP | `share_plus` sur l'écran résultats |
| Admin web | Second client Flutter Web (ou React) ciblant les mêmes collections Firestore |
| Réinitialisation de saison | Fonction admin qui archive `rankings_cache` courant puis le vide |
| Photos de profil | À remplacer par un service gratuit (Cloudinary) — Firebase Storage exige aussi Blaze |

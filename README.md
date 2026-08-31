# Club Hockey — App de vote MVP

Application mobile Flutter pour un club de hockey : vote des meilleurs joueurs après chaque
match, classement général/mensuel/par saison, badges, statistiques avancées, et notifications
push — le tout sur un backend auto-hébergé (gratuit, sans carte bancaire).

Voir **[ARCHITECTURE.md](ARCHITECTURE.md)** pour le détail de l'architecture, du modèle
de données, du système de badges, et de la feuille de route.

---

## Fonctionnalités

- 🗳️ **Vote** — Chaque joueur présent vote pour ses 3 meilleurs coéquipiers (anonyme)
- 🏆 **Classement** — Général, mensuel, par saison avec barème configurable (5/3/1 pts)
- 📊 **Statistiques** — Évolution par match, moyenne, badges, série top 3
- 🏠 **Écran d'accueil** — Stat insolite hebdomadaire, duel de la semaine, temps forts, records
- 🔔 **Notifications push** — Ouverture/clôture du vote, rappels automatiques
- 🤖 **Cycle de vote automatique** — Ouverture 2h après le match, rappel 24h avant clôture, clôture à 48h
- 🛡️ **Admin** — Gestion des membres, création de matchs, feuille de présence
- 🎖️ **8 badges** — MVP de la saison, En feu, Plébiscité, Révélation, Votant assidu, etc.

---

## Mise en route — App Flutter

### Prérequis

- Flutter SDK (≥ 3.x)
- Un projet Firebase avec **Authentication** (email/password), **Cloud Firestore**, **Cloud Messaging**

### Installation

```bash
# 1. Cloner le projet
git clone <url-du-repo>
cd hockey-club-app

# 2. Connecter Firebase
dart pub global activate flutterfire_cli
flutterfire configure
# → génère lib/firebase_options.dart

# 3. Installer les dépendances
flutter pub get

# 4. Générer les fichiers freezed/json/riverpod
dart run build_runner build --delete-conflicting-outputs

# 5. Déployer les règles de sécurité Firestore
firebase deploy --only firestore:rules

# 6. Configurer l'adresse du serveur
# → Modifier lib/core/config/server_config.dart avec l'URL de ton VPS

# 7. Lancer l'app
flutter run
```

---

## Mise en route — Backend (VPS)

Le backend Node.js/Express/TypeScript tourne dans `server/` sur un VPS (Oracle Cloud Free
Tier, gratuit sans carte bancaire). Il gère :

- 🔄 Calcul des résultats et classements à la clôture du vote
- ⏰ Cycle de vote automatique (ouverture, rappels, clôture)
- 📱 Notifications push (FCM)
- 🔐 Routes admin sécurisées (gestion membres, recalcul)

### Installation locale (développement)

```bash
cd server
cp .env.example .env
# → Configurer GOOGLE_APPLICATION_CREDENTIALS, PORT, etc.
npm install
npm run build
npm start
```

### Déploiement en production

Voir **[deploy/DEPLOY_ORACLE_VPS.md](deploy/DEPLOY_ORACLE_VPS.md)** — guide pas à pas
pour Oracle Cloud Free Tier, incluant les pièges classiques (double pare-feu, iptables).

---

## Déploiement Play Store

Voir **[deploy/PLAYSTORE_DEPLOYMENT.md](deploy/PLAYSTORE_DEPLOYMENT.md)** — de la
génération de la clé de signature à la publication.

---

## Structure du projet

```
lib/                   # Code Flutter (Clean Architecture)
  core/                # Config, modèles, services, thème, utils
  features/            # Modules fonctionnels (auth, home, matches, voting, ranking, profile, admin)

server/                # Backend Node.js/Express/TypeScript
  src/                 # Code source serveur

deploy/                # Guides et fichiers de déploiement
  DEPLOY_ORACLE_VPS.md
  PLAYSTORE_DEPLOYMENT.md
  hockey-club-server.service
  nginx.conf.example

firestore/             # Règles de sécurité Firestore
```

---

## Sécurité

⚠️ **Ne jamais commiter** :
- Clés de service Firebase (`*-firebase-adminsdk-*.json`)
- Fichiers `.env` (mots de passe SMTP, chemins vers les clés)
- Keystores Android (`*.jks`, `*.keystore`, `key.properties`)
- Fichiers `*.local.md` (contiennent IP du VPS, chemins SSH)

Le `.gitignore` est configuré pour exclure tous ces fichiers.

---

## Licence

Projet privé — usage réservé au club.

# Publier CHC MVP sur Vercel

La version web utilise **le même code Flutter, le même design et les mêmes données Firebase** que l'application mobile. Vercel distribue les fichiers statiques de `build/web`. Le backend `server/` continue de fonctionner sur le VPS : ses tâches planifiées et ses listeners permanents ne doivent pas être transférés tels quels dans une fonction Vercel.

## 1. Vérifier la version web en local

Outils : Flutter **3.44.9** (version vérifiée), Node.js **24 LTS** recommandé (22 minimum pour le backend), Git. Depuis la racine du dépôt :

```powershell
flutter pub get --enforce-lockfile
node scripts/generate-legal.mjs
flutter test test/web_compatibility_test.dart
flutter build web --release --no-web-resources-cdn
node scripts/preview-web.mjs
```

Ouvrir **http://127.0.0.1:8085**. `Ctrl+C` arrête l'aperçu. Le serveur ne rend accessible que `build/web`, jamais les fichiers privés du dépôt.

Pour développer avec rechargement :

```powershell
flutter run -d chrome --web-port 8085
```

Le site reprend les onglets Accueil, Matchs, Classements, Profil et Administration. Sur grand écran, la navigation devient latérale. Les fenêtres de vote, les statistiques et les formulaires d'administration utilisent les composants existants. Les notifications push et les widgets Android restent propres à l'application mobile ; le site ne demande pas d'autorisation de notification. L'ajout à l'écran d'accueil dépend du navigateur. Une connexion Internet reste nécessaire.

## 2. Préparer le dépôt Git

Publier le code sur un dépôt GitHub, GitLab ou Bitbucket auquel Vercel peut accéder. Le répertoire racine du projet Vercel doit être celui qui contient `pubspec.yaml` et `vercel.json`, **pas `server/` ni `web/`**.

Inclure notamment `lib/`, `assets/`, `web/`, `scripts/`, `pubspec.yaml`, `pubspec.lock` et `vercel.json`. Les fichiers `.env`, clés Firebase Admin SDK, clés SSH et keystores restent exclus du dépôt. Les identifiants de configuration Firebase **client** présents dans `lib/firebase_options.dart` sont publics par conception ; la clé de service **Admin** ne doit jamais être envoyée à Vercel ni intégrée au site.

Le projet contenait déjà des modifications locales avant cette adaptation : relire le diff avant de préparer un commit commun.

## 3. Créer le projet Vercel

Dans Vercel, choisir **Add New → Project**, importer le dépôt et conserver la racine du dépôt comme **Root Directory**.

Les réglages sont déjà déclarés dans `vercel.json` :

| Réglage          | Valeur                                                                            |
| ---------------- | --------------------------------------------------------------------------------- |
| Framework Preset | Other                                                                             |
| Build Command    | `bash scripts/build-vercel.sh`                                                    |
| Output Directory | `build/web`                                                                       |
| Install Command  | Fourni dans `vercel.json` ; les dépendances sont installées par le script Flutter |

Le script télécharge la version verrouillée de Flutter, résout les dépendances selon `pubspec.lock`, génère les pages légales puis compile le site. Les fichiers du moteur CanvasKit sont servis depuis le site. Le premier build peut être plus long en raison du téléchargement du SDK.

Variable facultative dans **Settings → Environment Variables** :

| Variable          | Valeur par défaut             | Utilisation                                                    |
| ----------------- | ----------------------------- | -------------------------------------------------------------- |
| `SERVER_BASE_URL` | `https://chc-mvp.duckdns.org` | URL HTTPS du VPS, sans slash final                             |
| `FLUTTER_VERSION` | `3.44.9`                      | Ne changer qu'après avoir vérifié la nouvelle version en local |

Ces valeurs sont utilisées pendant la compilation. Après modification, lancer un **Redeploy**. Ne pas ajouter de compte de service Firebase, mot de passe SMTP ou clé privée aux variables de ce frontend.

Cliquer sur **Deploy**, puis relever le domaine stable attribué au projet, par exemple `chc-mvp.vercel.app`. Le domaine exact sera donné par Vercel ; l'exemple n'est pas un domaine réservé.

## 4. Autoriser le domaine dans Firebase

Dans le projet Firebase `chc-mvp` :

1. Vérifier **Authentication → Sign-in method** : e-mail/mot de passe et Google doivent être activés selon les méthodes souhaitées.
2. Dans **Authentication → Settings → Authorized domains**, ajouter le domaine Vercel stable, sans `https://`, puis le domaine personnalisé éventuel.
3. Pour le développement, ajouter `localhost` et/ou `127.0.0.1` si ces domaines ne sont pas déjà autorisés et si tu les utilises.
4. Utiliser un compte membre existant. Il n'existe pas d'inscription publique : une connexion Google ne crée pas automatiquement une fiche membre du club.

La connexion Google web utilise Firebase `signInWithPopup`. Si le navigateur bloque la fenêtre, autoriser cette fenêtre de connexion ou utiliser l'e-mail/mot de passe. Ne pas modifier l'`authDomain` Firebase existant uniquement pour le remplacer par le domaine Vercel.

Un domaine de preview Vercel différent doit être ajouté explicitement si tu veux y tester l'authentification. Éviter d'autoriser toutes les previews ; conserver un environnement de test identifié.

## 5. Autoriser le frontend sur le VPS (CORS)

Mettre à jour le code de `server/` sur le VPS. Dans son `.env`, ajouter les origines exactes, avec le protocole et sans slash final :

```dotenv
WEB_ALLOWED_ORIGINS=https://chc-mvp.vercel.app,https://mvp.votre-domaine.fr
```

Remplacer les exemples par les vrais domaines. Pour un test local uniquement, ajouter temporairement `http://127.0.0.1:8085` ou `http://localhost:8085` selon l'adresse utilisée.

Recompiler et redémarrer le backend avec la procédure VPS habituelle :

```bash
cd /opt/hockey-club-server
sudo -u hockey npm ci
sudo -u hockey npm run build
sudo systemctl restart hockey-club-server
```

Le nom du service et le chemin doivent correspondre à ton installation ; voir `deploy/DEPLOY_ORACLE_VPS.md`. Le middleware CORS répond aux requêtes `OPTIONS` et autorise les en-têtes `Authorization` et `Content-Type`. Nginx doit laisser passer ces requêtes jusqu'à Express. Ne pas ajouter en parallèle un en-tête CORS `*` dans Nginx.

Les routes protégées conservent la validation du jeton Firebase et du rôle administrateur. Les applications natives, qui n'envoient pas d'en-tête `Origin`, continuent de fonctionner. Sans cette étape, les lectures Firebase peuvent fonctionner mais la réinitialisation du mot de passe et certaines actions administrateur échoueront dans le navigateur.

## 6. Déployer les règles de vote

Les règles locales renforcent les contrôles : membre actif présent au match, trois joueurs distincts figurant sur la feuille de présence, respect de l'auto-vote et des heures d'ouverture/clôture, auteur authentifié, horodatage serveur, un seul vote définitif. Elles protègent aussi contre une requête fabriquée hors de l'interface.

`firebase.json` contient la configuration Firestore. Depuis la racine :

```powershell
firebase deploy --only firestore:rules --project chc-mvp
```

Relire les règles avant cette commande : elles sont communes à Android et au web. Tester d'abord sur un projet Firebase de développement ou l'émulateur. Les champs `votingOpensAt` et `votingClosesAt`, lorsqu'ils sont renseignés, doivent être des **Timestamp Firestore**, comme ceux écrits par le serveur existant. Les anciens matchs sans dates restent régis par leur statut.

Les tests de règles livrés utilisent un projet local `demo-chc-web`, sans clé privée ni accès aux données réelles. Avec Firebase CLI et Java 21 ou supérieur :

```powershell
firebase emulators:exec --only firestore --project demo-chc-web --config firestore/emulator.json "node --test firestore/vote-rules.test.mjs"
```

Pour vérifier les accès web du backend sans lancer les traitements du club :

```powershell
sudo -u hockey npm --prefix server ci
sudo -u hockey npm --prefix server run build
node --test server/test/cors.test.cjs
```

Validation locale de cette livraison : compilation Flutter Web et TypeScript réussie, 6 tests Flutter réussis, 12 tests de règles Firestore réussis dans l'émulateur, 1 test CORS réussi. L'écran de connexion et les pages légales ont aussi été contrôlés dans le navigateur en format mobile. Les parcours avec un compte réel, les e-mails et les réglages de production restent à vérifier après configuration.

## 7. Pages légales

Disponibles sans connexion et sans JavaScript :

- `/mentions-legales.html`
- `/confidentialite.html`
- `/cookies.html`
- `/conditions-utilisation.html`
- `/supprimer-compte.html`

Les liens sont présents sur l'écran de connexion et dans Profil. Sur Vercel, les anciennes URL `/privacy.html` et `/delete-account.html` redirigent vers les pages correspondantes.

L'identité fournie a été intégrée : **Châteaubourg Hockey Club**, **25 rue du Prieuré, 35220 Châteaubourg**, responsable **Florian Moussé**, contact **chcmvp.chateaubourghockeyclub@gmail.com**.

Pour modifier ces données, éditer `web/legal-config.json`. Pour modifier les textes, éditer `scripts/generate-legal.mjs`, puis exécuter `node scripts/generate-legal.mjs`. Les HTML générés sont versionnés pour que l'aperçu de développement possède aussi ces pages.

### Points à valider par le club avant mise en ligne

- Compléter les coordonnées téléphoniques de l'éditeur et de l'hébergeur, ainsi que l'identification associative pertinente. Confirmer la qualité du responsable de publication indiqué. Les informations non fournies ne sont pas inventées.
- Confirmer l'hébergement réel du VPS, le prestataire SMTP, les régions Firebase et les garanties de transfert contractuelles ; ajuster la politique si l'installation diffère du dépôt.
- Définir les durées opérationnelles de conservation des bulletins, historiques, journaux et sauvegardes. Le logiciel existant n'exécute pas de purge automatique ; le club doit organiser les traitements manuels ou ajouter une procédure avant de promettre un délai de suppression automatisé.
- Valider la base juridique selon l'adhésion au club et les modalités applicables aux mineurs. Les textes décrivent le service observé ; ils ne remplacent pas la validation des pratiques réelles du club.
- Le modèle actuel autorise les membres actifs à lire les fiches membres, y compris les e-mails. Si le club veut réserver ces coordonnées aux administrateurs, séparer les données privées dans un document protégé : les règles Firestore ne masquent pas certains champs d'un document lisible.
- La suppression d'un membre dans le backend actuel retire le compte Auth et la fiche `users`, mais ne nettoie pas automatiquement tous les votes, badges, historiques, statistiques et références dans les matchs. La page publique propose donc une **demande par e-mail**, sans annoncer une suppression immédiate ou une anonymisation déjà implémentée. Définir et exécuter la procédure complète lors d'une demande.
- Les anciennes pages légales servies par le VPS sont distinctes de celles du web. Les harmoniser ou les rediriger vers le domaine final, notamment si leurs URL sont utilisées dans le Play Store. Elles contiennent des coordonnées et promesses de suppression différentes.

### Cookies

Aucun SDK de publicité ou d'analytics n'est ajouté (le `measurementId` Firebase existant n'active pas Analytics à lui seul). Seuls l'authentification, la préférence de thème et les fichiers techniques sont utilisés. Il n'y a donc pas de bandeau d'acceptation artificiel. Si tu ajoutes ultérieurement des traceurs non essentiels, les bloquer avant consentement et proposer un refus et un retrait aussi simples que l'acceptation.

## 8. Contrôles après déploiement

1. Ouvrir le site sur un téléphone et un ordinateur ; vérifier le thème clair/sombre et la navigation.
2. Ouvrir les cinq pages légales sans se connecter, puis recharger leurs URL directement.
3. Tester e-mail/mot de passe, Google et déconnexion avec un compte de test autorisé. Vérifier qu'un compte non membre n'accède pas aux données.
4. Sur un match de test : voter avec un joueur présent, vérifier le résultat de validation, puis vérifier l'impossibilité de voter deux fois. Vérifier aussi un joueur absent, un candidat absent, l'auto-vote interdit et une clôture dépassée.
5. Vérifier les classements après clôture, puis les formulaires administrateur et les e-mails avec des données de test.
6. Confirmer que la console réseau ne présente aucune erreur CORS ou contenu mixte HTTP/HTTPS.

La compilation et les tests locaux ne prouvent pas que les domaines Firebase, les règles déployées, le VPS et le SMTP en production sont déjà configurés. Aucun compte membre ni vote réel n'est créé par les tests livrés.

## Dépannage

| Symptôme                                   | À vérifier                                                                                                      |
| ------------------------------------------ | --------------------------------------------------------------------------------------------------------------- |
| `unauthorized-domain` lors de la connexion | Domaine exact dans les domaines autorisés Firebase                                                              |
| Erreur CORS / 403 sur une route du VPS     | `WEB_ALLOWED_ORIGINS`, protocole, port, absence de slash final, redémarrage du serveur                          |
| Google ne s'ouvre pas                      | Fenêtres bloquées ; utiliser aussi la connexion e-mail                                                          |
| Le site affiche une ancienne version       | Recharger, vérifier le dernier déploiement et le bon domaine ; les fichiers utilisent une revalidation du cache |
| Vote refusé                                | Présence, unicité, auto-vote, statut, date limite et règles Firestore                                           |
| Résultats non actualisés                   | Service VPS, cron et listeners ; Vercel n'exécute pas ces tâches                                                |
| Build Flutter impossible                   | Version `FLUTTER_VERSION`, accès réseau au SDK, `pubspec.lock`, logs de compilation                             |

## Références

- [Compiler et distribuer Flutter Web](https://docs.flutter.dev/deployment/web)
- [Configuration Vercel](https://vercel.com/docs/project-configuration)
- [Connexion Google avec Firebase et Flutter](https://firebase.google.com/docs/auth/flutter/federated-auth)
- [CNIL : cookies et traceurs](https://www.cnil.fr/fr/cookies-et-autres-traceurs/que-dit-la-loi)
- [CNIL : information et transparence](https://www.cnil.fr/fr/conformite-rgpd-information-des-personnes-et-transparence)

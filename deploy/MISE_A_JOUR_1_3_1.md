# Version 1.3.1 (7) : affichage et notifications de réouverture

## Changements

- Le logo original de 1702 × 1702 pixels est conservé. La connexion et l'accueil utilisent des variantes préparées à 72, 144, 216 et 288 pixels, sélectionnées selon la densité de l'écran, avec un filtrage adapté aux petites tailles. Cela évite de réduire directement l'original de plus de vingt fois dans le navigateur. Après un futur changement du logo source, exécuter `dart run scripts/generate_display_logo.dart` et inclure les variantes générées dans Git.
- Sur ordinateur, **Ma participation aux votes** apparaît après les records, en bas de l'accueil et sur toute la largeur, comme sur mobile.
- La barre de filtres des matchs conserve sa largeur et son alignement lorsqu'un filtre ne retourne aucun résultat.
- À l'ouverture ou à la réouverture d'un vrai match, l'invitation au vote est envoyée seulement aux participants actifs qui n'ont pas encore déposé de bulletin. Les bulletins existants sont conservés. Les rappels de clôture manuelle restent réservés aux admins.
- À la clôture après réouverture, tous les participants actifs, y compris ceux qui avaient déjà voté, reçoivent **Classement actualisé**, qui indique le recalcul avec les votes tardifs. Les notifications des matchs de test restent réservées aux admins, indépendamment des votants simulés. Comme auparavant, la réception push nécessite Android, l'autorisation de notification et un appareil enregistré.

## Pourquoi l'installation de npm 12 échouait

Le `tsc` de ton journal s'est terminé sans erreur : la compilation du backend a réussi. `EBADENGINE` concerne la commande exécutée ensuite, `npm install -g npm@12.2.1`, car cette version de npm refuse Node 20. Il n'est pas nécessaire d'installer npm 12 séparément pour cette application : utilise le npm livré avec Node.

Node 20 est désormais en [fin de maintenance](https://nodejs.org/en/about/eol). Le backend corrigé utilise Firebase Admin 14.5, qui nécessite Node 22 minimum ; la procédure ci-dessous passe à **Node 24 LTS**. Mets Node à jour **avant** d'installer les nouvelles dépendances.

L'audit du verrou local initial signalait 16 vulnérabilités ; ton VPS en signalait 17, avec un arbre installé différent. Firebase Admin, Nodemailer et node-cron ont été mis à jour explicitement, puis les correctifs compatibles de body-parser, proxy-addr et qs appliqués. Le nouveau `package-lock.json` fait partie de la livraison : `npm ci` installe exactement les versions vérifiées. Ne lance pas `npm audit fix --force` sur le VPS.

## Mise à jour du VPS Ubuntu

### 1. Installer Node 24 pour le service système

Cette procédure utilise le dépôt NodeSource, déjà recommandé dans le guide VPS. Le service fourni lance `/usr/bin/node` : installer Node uniquement dans le compte `ubuntu` avec nvm ne changerait pas son runtime.

```bash
curl -fsSL https://deb.nodesource.com/setup_24.x -o /tmp/chc-nodesource-24.sh &&
sudo bash /tmp/chc-nodesource-24.sh &&
sudo apt-get install -y nodejs

/usr/bin/node --version
sudo -u hockey /usr/bin/node --version
sudo -u hockey /usr/bin/npm --version
sudo systemctl show hockey-club-server -p ExecStart
```

Les deux commandes Node doivent afficher `v24...`. Vérifie que `ExecStart` utilise bien `/usr/bin/node` comme le service du dépôt. La configuration du dépôt et les architectures prises en charge sont décrites par [NodeSource](https://github.com/nodesource/distributions/blob/master/DEV_README.md).

### 2. Transférer l'archive complète

Copie `build/chc-backend-update.tar.gz` de ton ordinateur vers `/tmp/chc-backend-update.tar.gz` sur le VPS, avec ton outil habituel. L'archive contient `src/`, `public/`, `test/`, `package.json`, **package-lock.json** et `tsconfig.json`. Elle ne contient ni `.env`, ni clé Firebase, ni `node_modules`.

### 3. Installer et redémarrer après compilation réussie

La sauvegarde contient les fichiers du code précédent, sans les secrets. Arrête le service pendant le remplacement de ses dépendances ; une courte interruption de l'API est donc prévue. Le `&&` empêche un redémarrage avec une compilation échouée.

```bash
cd /opt/hockey-club-server
sudo tar -czf /opt/chc-backend-before-1.3.1-$(date +%Y%m%d-%H%M%S).tar.gz \
  src public dist package.json package-lock.json tsconfig.json &&
sudo systemctl stop hockey-club-server &&
sudo -u hockey tar -xzf /tmp/chc-backend-update.tar.gz -C /opt/hockey-club-server &&
sudo -u hockey /usr/bin/npm ci &&
sudo -u hockey /usr/bin/npm run build &&
sudo -u hockey /usr/bin/npm test &&
sudo systemctl restart hockey-club-server

sudo systemctl status hockey-club-server --no-pager
curl --fail http://127.0.0.1:8080/health
sudo journalctl -u hockey-club-server -n 50 --no-pager
```

Adapte le port du contrôle `/health` si ton service utilise un autre port. En cas d'erreur d'installation ou de compilation, corrige-la avant de redémarrer ; le service reste arrêté. Le `.env` et la clé Firebase existants ne sont pas remplacés. Les tests de `npm test` sont locaux et n'envoient aucun e-mail ni notification.

Si `npm ci` échoue avec `EACCES`, réattribue **les fichiers de l'application** à l'utilisateur du service, puis reprends à `npm ci` :

```bash
sudo chown -R hockey:hockey /opt/hockey-club-server/src \
  /opt/hockey-club-server/public /opt/hockey-club-server/test \
  /opt/hockey-club-server/node_modules /opt/hockey-club-server/dist
sudo chown hockey:hockey /opt/hockey-club-server/package.json \
  /opt/hockey-club-server/package-lock.json /opt/hockey-club-server/tsconfig.json
```

Pour revenir au code précédent, conserve Node 24, arrête le service, extrais la sauvegarde créée ci-dessus dans `/opt/hockey-club-server`, réattribue les fichiers restaurés à `hockey`, puis relance `sudo -u hockey npm ci`, `sudo -u hockey npm run build` et le service. La sauvegarde précède les corrections de dépendances : ce retour doit rester temporaire.

## Publier l'application

Après la mise à jour du backend, publie les changements Git pour déclencher Vercel selon [le guide web](DEPLOY_VERCEL.md). Le script Flutter reste identique. Distribue ensuite la version Android avec la signature habituelle ; le profil affiche **1.3.1 (7)**. L'APK debug produit pour vérification n'est pas un APK de production signé avec la clé du club.

Sur le site, recharge la page après le déploiement pour récupérer le nouveau rendu. Aucun changement de `.env`, d'index ou de règles Firestore n'est nécessaire.

## Vérifier le résultat

Sur ordinateur, l'accueil place la participation sous les records. Dans Matchs, passe de Tous à un filtre vide puis reviens : la barre reste à la même position. Vérifie le contour du logo sur la connexion et l'accueil.

Les tests serveur vérifient sur l'émulateur que les anciens votants sont exclus de l'invitation de réouverture, que les non-votants restent destinataires, que tous les participants retrouvent la notification de résultat et que les matchs de test restent réservés aux admins. Les notifications ne sont pas envoyées en production pendant cette validation.

Validation du 26 octobre 2026 : **66 tests Flutter, 19 tests unitaires serveur et 19 tests d'intégration sur l'émulateur réussis**. Les 24 tests d'affichage ont également été relancés après l'ajout des variantes du logo. Installation serveur depuis le verrou avec `npm ci`, compilation TypeScript et compilation web release réussies ; l'audit serveur final ne signale **aucune vulnérabilité connue**. Le rendu de connexion a été contrôlé dans le navigateur, et l'accueil en bas de page dans les captures de tests mobile et ordinateur. L'analyse Dart ciblée ne signale aucune erreur, seulement deux remarques de style préexistantes. Aucun déploiement en production n'a été effectué.

La compilation APK Android debug a également réussi. Flutter signale la future migration Kotlin des plugins `home_widget`, `package_info_plus` et `share_plus`, sans bloquer cette version. La compilation web conserve un avertissement préexistant concernant la police CupertinoIcons. Ces migrations ne font pas partie de ce correctif.

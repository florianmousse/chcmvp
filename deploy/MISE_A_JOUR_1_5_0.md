# CHC MVP 1.5.0 (12)

## Ce qui change

- Lecteur YouTube Android : l’HTML intégré utilise l’identifiant de l’application comme origine HTTPS et référent, distinct de l’hôte YouTube. Cela corrige l’identification du lecteur. La vidéo `IPQMJo0x8G8` signalée avec l’erreur 152-4 reste à essayer sur un appareil Android ; aucune lecture sur téléphone physique n’a été vérifiée ici. Les restrictions propres à une vidéo restent applicables. L’accord avant chargement et le bouton « Ouvrir YouTube » sont conservés.
- Ballon d’or / Golden Boy : sélectionner le joueur suffit, aucun intitulé de nomination à répéter. Les intitulés d’action restent disponibles pour Puskás, la meilleure passe et les prix personnalisés.
- Vote de cérémonie : les joueurs utilisés à une autre place sont grisés et désactivés, y compris leurs autres actions. La croix efface une place pour modifier son classement avant validation.
- Adresse e-mail : Administration → Membres → Modifier. Le serveur modifie le compte Firebase existant, avec le même UID et le même mot de passe. Votes, statistiques, badges et trophées restent attachés au joueur. L’adresse doit être libre ; elle repasse non vérifiée dans Firebase. En cas d’échec de mise à jour du profil, le serveur tente de rétablir l’ancienne adresse Auth. Les éventuels fournisseurs de connexion liés (Google) restent liés au compte.
- Accueil ordinateur : « Le coin des stats » au-dessus de « Les temps forts », avec grille sur plusieurs colonnes. Titres de section harmonisés.
- Notifications de cérémonie sur les appareils Android ayant autorisé les notifications : ouverture aux votants actifs n’ayant pas voté ; réouverture aux seuls votants sans bulletin valide ; résultats aux votants et nominés actifs sans dévoiler le gagnant. Toucher la notification ouvre la cérémonie. La version web conserve son fonctionnement actuel sans push.
- Matchs **Championnat** (bleu), **Amical** (vert) et **Playoff** (orange). Les anciens matchs sont Championnat par défaut. Les amicaux apparaissent dans Matchs et dans la gestion admin ; ils n’ont aucun vote MVP ni notification de vote, et sont exclus des points, statistiques, badges, bilans, accueil et widgets. L’admin peut saisir le score et terminer le match. Passer un ancien match en amical déclenche le retrait de ses contributions ; ses données brutes restent conservées.

## Paliers vérifiés

| Badge | Bronze | Argent | Or |
|---|---:|---:|---:|
| Buteur, par saison | 5 buts | 15 buts | 25 buts |
| Passeur, par saison | 5 passes | 15 passes | 25 passes |
| Couteau suisse, par saison | 3 buts et 3 passes | 8 buts et 8 passes | 15 buts et 15 passes |

Ce sont des seuils d’obtention, pas des plafonds de statistiques. Les cartons ne contribuent jamais à Couteau suisse. Le meilleur palier encore justifié reste affiché. Cap des 50 cumule 50 points sur plusieurs saisons, hors amicaux, tests et cérémonies.

## Installation

Installer **le backend puis les règles Firestore**, avant de publier les nouvelles applications.
Transférer `build/chc-backend-update-1.5.0.tar.gz` vers `/tmp/` sur le VPS. L’archive contient uniquement `src`, `public`, `package.json` et `package-lock.json`, sans secrets.

```bash
cd /opt/hockey-club-server &&
sudo tar -czf /tmp/chc-server-before-1.5.0.tar.gz \
  src public dist package.json package-lock.json &&
sudo chown -R hockey:hockey src public &&
sudo chown hockey:hockey package.json package-lock.json &&
sudo -u hockey tar -xzf /tmp/chc-backend-update-1.5.0.tar.gz \
  -C /opt/hockey-club-server &&
sudo -u hockey npm ci &&
sudo -u hockey npm run build &&
sudo systemctl restart hockey-club-server
```

```bash
sudo systemctl status hockey-club-server --no-pager
sudo journalctl -u hockey-club-server -n 50 --no-pager
```

Depuis le dépôt sur le PC, publier les règles qui interdisent les votes amicaux et réservent les changements d’e-mail au serveur :

```powershell
firebase deploy --only firestore:rules --project chc-mvp
```

Puis publier le code sur Git pour Vercel et distribuer une nouvelle version Android signée selon les guides existants. Vérifier **1.5.0 (12)** dans le profil. Le fichier `build/app/outputs/flutter-apk/app-debug.apk` sert aux essais, pas à la distribution de production.

Lancer une fois **Administration → Reconstruire les classements maintenant** pour appliquer les seuils et nettoyer les données anciennes. La reconstruction peut attribuer ou retirer des badges et déclencher leurs notifications habituelles. Aucun nouveau paramètre `.env`, aucune mise à jour de Node/npm et aucun index composite ne sont requis.

Les notifications de cérémonie utilisent une file persistante `ceremony_notifications`, inaccessible aux clients. Les échecs sont réessayés toutes les dix minutes et les messages devenus obsolètes sont ignorés. Un arrêt du serveur juste après acceptation par FCM peut produire un doublon lors de la reprise. Les anciennes cérémonies ne déclenchent pas d’annonce tant qu’un admin n’effectue pas une nouvelle ouverture, réouverture ou clôture.

Référence technique du correctif YouTube : [identification des lecteurs intégrés](https://developers.google.com/youtube/terms/required-minimum-functionality#embedded-player-api-client-identity).

Aucun déploiement ni changement des données de production n’est effectué automatiquement par cette préparation.

## Vérifications locales

- Compilation TypeScript et 29 tests unitaires serveur réussis.
- 54 scénarios de règles Firestore et d’intégration vérifiés sur l’émulateur local, dont l’exclusion et le retrait des contributions d’un amical, les reprises de notifications et leurs destinataires.
- Tests Flutter des votes, formulaires, badges, bilans et affichages mobile/ordinateur vérifiés ; les 17 derniers tests ciblés passent après correction du test de sérialisation du modèle.
- Analyse Dart sans erreur de compilation ; des avertissements et conseils de style subsistent.
- Compilation web release et APK Android debug réussies. `build/web/version.json` indique `1.5.0`, numéro `12`.
- La réception réelle des push et la lecture YouTube sur un appareil Android restent à vérifier après installation ; aucun push réel n’a été envoyé pendant les tests.

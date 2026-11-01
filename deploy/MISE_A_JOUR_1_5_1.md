# CHC MVP 1.5.1 (13)

## Changements

- Les matchs amicaux proposent les votes MVP et les notifications habituelles. Leur carte affiche le top 3 après clôture et le nombre de votants. Les admins disposent du suivi de participation dès l’ouverture, ainsi que des actions de clôture, réouverture et réinitialisation d’un bulletin.
- Le podium amical reste propre au match : aucun point officiel, statistique individuelle, badge, bilan du club ou résumé d’accueil ne provient de ces rencontres. Une reconstruction conserve les votes et recalcule leur podium sans réintroduire de contribution officielle.
- Couleurs reprises des miniatures fournies : **Championnat bleu**, **Amical gris**, **Playoff vert**. Le libellé du type reste visible sur la carte.
- Android : le lecteur charge directement la page HTTPS officielle YouTube avec le référent identifiant l’application, au lieu de passer par une page HTML locale et son pont JavaScript. L’autorisation avant chargement reste nécessaire. Les boutons **Réessayer la vidéo**, **Lire dans le navigateur intégré** et **Ouvrir YouTube** permettent de relancer ou poursuivre la lecture.

La vidéo `IPQMJo0x8G8` fonctionne directement sur le téléphone selon le retour utilisateur. Cela oriente vers l’intégration Android, mais la nouvelle lecture intégrée reste à confirmer sur ce téléphone après installation : une compilation ne permet pas de valider la lecture réelle.

Référence : [exigences YouTube pour identifier un lecteur intégré](https://developers.google.com/youtube/terms/required-minimum-functionality#embedded-player-api-client-identity).

## Installation

Installer **le backend puis les règles Firestore**, avant de publier les nouvelles applications. Les règles de la version 1.5.0 interdisaient les votes amicaux : leur mise à jour est indispensable.

Transférer `build/chc-backend-update-1.5.1.tar.gz` vers `/tmp/` sur le VPS. Cette archive contient uniquement `src`, `public`, `package.json` et `package-lock.json`, sans secrets.

```bash
cd /opt/hockey-club-server &&
sudo tar -czf /tmp/chc-server-before-1.5.1.tar.gz \
  src public dist package.json package-lock.json &&
sudo chown -R hockey:hockey src public &&
sudo chown hockey:hockey package.json package-lock.json &&
sudo -u hockey tar -xzf /tmp/chc-backend-update-1.5.1.tar.gz \
  -C /opt/hockey-club-server &&
sudo -u hockey npm ci &&
sudo -u hockey npm run build &&
sudo systemctl restart hockey-club-server
```

```bash
sudo systemctl status hockey-club-server --no-pager
sudo journalctl -u hockey-club-server -n 50 --no-pager
```

Depuis le dépôt sur le PC :

```powershell
firebase deploy --only firestore:rules --project chc-mvp
```

Publier ensuite le code sur Git pour Vercel et distribuer la version Android signée selon les guides existants. Vérifier **1.5.1 (13)** dans le profil. `build/app/outputs/flutter-apk/app-debug.apk` est réservé aux essais ; ce n’est pas une version de distribution de production.

Pour un ancien amical déjà terminé sans vote, choisir **Rouvrir le vote**. Une réouverture manuelle exige une clôture manuelle ; elle conserve les bulletins existants et n’invite à voter que les personnes n’ayant pas encore voté. Les rappels de clôture restent réservés aux admins.

Lancer une fois **Administration → Reconstruire les classements maintenant** pour recalculer les podiums amicaux dont des bulletins existent déjà et nettoyer les contributions officielles anciennes. La reconstruction peut attribuer ou retirer des badges selon les seuls matchs officiels et envoyer leurs notifications habituelles.

Aucun paramètre `.env`, changement de Node/npm ou nouvel index composite n’est requis. Aucun déploiement ni changement des données de production n’est effectué par la préparation locale.

## Vérifications

- Compilation TypeScript réussie.
- 42 tests d’intégration et de règles Firestore réussis sur l’émulateur local, dont les votes amicaux, la reconstruction, la réouverture, la suppression et l’absence de points/badges officiels.
- 28 tests Flutter ciblés réussis : cartes, podium et participation amicaux, bilans, cérémonies, consentement YouTube et construction de la requête Android.
- Analyse statique du nouveau lecteur : aucune anomalie. Compilation web release et APK Android debug réussies en version **1.5.1 (13)**.
- La lecture YouTube réelle et la réception des push restent à vérifier sur téléphone après installation.

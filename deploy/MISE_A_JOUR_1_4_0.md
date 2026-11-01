# Version 1.4.0 (10) — Cérémonies, trophées et paliers de badges

Pour la version actuelle et ses corrections, suivre [la mise à jour 1.4.1](MISE_A_JOUR_1_4_1.md). Les limitations et seuils décrits ci-dessous concernent la version initiale 1.4.0.

## Ce qui change

- **Accueil → Cérémonies** : votes pour un top de 1 à 10, avec Ballon d’or, Golden Boy, Puskás, plus belle passe décisive et prix personnalisé.
- **Administration → Cérémonies** : choix des nominations et des votants, brouillon privé, ouverture, clôture ou annulation.
- Révélation animée du dernier rang du top au premier, manuelle ou automatique, avec pause et replay. Les égalités parfaites sont révélées ensemble.
- Vidéos YouTube intégrées dans les nominations, chargées après un accord explicite pour chaque lecteur. Aucun lecteur ou aperçu distant n’est chargé avant cet accord.
- Trophées séparés des badges sur les profils. Badges et trophées visibles à côté des noms dans le classement, y compris pour les membres actifs à zéro point.
- Badges Buteur et Passeur : bronze à 5, argent à 20, or à 50, dans une même saison. Le meilleur palier obtenu est affiché. Les suppressions et corrections de matchs continuent à recalculer les badges.
- Tutoriel intégré, [guide d’utilisation](GUIDE_UTILISATION.md), confidentialité et conditions d’utilisation actualisés.

## Installer dans cet ordre

Cette version nécessite **le backend et les nouvelles règles Firestore**, puis les applications. Aucune nouvelle variable `.env` ni aucun index composé ne sont nécessaires.

### 1. Backend sur le VPS

L’archive préparée est `build/chc-backend-update-1.4.0.tar.gz`. Elle contient uniquement `src`, `public`, `package.json` et `package-lock.json` du serveur. Elle ne contient ni `.env`, ni clé Firebase, ni `node_modules`.

Transférer l’archive dans `/tmp/chc-backend-update-1.4.0.tar.gz` sur le VPS, puis exécuter :

```bash
cd /opt/hockey-club-server &&
sudo tar -czf /tmp/chc-server-before-1.4.0.tar.gz \
  src public dist package.json package-lock.json &&
sudo chown hockey:hockey package.json package-lock.json &&
sudo -u hockey tar -xzf /tmp/chc-backend-update-1.4.0.tar.gz \
  -C /opt/hockey-club-server &&
sudo -u hockey npm ci &&
sudo -u hockey npm run build &&
sudo systemctl restart hockey-club-server
```

Le service est redémarré uniquement si toutes les étapes précédentes réussissent. En cas d’erreur, conserver le message complet et corriger avant de continuer. Les sources et le dossier `public` doivent déjà appartenir à `hockey`, comme dans les mises à jour précédentes. Node 24 installé sur le VPS convient ; il n’est pas nécessaire de changer npm pour cette fonctionnalité.

Vérifier :

```bash
sudo systemctl status hockey-club-server --no-pager
sudo journalctl -u hockey-club-server -n 40 --no-pager
```

Les nouvelles routes `/ceremonies` exigent un membre authentifié et actif. Création, ouverture, clôture et annulation exigent un admin. Votes et clôture sont transactionnels : un dernier vote concurrent ne peut pas être perdu silencieusement, et une répétition de requête ne double pas les points.

### 2. Règles Firebase depuis le PC

À la racine du dépôt, avec Firebase CLI connecté au projet :

```powershell
firebase deploy --only firestore:rules --project chc-mvp
```

Les membres actifs peuvent lire les cérémonies publiées, les admins peuvent aussi lire les brouillons. Chaque votant peut lire uniquement son propre bulletin. Les écritures directes des cérémonies et des bulletins sont interdites aux applications, même aux admins : elles passent par les contrôles du serveur.

### 3. Web et Android

Publier les changements Git pour déclencher Vercel selon [le guide Vercel](DEPLOY_VERCEL.md). Le script existant génère les pages légales et compile le site.

Pour Android, produire et distribuer une version signée selon [le guide Android](PLAYSTORE_DEPLOYMENT.md). Un APK **debug** est fourni pour validation technique ; il ne remplace pas la version signée du club et peut ne pas pouvoir s’installer par-dessus celle-ci. Le nouveau lecteur YouTube nécessite une nouvelle compilation Android.

Vérifier **Profil → Version de l’application : 1.4.0 (10)**. Si un code de version supérieur a déjà été publié sur Google Play, augmenter le numéro après `+` dans `pubspec.yaml` avant de compiler.

### 4. Recalculer les anciens badges

Après la mise à jour du backend, lancer **Administration → Reconstruire les classements maintenant** une fois pour attribuer les nouveaux paliers aux statistiques existantes. Les attributions peuvent déclencher les notifications habituelles de badges. Les recalculs suivants se font par les mécanismes existants de clôture/correction/suppression de matchs.

Les paliers ne cumulent pas plusieurs saisons. Une récompense d’une ancienne saison est conservée si les matchs qui la justifient existent toujours. Les trophées de cérémonie ne dépendent pas des matchs et ne sont pas supprimés par leur reconstruction.

## Organiser le premier prix

1. Créer par exemple **Ballon d’or 2026**, top 5, depuis Cérémonies.
2. Choisir les nommés et les votants. Les joueurs sans compte peuvent être nommés. Sans auto-vote, chaque votant doit pouvoir sélectionner cinq nominations d’autres joueurs.
3. Vérifier le brouillon puis ouvrir le vote. Chaque bulletin ordonné donne 5, 4, 3, 2 et 1 point.
4. Clôturer quand la participation convient. Les résultats deviennent consultables et les premiers reçoivent leur trophée.
5. Projeter la révélation pour une soirée du club, ou laisser chacun la regarder depuis son appareil.

À égalité de points, le nombre de premières places départage, puis les places suivantes. Une égalité parfaite conserve un rang commun et un trophée pour chaque premier. Aucun vote signifie aucun trophée. Les nominations à zéro point n’apparaissent pas dans le résultat.

Pour une soirée comprenant plusieurs prix, créer une cérémonie par prix. Golden Boy n’impose pas de condition d’âge automatique : l’admin choisit la liste éligible. Les classements sont calculés par nomination ; un même joueur peut avoir plusieurs actions nominées pour Puskás ou la passe décisive.

Les résultats sont publiés dès la clôture, y compris les trophées sur les profils. L’animation est une présentation individuelle rejouable, **pas une diffusion synchronisée ni une publication différée**. Les cérémonies n’envoient pas de notifications push dans cette version.

Les configurations et bulletins sauvegardés ne sont pas éditables, et une clôture est définitive. Avant la clôture, une erreur de configuration peut être corrigée en annulant puis recréant la cérémonie. Pour essayer l’interface sans attribuer de trophée réel, annuler la cérémonie d’essai avant sa clôture.

## YouTube

Les liens `youtube.com/watch`, `youtu.be`, Shorts et embed sont acceptés. Utiliser une vidéo publique ou non répertoriée dont l’auteur autorise l’intégration et pour laquelle le club dispose des autorisations nécessaires. Une vidéo privée, une restriction d’âge ou une interdiction d’intégration peut empêcher la lecture : un lien externe reste disponible. Voir [l’aide YouTube sur l’intégration](https://support.google.com/youtube/answer/171780).

Le joueur choisit **Autoriser YouTube pour cette vidéo** avant toute connexion du lecteur à Google. Ce choix n’est pas mémorisé entre les visites. Il peut fermer le lecteur ou voter sans le charger. Les pages légales expliquent les transferts et cookies possibles. Le fonctionnement du lecteur dépend aussi des restrictions YouTube et du navigateur ; vérifier les vidéos retenues sur Android et sur le site avant la cérémonie.

## Vérifications réalisées

- Compilation TypeScript et 24 tests unitaires serveur réussis.
- 43 tests d’intégration et de règles Firestore réussis sur émulateur local : permissions, confidentialité des bulletins, double vote, clôture concurrente, égalités, annulation, absence de votes et non-régression des reconstructions de matchs.
- 50 tests Flutter réussis, dont vote ordonné, échange de deux places avant confirmation, révélation, paliers, joueurs décorés à zéro point et dispositions téléphone/ordinateur. Captures locales des écrans contrôlées à 390 et 1440 pixels.
- Analyse Flutter ciblée : aucun problème.
- Compilations web release et Android debug réussies.

Les données de production n’ont pas été modifiées et aucun déploiement n’a été effectué. La lecture effective des vidéos sur un téléphone physique reste à vérifier avec les vidéos du club.

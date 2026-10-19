# Version 1.1.0 (3) : suivi des votes et aide

- Les admins voient la participation sur chaque carte de match et dans Administration → Matchs, y compris quand le vote est ouvert. Le détail montre les non-votants et signale les joueurs sans compte ou désactivés.
- Le dénominateur est la liste dédupliquée des joueurs présents, comme pour le taux de participation existant. Un bulletin dont l'auteur n'est plus dans cette liste n'est pas compté. Le suivi ne renvoie aucun choix de vote ni adresse e-mail.
- Le suivi passe par `GET /matches/:matchId/participation`, protégé par authentification Firebase et rôle admin actif. Les matchs de test sont également pris en charge. Il se recharge toutes les 30 secondes tant que le composant est affiché ; quitter l'écran arrête son abonnement.
- **Profil → Tutoriel** contient le guide Android/web, et une partie administration pour les admins. Une [copie à partager](GUIDE_UTILISATION.md) est fournie.
- **Profil → Version de l'application** lit la version réellement empaquetée via `package_info_plus`, sur Android comme sur le web. Elle provient de `pubspec.yaml` (`1.1.0+3`), ou des options `--build-name` / `--build-number` si elles sont utilisées. Incrémenter le numéro de build à chaque nouvelle version Android.

## Installation

1. Mettre le backend à jour avec la nouvelle archive `build/chc-backend-update.tar.gz`, selon [la procédure VPS](AUDIT_STATS_CLASSEMENTS.md#installer-cette-version). Elle inclut `src/voteParticipation.ts` et la route modifiée. Garder le `.env` et le compte de service existants.
2. Publier les changements Git, notamment `pubspec.yaml` et `pubspec.lock`, pour redéployer Vercel. Le script installe le nouveau plugin et compile le site. Le fichier `version.json` généré par Flutter doit être servi avec le reste de `build/web` (la configuration Vercel existante le prévoit).
3. Recompiler et distribuer l'application Android avec `flutter build apk --release` ou la commande de publication habituelle. Le numéro de build devient 3 par défaut ; s'il existe déjà une version distribuée avec un numéro supérieur, choisir un numéro supérieur à celle-ci.
4. Avec un compte admin, ouvrir le suivi d'un match, faire voter un autre compte, puis actualiser : le compteur augmente et le nom disparaît. Avec un compte membre, le suivi ne doit pas apparaître. Vérifier aussi **Profil → Tutoriel** et **Version de l'application** sur les deux plateformes.

Aucun changement supplémentaire des règles Firestore ni du `.env` n'est nécessaire par rapport à la version précédente. Les règles protégeant les matchs de test et les badges restent nécessaires si cette version précédente n'a pas encore été installée. Le suivi sera indisponible tant que le VPS n'expose pas la nouvelle route.

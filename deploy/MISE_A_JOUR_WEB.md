# Mise à jour : web et joueurs sans e-mail

Pour la version **1.1.0 (3)** (suivi des votes réservé aux admins, tutoriel et numéro de version dans Profil), suivre aussi [les instructions de mise à jour](MISE_A_JOUR_1_1_0.md). Le [guide d'utilisation Android/web](GUIDE_UTILISATION.md) peut être partagé aux membres.

## Changements

- Connexion web : champs HTML visibles avec `autocomplete="username"` et `autocomplete="current-password"`. Les identifiants sont lus au moment de la soumission, même si le gestionnaire de mots de passe ne déclenche aucun événement de saisie. Le formulaire mobile natif reste en Flutter.
- Ordinateur : navigation latérale étendue, résumé personnel et cartes de matchs en grille, statistiques en colonnes, badges tous visibles, profil en deux colonnes et formulaires de largeur limitée. Les petits écrans conservent leurs carrousels et leur navigation mobile.
- Badges : obtenus en premier, plus récents en tête. Leur validité est désormais recalculée par le serveur après suppression d'un match ; voir la procédure ci-dessous.
- Administration → Membres → Ajouter : l'e-mail est facultatif. Sans e-mail, une fiche joueur est créée sans compte Firebase Authentication ni invitation. Ajoute ce joueur aux présents du match pour pouvoir voter pour lui.
- Pour inviter ce joueur plus tard : ouvre **Modifier**, renseigne son e-mail et clique sur **Enregistrer et inviter**. Son identifiant reste le même, donc ses résultats, statistiques et badges restent associés à sa fiche. Un joueur sans compte ne peut pas se connecter ni déposer de vote.
- Les comptes existants restent compatibles ; aucune migration de données n'est nécessaire. Une adresse déjà utilisée par un autre compte est refusée sans fusionner les fiches.

## Déployer

1. Mets d'abord le backend à jour sur le VPS suivant la [procédure du guide Vercel](DEPLOY_VERCEL.md#5-autoriser-le-frontend-sur-le-vps-cors). L'archive doit inclure le nouveau fichier `server/src/members.ts`, en plus du routeur modifié. Recrée l'archive après toute modification du backend ; ne réutilise pas une archive ancienne.
2. Pousse ensuite les modifications de l'application, y compris `pubspec.yaml`, `pubspec.lock`, les champs web et les pages légales. Relance le déploiement Vercel.
3. Dans Administration, crée un joueur sans e-mail, ajoute-le aux présents d'un match et vérifie qu'il apparaît parmi les candidats. Pour ouvrir un accès, modifie ensuite cette même fiche plutôt que de créer un deuxième joueur.

Si le serveur n'a pas encore été mis à jour, il refusera l'ajout sans e-mail. Si l'envoi d'une invitation échoue après création du compte, utilise « Mot de passe oublié » pour renvoyer le lien ; le compte est conservé.

## Vérifications locales

```bash
flutter test test/web_compatibility_test.dart test/product_updates_test.dart test/member_form_test.dart
node server/node_modules/typescript/bin/tsc -p server/tsconfig.json
npm --prefix server test
flutter build web --release --no-web-resources-cdn --dart-define=SERVER_BASE_URL=https://chc-mvp.duckdns.org
```

Le contrôle navigateur utilise un formulaire isolé et des identifiants fictifs, sans contacter Firebase :

```bash
flutter build web --release --no-web-resources-cdn --target=test/support/web_login_harness.dart --output=build/login-preview
node scripts/test-web-login.mjs
```

Chrome est cherché à son emplacement Windows standard. Pour un autre emplacement ou système, définis `CHROME_EXECUTABLE` avec son chemin. Les ports locaux 8086 et 9227 doivent être libres. Les aperçus et le profil Chrome de test sont dans `build/`, ignoré par Git. Cette compilation de test est séparée de `build/web`, qui reste la sortie destinée à Vercel.

L'extension Bitwarden elle-même n'est pas incluse dans ce test. Sur le site déployé, vérifie que l'entrée du coffre correspond au domaine du site, puis teste le remplissage et la connexion. Les champs natifs suivent le fonctionnement décrit par [Bitwarden](https://contributing.bitwarden.com/architecture/deep-dives/autofill/) et sont intégrés grâce à [HtmlElementView de Flutter](https://docs.flutter.dev/platform-integration/web/web-content-in-flutter).

## Audit des statistiques et des classements

Voir [les correctifs et la procédure de reconstruction](AUDIT_STATS_CLASSEMENTS.md) pour la mise à jour du serveur **et des règles Firestore**, le nettoyage des anciens matchs supprimés, le recalcul des badges et l'utilisation des matchs de test réservés aux admins. Cette procédure est celle à suivre pour la version actuelle.

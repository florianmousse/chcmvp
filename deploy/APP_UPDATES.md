# Alerte facultative de mise à jour

Au démarrage, puis au retour au premier plan (au plus une vérification toutes
les 15 minutes), l'application vérifie la disponibilité d'une nouvelle version.
Une popup propose « Mettre à jour » ou « Plus tard ». Une version déjà proposée
ne l'est plus pendant la même session. Une panne de réseau ou de boutique ne
bloque pas l'accès ; un diagnostic sans données personnelles est journalisé.

## Android

La vérification utilise l'API Google Play via `in_app_update` 5.0.0 (licence MIT,
Flutter 3.44 / Dart 3.12 minimum, compatible avec le SDK 3.44.9 du projet).
Cette dépendance évite d'extraire des pages HTML de la boutique ou de maintenir
une version globale qui ignorerait les pistes et déploiements progressifs.
Le bouton ouvre la fiche Google Play ; l'installation reste volontaire.
Il n'y a aucun téléchargement d'APK ni mise à jour obligatoire.

Les installations hors Google Play peuvent ne pas disposer de cette vérification.
Les autres plateformes natives ne proposent pas cette alerte actuellement.
Les comptes de review utilisent le même parcours, sans lecture ni écriture des
données du club et sans notification aux membres.

Pour valider : installer depuis Google Play une version contenant cette fonction,
puis rendre disponible une version de build supérieur sur la piste du compte de
test. Vérifier la popup, « Plus tard », le retour à l'application et l'ouverture
de la boutique. Vérifier aussi un compte à jour et un appareil hors connexion.
Un APK de debug ne prouve pas le fonctionnement sur Google Play.
Voir [les instructions Google](https://developer.android.com/guide/playcore/in-app-updates/test).

## Web

Le script Vercel lit `pubspec.yaml` avec `scripts/read-app-version.mjs` et compile
`APP_BUILD_VERSION` dans le bundle. L'application compare cette valeur au fichier
`version.json` généré par Flutter, sur la même origine, avec une URL non mise en
cache. Seule une version numérique supérieure déclenche la popup « Recharger ».
Le rechargement est volontaire pour préserver les formulaires en cours.

Pour une compilation manuelle PowerShell :

```powershell
$appBuildVersion = node scripts/read-app-version.mjs
flutter build web --release --no-web-resources-cdn --dart-define="APP_BUILD_VERSION=$appBuildVersion" --dart-define=SERVER_BASE_URL=https://api.example.invalid
```

Sans cette valeur, la vérification web est indisponible et produit un diagnostic.
Augmenter la version dans `pubspec.yaml` lors d'une publication ; conserver le
fichier `version.json` généré et les en-têtes de revalidation de `vercel.json`.
Pour valider, ouvrir un build A sur téléphone et ordinateur, publier un build B
de version supérieure dans un environnement de test, puis remettre l'onglet A
au premier plan après 15 minutes. Vérifier report et rechargement, clavier et
texte agrandi. Un retour arrière vers une version inférieure ne déclenche pas
d'alerte. Pour retirer la fonction, revenir au code précédent et reconstruire.

Cette fonction ne peut pas s'ajouter rétroactivement aux anciennes installations :
une première mise à jour manuelle contenant ce code est nécessaire.

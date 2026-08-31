/// Mêmes informations que server/.env (CLUB_NAME) — dupliquées ici côté
/// client puisque l'app et le serveur sont deux projets séparés.
const String clubName = 'Châteaubourg Hockey Club';

/// Logo affiché en local (voir pubspec.yaml > flutter > assets) — pas de
/// requête réseau à chaque affichage de l'accueil, contrairement à une URL.
/// Place ton fichier exactement à ce chemin (crée le dossier assets/logo/ à
/// la racine du projet, à côté de lib/) avant de lancer `flutter pub get` :
/// un asset déclaré ici mais absent du disque fait échouer le build.
const String clubLogoAssetPath = 'assets/logo/logo.png';

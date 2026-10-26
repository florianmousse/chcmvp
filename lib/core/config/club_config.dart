/// Mêmes informations que server/.env (CLUB_NAME) - dupliquées ici côté
/// client puisque l'app et le serveur sont deux projets séparés.
const String clubName = 'Châteaubourg Hockey Club';

/// Logo affiché en local (voir pubspec.yaml > flutter > assets) - pas de
/// requête réseau à chaque affichage de l'accueil, contrairement à une URL.
/// Variantes adaptées aux petites tailles et à la densité de l'écran.
/// Après remplacement de assets/logo/logo.png, les régénérer avec
/// `dart run scripts/generate_display_logo.dart`.
const String clubLogoAssetPath = 'assets/logo/display/club.png';

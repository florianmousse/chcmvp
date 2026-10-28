# Logo du club

- `logo.svg` : original fourni par le club, conservé tel quel.
- `display/club.svg` : version utilisée par le widget `ClubLogo` sur Android et le web. Les six classes CSS de l'original sont remplacées par leurs attributs `fill`, `fill-rule`, `stroke`, `stroke-width` et `stroke-miterlimit`. Les tracés et le `viewBox` sont inchangés. Cette préparation évite de dépendre du support des feuilles CSS par le lecteur SVG Flutter.
- `web/logo.svg` (à la racine du projet) : copie de l'original pour l'écran de chargement HTML.

L'accueil et la connexion affichent le dessin à 72 pixels logiques. Les PNG restent disponibles pour les usages nécessitant un bitmap, notamment les icônes ; le générateur `scripts/generate_display_logo.dart` concerne uniquement les anciennes variantes PNG.

Après un futur remplacement du SVG, conserver les couleurs et les règles de remplissage lors de la préparation Flutter, puis vérifier le rendu des animaux, des cercles et des inscriptions. Ne pas convertir le SVG en bitmap pour ces deux écrans.

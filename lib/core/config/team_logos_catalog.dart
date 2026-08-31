/// Un logo à ajouter ici = un fichier ajouté dans assets/team_logos/ (voir
/// pubspec.yaml) + une entrée dans cette liste + un rebuild de l'app. Une
/// fois fait, il apparaît dans le sélecteur du formulaire de match — plus
/// besoin de retoucher au code pour l'associer à tel ou tel match ensuite,
/// ça se choisit directement dans l'app à la création/édition.
class TeamLogoOption {
  const TeamLogoOption({required this.name, required this.assetPath});
  final String name;
  final String assetPath;
}

const List<TeamLogoOption> teamLogosCatalog = [
  TeamLogoOption(name: 'Nantes', assetPath: 'assets/team_logos/nantes.png'),
  TeamLogoOption(
    name: 'Carquefou',
    assetPath: 'assets/team_logos/carquefou.png',
  ),
  TeamLogoOption(name: 'Rennes', assetPath: 'assets/team_logos/rennes.png'),
  TeamLogoOption(
    name: 'St. Gilles',
    assetPath: 'assets/team_logos/st_gilles.png',
  ),
  TeamLogoOption(name: 'Angers', assetPath: 'assets/team_logos/angers.png'),
  TeamLogoOption(name: 'La Baule', assetPath: 'assets/team_logos/la_baule.png'),
  TeamLogoOption(name: 'Laval', assetPath: 'assets/team_logos/laval.png'),
  TeamLogoOption(name: 'Le Mans', assetPath: 'assets/team_logos/le_mans.png'),
  TeamLogoOption(name: 'Pordic', assetPath: 'assets/team_logos/pordic.png'),
  TeamLogoOption(name: 'Segre', assetPath: 'assets/team_logos/segre.png'),
  TeamLogoOption(name: 'St. Seb', assetPath: 'assets/team_logos/st_seb.png'),
  TeamLogoOption(name: 'CHC', assetPath: 'assets/team_logos/chc.png'),
];

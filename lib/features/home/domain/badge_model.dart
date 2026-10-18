/// Modèle de badge — représente un accomplissement qu'un joueur peut
/// débloquer au fil de la saison. Calculé côté client puis synchronisé
/// dans Firestore (`userBadges/{userId}`) avec la date d'obtention.
enum BadgeType {
  mvpSaison,
  serieTop3,
  plebiscite,
  revelation,
  votantAssidu,
  centurion,
  podiumMaster,
  regularite,
  buteur,
  passeurDor,
  fairPlay,
  couteauSuisse,
}

class Badge {
  const Badge({
    required this.type,
    required this.label,
    required this.emoji,
    required this.description,
  });

  final BadgeType type;
  final String label;
  final String emoji;
  final String description;

  static const allDefinitions = <BadgeType, Badge>{
    BadgeType.mvpSaison: Badge(
      type: BadgeType.mvpSaison,
      label: 'MVP de la saison',
      emoji: '🏆',
      description: 'Numéro 1 au classement général de la saison.',
    ),
    BadgeType.serieTop3: Badge(
      type: BadgeType.serieTop3,
      label: 'En feu',
      emoji: '🔥',
      description: '5 matchs consécutifs (ou plus) dans le top 3.',
    ),
    BadgeType.plebiscite: Badge(
      type: BadgeType.plebiscite,
      label: 'Plébiscité',
      emoji: '🤝',
      description:
          'A reçu des votes de 80 % ou plus des coéquipiers sur un match.',
    ),
    BadgeType.revelation: Badge(
      type: BadgeType.revelation,
      label: 'Révélation',
      emoji: '🚀',
      description:
          'Moyenne de points en hausse de +40 % par rapport à ses 5 premiers matchs.',
    ),
    BadgeType.votantAssidu: Badge(
      type: BadgeType.votantAssidu,
      label: 'Votant assidu',
      emoji: '🗳️',
      description:
          '100 % de participation aux votes sur au moins une saison complète.',
    ),
    BadgeType.centurion: Badge(
      type: BadgeType.centurion,
      label: 'Centurion',
      emoji: '💯',
      description: '100 points ou plus cumulés en une saison.',
    ),
    BadgeType.podiumMaster: Badge(
      type: BadgeType.podiumMaster,
      label: 'Podium Master',
      emoji: '🥇',
      description: '10 premières places ou plus en une saison.',
    ),
    BadgeType.regularite: Badge(
      type: BadgeType.regularite,
      label: 'Régularité',
      emoji: '📊',
      description:
          'L\'écart-type de points le plus faible de l\'équipe (min. 5 matchs).',
    ),
    BadgeType.buteur: Badge(
      type: BadgeType.buteur,
      label: 'Buteur',
      emoji: '⚽',
      description: '5 buts ou plus marqués en une saison.',
    ),
    BadgeType.passeurDor: Badge(
      type: BadgeType.passeurDor,
      label: 'Passeur d\'or',
      emoji: '🎯',
      description: '5 passes décisives ou plus en une saison.',
    ),
    BadgeType.fairPlay: Badge(
      type: BadgeType.fairPlay,
      label: 'Fair-play',
      emoji: '😇',
      description:
          'Aucun carton jaune ou rouge en au moins 5 matchs joués.',
    ),
    BadgeType.couteauSuisse: Badge(
      type: BadgeType.couteauSuisse,
      label: 'Couteau suisse',
      emoji: '🦸',
      description:
          'Au moins 3 buts, 3 passes D. et 3 cartons verts en une saison.',
    ),
  };
}

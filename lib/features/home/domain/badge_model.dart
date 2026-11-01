/// Modèle de badge - représente un accomplissement qu'un joueur peut
/// débloquer au fil de la saison. Calculé côté serveur puis enregistré
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
  capDes50,
}

class Badge {
  const Badge({
    required this.type,
    required this.label,
    required this.emoji,
    required this.description,
    this.tier,
    this.earnedKey,
  });

  final BadgeType type;
  final String label;
  final String emoji;
  final String description;
  final String? tier;
  final String? earnedKey;

  static Badge forEarned(BadgeType type, Iterable<String> keys) {
    final base = allDefinitions[type]!;
    if (type != BadgeType.buteur &&
        type != BadgeType.passeurDor &&
        type != BadgeType.couteauSuisse) {
      return base;
    }
    final swiss = type == BadgeType.couteauSuisse;
    final prefix = swiss
        ? 'couteauSuisse'
        : type == BadgeType.buteur
        ? 'buteur'
        : 'passeur';
    final gold = keys.contains('${prefix}Or');
    final silver = keys.contains('${prefix}Argent');
    final tier = gold
        ? 'Or'
        : silver
        ? 'Argent'
        : 'Bronze';
    final earnedKey = gold
        ? '${prefix}Or'
        : silver
        ? '${prefix}Argent'
        : type.name;
    final noun = type == BadgeType.buteur ? 'buts' : 'passes décisives';
    return Badge(
      type: type,
      label:
          '${swiss
              ? 'Couteau suisse'
              : type == BadgeType.buteur
              ? 'Buteur'
              : 'Passeur'} · $tier',
      emoji: base.emoji,
      tier: tier,
      earnedKey: earnedKey,
      description: swiss
          ? '$tier : au moins ${gold
                ? 15
                : silver
                ? 8
                : 3} buts ET autant de passes décisives en une saison.\nBronze : 3 + 3 · Argent : 8 + 8 · Or : 15 + 15.'
          : '$tier : ${gold
                ? 25
                : silver
                ? 15
                : 5} $noun en une saison.\nBronze : 5 · Argent : 15 · Or : 25.',
    );
  }

  static const allDefinitions = <BadgeType, Badge>{
    BadgeType.capDes50: Badge(
      type: BadgeType.capDes50,
      label: 'Cap des 50',
      emoji: '⭐',
      description:
          '50 points de classement cumulés sur l’ensemble des saisons.',
    ),
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
      description:
          '3 matchs joués consécutifs (ou plus) dans le top 3 en une saison.',
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
          'Moyenne de points des matchs suivants en hausse de 40 % ou plus par rapport aux 3 premiers matchs de la saison (au moins 4 matchs, moyenne initiale non nulle).',
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
      description: '30 points ou plus cumulés en une saison.',
    ),
    BadgeType.podiumMaster: Badge(
      type: BadgeType.podiumMaster,
      label: 'Podium Master',
      emoji: '🥇',
      description: '5 premières places ou plus en une saison.',
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
          'Aucun carton (vert, jaune ou rouge) en au moins 5 matchs renseignés.',
    ),
    BadgeType.couteauSuisse: Badge(
      type: BadgeType.couteauSuisse,
      label: 'Couteau suisse',
      emoji: '🦸',
      description:
          'Au moins 3 buts et 3 passes décisives en une saison. Paliers : bronze 3 + 3, argent 8 + 8, or 15 + 15. Aucun carton requis.',
    ),
  };
}

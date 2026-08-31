/// Identifiant de saison sportive : de septembre à août, comme côté serveur
/// (voir server/src/season.ts) — un match de septembre 2026 appartient à la
/// même saison qu'un match de mars 2027 (saison "2026-2027").
String seasonId(DateTime date) {
  final startYear = date.month >= 9 ? date.year : date.year - 1;
  return '$startYear-${startYear + 1}';
}

/// Année de départ de la saison en cours (ex: 2026 pour la saison "2026-2027").
int currentSeasonStartYear() {
  final now = DateTime.now();
  return now.month >= 9 ? now.year : now.year - 1;
}

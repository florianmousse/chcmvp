/**
 * Identifiant de saison sportive : de septembre à août, plutôt que l'année
 * civile. Un match en septembre 2026 fait partie de la même saison qu'un
 * match en mars 2027 (saison "2026-2027"), pas de deux saisons différentes.
 */
export function seasonId(date: Date): string {
  const year = date.getUTCFullYear();
  const month = date.getUTCMonth() + 1; // 1-12
  const startYear = month >= 9 ? year : year - 1;
  return `${startYear}-${startYear + 1}`;
}

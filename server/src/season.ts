/**
 * Identifiant de saison sportive : de septembre à août, plutôt que l'année
 * civile. Un match en septembre 2026 fait partie de la même saison qu'un
 * match en mars 2027 (saison "2026-2027"), pas de deux saisons différentes.
 */
export function seasonId(date: Date): string {
  const { year, month } = clubCalendar(date);
  const startYear = month >= 9 ? year : year - 1;
  return `${startYear}-${startYear + 1}`;
}

// The match date picker stores local midnight as a UTC timestamp. Using UTC
// calendar fields assigns September 1st in France to the previous season.
function clubCalendar(date: Date): { year: number; month: number } {
  const parts = new Intl.DateTimeFormat("en-GB", {
    timeZone: "Europe/Paris", year: "numeric", month: "2-digit",
  }).formatToParts(date);
  return {
    year: Number(parts.find((part) => part.type === "year")!.value),
    month: Number(parts.find((part) => part.type === "month")!.value),
  };
}

export function monthId(date: Date): string {
  const { year, month } = clubCalendar(date);
  return `${year}-${String(month).padStart(2, "0")}`;
}

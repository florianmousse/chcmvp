import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { Tally } from "./matchTally";
import { seasonId } from "./season";

export interface BadgeMatch {
  id: string;
  date: Date;
  team: string;
  present: string[];
  entries: Record<string, Tally>;
  distinctVoters: Record<string, number>;
  voters: Set<string>;
  gameStats: Record<string, Record<string, number>>;
}

/** Re-evaluate every season still represented by real matches. Keeping the union
 * preserves earlier-season achievements, but deleted source matches cannot count. */
export function calculateBadges(matches: BadgeMatch[], now = new Date()): Map<string, Set<string>> {
  const earned = new Map<string, Set<string>>();
  const seasons = new Map<string, BadgeMatch[]>();
  for (const match of matches) {
    if (match.id.startsWith("test:")) continue;
    const season = seasonId(match.date);
    if (!seasons.has(season)) seasons.set(season, []);
    seasons.get(season)!.push(match);
  }
  for (const [season, seasonMatches] of seasons) {
    seasonMatches.sort((a, b) => a.date.getTime() - b.date.getTime() || a.id.localeCompare(b.id));
    const histories = new Map<string, BadgeMatch[]>();
    for (const match of seasonMatches) for (const uid of new Set(match.present)) {
      if (!histories.has(uid)) histories.set(uid, []);
      histories.get(uid)!.push(match);
    }
    const pointsOf = (uid: string, history: BadgeMatch[]) => history.map((m) => m.entries[uid]?.points ?? 0);
    const total = (values: number[]) => values.reduce((a, b) => a + b, 0);
    const deviation = (values: number[]) => {
      const mean = total(values) / values.length;
      return Math.sqrt(total(values.map((p) => (p - mean) ** 2)) / values.length);
    };
    const maxPoints = Math.max(0, ...[...histories].map(([uid, h]) => total(pointsOf(uid, h))));
    const finished = season < seasonId(now);
    for (const [uid, history] of histories) {
      const badges = earned.get(uid) ?? new Set<string>();
      earned.set(uid, badges);
      const points = pointsOf(uid, history);
      const totalPoints = total(points);
      const firstCount = history.filter((m) => m.entries[uid]?.firstCount).length;
      if (finished && maxPoints > 0 && totalPoints === maxPoints) badges.add("mvpSaison");
      if (totalPoints >= 100) badges.add("centurion");
      if (firstCount >= 10) badges.add("podiumMaster");
      let streak = 0;
      for (const match of history) {
        const entry = match.entries[uid];
        streak = entry && entry.firstCount + entry.secondCount + entry.thirdCount > 0 ? streak + 1 : 0;
        if (streak >= 5) badges.add("serieTop3");
        if (match.present.length && (match.distinctVoters[uid] ?? 0) / match.present.length >= .8) {
          badges.add("plebiscite");
        }
      }
      if (points.length >= 6) {
        const start = total(points.slice(0, 5)) / 5;
        const rest = total(points.slice(5)) / (points.length - 5);
        if (start > 0 && (rest - start) / start >= .4) badges.add("revelation");
      }
      if (finished && history.length && history.every((m) => m.voters.has(uid))) badges.add("votantAssidu");
      if (history.length >= 5) {
        const myTeams = new Set(history.map((m) => m.team));
        const mine = deviation(points);
        const moreRegular = [...histories].some(([other, h]) => other !== uid && h.length >= 5 &&
          h.some((m) => myTeams.has(m.team)) && deviation(pointsOf(other, h)) < mine);
        if (!moreRegular) badges.add("regularite");
      }
      const sheets = history.map((m) => m.gameStats[uid]);
      const sum = (field: string) => total(sheets.map((s) => Math.max(0, Number(s?.[field] ?? 0))));
      const goals = sum("goals"), assists = sum("assists"), green = sum("greenCards");
      if (goals >= 5) badges.add("buteur");
      if (assists >= 5) badges.add("passeurDor");
      if (goals >= 3 && assists >= 3 && green >= 3) badges.add("couteauSuisse");
      if (history.length >= 5 && sheets.every(Boolean) && green + sum("yellowCards") + sum("redCards") === 0) {
        badges.add("fairPlay");
      }
    }
  }
  return earned;
}

export async function rebuildBadges(matches: BadgeMatch[], db = getFirestore(), now = new Date()): Promise<number> {
  const computed = calculateBadges(matches, now);
  const previous = await db.collection("userBadges").get();
  const existing = new Map(previous.docs.map((d) => [d.id, d.data().earned ?? {}]));
  const uids = new Set([...computed.keys(), ...existing.keys()]);
  let batch = db.batch(), pending = 0, changed = 0;
  for (const uid of uids) {
    const types = computed.get(uid) ?? new Set<string>();
    const before = existing.get(uid) ?? {};
    if (Object.keys(before).length === types.size && [...types].every((type) => before[type])) continue;
    const earned = Object.fromEntries([...types].map((type) => [type, before[type] ?? Timestamp.fromDate(now)]));
    batch.set(db.doc(`userBadges/${uid}`), { earned, updatedAt: Timestamp.fromDate(now) });
    pending++; changed++;
    if (pending >= 400) { await batch.commit(); batch = db.batch(); pending = 0; }
  }
  if (pending) await batch.commit();
  return changed;
}

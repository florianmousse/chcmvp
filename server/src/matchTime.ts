import { Timestamp } from 'firebase-admin/firestore';

const calendar = new Intl.DateTimeFormat('en-GB', {
  timeZone: 'Europe/Paris', year: 'numeric', month: '2-digit', day: '2-digit',
  hour: '2-digit', minute: '2-digit', hourCycle: 'h23',
});
function parts(date: Date): Record<string, number> {
  return Object.fromEntries(calendar.formatToParts(date)
    .filter(p => p.type !== 'literal').map(p => [p.type, Number(p.value)]));
}

/** Legacy timestamps retain their Paris calendar date. New clients also send
 * a civil date, avoiding dependence on the device's current timezone. */
export function matchDateTime(date: Timestamp, time: string, civilDate?: string): number {
  if (!/^([01]\d|2[0-3]):[0-5]\d$/.test(time)) throw new Error('Heure de match invalide.');
  const old = parts(date.toDate());
  const [year, month, day] = civilDate ? civilDate.split('-').map(Number) : [old.year, old.month, old.day];
  const [hour, minute] = time.split(':').map(Number);
  const wall = Date.UTC(year, month - 1, day, hour, minute);
  // Try both Paris offsets: reject nonexistent spring times; choose the first
  // occurrence of an ambiguous autumn time deterministically.
  for (const offset of [2, 1]) {
    const candidate = wall - offset * 3600000;
    const p = parts(new Date(candidate));
    if (p.year === year && p.month === month && p.day === day && p.hour === hour && p.minute === minute) return candidate;
  }
  throw new Error('Date ou heure inexistante dans le fuseau Europe/Paris.');
}

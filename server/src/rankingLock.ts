// One VPS process owns the listeners and HTTP routes. Serialize every ranking
// writer so a manual rebuild cannot overlap a closure or a deletion.
let pending: Promise<unknown> = Promise.resolve();

export function withRankingLock<T>(work: () => Promise<T>): Promise<T> {
  const result = pending.then(work);
  pending = result.catch(() => undefined);
  return result;
}

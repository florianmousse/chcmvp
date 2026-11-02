import { getReviewSpaceUid } from './database';

// Serialize calculations per data space: a review rebuild never blocks the club queue.
const queues = new Map<string, Promise<unknown>>();
export function withRankingLock<T>(work: () => Promise<T>): Promise<T> {
  const key = getReviewSpaceUid() ?? 'production';
  const result = (queues.get(key) ?? Promise.resolve()).then(work);
  const pending = result.catch(() => undefined);
  queues.set(key, pending);
  void pending.finally(() => { if (queues.get(key) === pending) queues.delete(key); });
  return result;
}

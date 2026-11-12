import { createHash } from 'node:crypto';
import { Timestamp } from 'firebase-admin/firestore';

export function resultsFingerprint(match: FirebaseFirestore.DocumentData): string {
  const fields = ['resultsRevision', 'status', 'date', 'time', 'team', 'matchType', 'pointsScale', 'presentPlayerIds', 'scoreHome', 'scoreAway', 'allowSelfVote'];
  return createHash('sha256').update(JSON.stringify(fields.map(key => {
    const value: unknown = match[key];
    return value instanceof Timestamp ? value.toMillis() : value ?? null;
  }))).digest('hex');
}


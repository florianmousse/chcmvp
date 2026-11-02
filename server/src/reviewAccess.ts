export function canManageMatch(user: any, matchId: string, match: any): boolean {
  return user?.isActive === true && (user.role === 'admin' ||
    (user.role === 'reviewer' && matchId.startsWith('test:') &&
      match?.reviewCreatedBy === user.uid));
}

export function isSilentReviewMatch(match: any): boolean {
  return typeof match?.reviewCreatedBy === 'string' && match.reviewCreatedBy.length > 0;
}
import { getFirestore } from 'firebase-admin/firestore';
import { matchReference } from './matchReference';


export async function suppressMatchNotification(matchId: string | undefined, db = getFirestore()) {
  if (!matchId?.startsWith('test:')) return false;
  const snapshot = await matchReference(matchId, db).get();
  // A concurrent deletion must not allow a delayed review notification through.
  return !snapshot.exists || isSilentReviewMatch(snapshot.data());
}

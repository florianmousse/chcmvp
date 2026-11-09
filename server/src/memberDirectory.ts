import { FieldPath, Firestore } from 'firebase-admin/firestore';

// Explicit projection: new private fields never become public by accident.
export function directoryProfile(uid: string, data: Record<string, unknown>, includeContact = false) {
  return {
    uid, firstName: data.firstName, lastName: data.lastName, team: data.team,
    photoUrl: data.photoUrl ?? null, jerseyNumber: data.jerseyNumber ?? null,
    role: data.role, isActive: data.isActive,
    // The public model requires email, but contacts are only loaded by admins.
    email: includeContact && typeof data.email === 'string' ? data.email : '',
  };
}

export async function memberDirectory(uid: string, cursor: unknown, db: Firestore) {
  const actor = (await db.doc(`users/${uid}`).get()).data();
  if (actor?.isActive !== true || !['member', 'admin'].includes(actor.role)) {
    throw Object.assign(new Error('Accès refusé.'), { status: 403 });
  }
  if (cursor !== undefined && (typeof cursor !== 'string' || !cursor || cursor.length > 1500 || cursor.includes('/'))) {
    throw Object.assign(new Error('Page invalide.'), { status: 400 });
  }
  let query = db.collection('users').orderBy(FieldPath.documentId()).limit(100);
  if (typeof cursor === 'string') query = query.startAfter(cursor);
  const page = await query.get();
  return {
    members: page.docs.filter(d => d.data().role !== 'reviewer').map(d => directoryProfile(d.id, d.data(), actor.role === 'admin')),
    nextCursor: page.size === 100 ? page.docs[page.size - 1].id : null,
  };
}

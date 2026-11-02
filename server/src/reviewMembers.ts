import type { Auth } from 'firebase-admin/auth';
import type { Firestore } from 'firebase-admin/firestore';

/** Profile/account simulations only. This adapter never calls Firebase Auth or SMTP. */
export function simulatedAuth(db: Firestore): Auth {
  const missing = () => Object.assign(new Error('Compte simulé introuvable.'), { code: 'auth/user-not-found' });
  const collection = db.collection('simulated_accounts');
  return {
    async createUser(input: any) {
      const ref = collection.doc(input.uid);
      await db.runTransaction(async tx => {
        const existing = await tx.get(ref);
        const duplicates = await tx.get(collection.where('email', '==', input.email));
        if (existing.exists) throw Object.assign(new Error('Compte déjà invité.'), { code: 'auth/uid-already-exists' });
        if (!duplicates.empty) throw Object.assign(new Error('Adresse déjà utilisée dans cet espace.'), { code: 'auth/email-already-exists' });
        // Intentionally discard generated passwords, tokens and reset links.
        tx.create(ref, { uid: input.uid, email: input.email, disabled: input.disabled ?? false });
      });
      return { uid: input.uid, email: input.email };
    },
    async getUser(uid: string) {
      const data = (await collection.doc(uid).get()).data();
      if (data) return data;
      const profile = (await db.doc(`users/${uid}`).get()).data();
      if (!profile?.email) throw missing();
      return { uid, email: profile.email, disabled: !profile.isActive, emailVerified: false };
    },
    async updateUser(uid: string, fields: any) {
      const ref = collection.doc(uid);
      const profile = (await db.doc(`users/${uid}`).get()).data();
      const existing = (await ref.get()).data();
      if (!existing && !profile?.email) throw missing();
      if (fields.email) {
        const duplicates = await db.collection('users').where('email', '==', fields.email).get();
        if (duplicates.docs.some(d => d.id !== uid)) throw Object.assign(new Error('Adresse déjà utilisée.'), { code: 'auth/email-already-exists' });
      }
      await ref.set({ uid, email: existing?.email ?? profile!.email, ...fields }, { merge: true });
      return { uid };
    },
    async deleteUser(uid: string) { await collection.doc(uid).delete(); },
    async generatePasswordResetLink() { return 'https://example.invalid/simulated-invitation'; },
  } as unknown as Auth;
}

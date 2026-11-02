import { AsyncLocalStorage } from 'node:async_hooks';
import { Firestore, getFirestore as productionFirestore } from 'firebase-admin/firestore';

type ReviewContext = { uid: string; db: Firestore };
const context = new AsyncLocalStorage<ReviewContext>();
const owners = new WeakMap<object, string>();
export const getProductionFirestore = productionFirestore;
export const getReviewSpaceUid = () => context.getStore()?.uid;
export const reviewDatabaseOwner = (db: Firestore) => owners.get(db);
export const getFirestore = (): Firestore => context.getStore()?.db ?? productionFirestore();

/** References returned by this facade always belong to the selected space.
 * Transactions/batches operate on those references using the real SDK. */
export function reviewDatabase(uid: string, db = productionFirestore()): Firestore {
  if (!uid || uid.includes('/') || uid === '.' || uid === '..') throw new Error('Espace invalide.');
  const prefix = `review_spaces/${uid}/`;
  const safePath = (path: string) => {
    if (typeof path !== 'string' || path.split('/').some(p => !p || p === '.' || p === '..') || path.startsWith('review_spaces/')) {
      throw new Error('Chemin invalide.');
    }
    return prefix + path;
  };
  const scoped = new Proxy(db, {
    get(target, property) {
      if (property === 'doc') return (path: string) => target.doc(safePath(path));
      if (property === 'collection') return (path: string) => target.collection(safePath(path));
      if (property === 'collectionGroup' || property === 'listCollections') {
        return () => { throw new Error('Requête globale interdite dans un espace de validation.'); };
      }
      const value = Reflect.get(target, property, target);
      return typeof value === 'function' ? value.bind(target) : value;
    },
  });
  owners.set(scoped, uid);
  return scoped;
}

export function inReviewSpace<T>(uid: string, work: () => T, db = productionFirestore()): T {
  return context.run({ uid, db: reviewDatabase(uid, db) }, work);
}

import { getFirestore } from "firebase-admin/firestore";

// ':' cannot occur in a Firestore auto-ID. Test matches live in an entirely
// separate collection, so old clients and broad production queries cannot leak them.
export const isTestMatchId = (id: string): boolean => id.startsWith("test:");
export function matchReference(id: string, db = getFirestore()) {
  return db.collection(isTestMatchId(id) ? "test_matches" : "matches").doc(id);
}

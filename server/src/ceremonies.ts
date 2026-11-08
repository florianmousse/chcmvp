import { reviewDatabaseOwner } from "./database";
import { getFirestore } from "./database";
import { Firestore, Timestamp } from "firebase-admin/firestore";

export class CeremonyError extends Error {
  constructor(message: string, public status = 400) { super(message); }
}
export interface Nominee { id: string; uid: string; name: string; label: string; videoId: string | null }
export interface Ceremony {
  title: string; category: string; topSize: number; allowSelfVote: boolean;
  nominees: Nominee[]; voterIds: string[]; status: string; voteCount: number; revision?: number;
}
export interface AwardResult extends Nominee { points: number; counts: number[]; rank: number }
const categories = ['ballon_or', 'golden_boy', 'puskas', 'assist', 'custom'];
function text(value: unknown, label: string, max = 120): string {
  if (typeof value !== 'string' || !value.trim() || value.trim().length > max) {
    throw new CeremonyError(`${label} requis (maximum ${max} caractères).`);
  }
  return value.trim();
}
function id(value: unknown): string {
  const result = text(value, 'Identifiant', 128);
  if (result.includes('/') || result === '.' || result === '..') throw new CeremonyError('Identifiant invalide.');
  return result;
}
export function youtubeId(value: unknown): string | null {
  if (value == null || value === '') return null;
  if (typeof value !== 'string') throw new CeremonyError('Lien YouTube invalide.');
  let result = value.trim();
  if (!/^[\w-]{11}$/.test(result)) {
    let url: URL;
    try { url = new URL(result); } catch { throw new CeremonyError('Lien YouTube invalide.'); }
    if (!['https:', 'http:'].includes(url.protocol)) throw new CeremonyError('Lien YouTube invalide.');
    if (url.hostname === 'youtu.be') result = url.pathname.slice(1);
    else if (['youtube.com', 'www.youtube.com', 'm.youtube.com', 'www.youtube-nocookie.com'].includes(url.hostname)) {
      result = url.pathname === '/watch' ? url.searchParams.get('v') ?? '' :
        /^\/(shorts|embed)\/([\w-]{11})\/?$/.exec(url.pathname)?.[2] ?? '';
    } else throw new CeremonyError('Utilise un lien youtube.com ou youtu.be.');
  }
  if (!/^[\w-]{11}$/.test(result)) throw new CeremonyError('Lien YouTube invalide.');
  return result;
}
export function validateCeremony(body: any): Omit<Ceremony, 'status' | 'voteCount'> {
  const title = text(body?.title, 'Titre');
  if (!categories.includes(body.category)) throw new CeremonyError('Catégorie invalide.');
  if (!Number.isInteger(body.topSize) || body.topSize < 1 || body.topSize > 10) throw new CeremonyError('Choisis un top de 1 à 10.');
  if (!Array.isArray(body.nominees) || body.nominees.length < body.topSize || body.nominees.length > 50) {
    throw new CeremonyError('Prévois assez de nominations pour le top (50 maximum).');
  }
  const nominees: Nominee[] = body.nominees.map((n: any, i: number) => ({
    id: `n${i + 1}`, uid: id(n.uid), name: '', label: ['ballon_or', 'golden_boy'].includes(body.category) ? '' : text(n.label, 'Nomination'), videoId: youtubeId(n.videoUrl),
  }));
  if (!Array.isArray(body.voterIds) || !body.voterIds.length || body.voterIds.length > 500) throw new CeremonyError('Choisis de 1 à 500 votants.');
  const voterIds = [...new Set<string>(body.voterIds.map(id))];
  const allowSelfVote = body.allowSelfVote === true;
  if (new Set(nominees.map(n => n.uid)).size < body.topSize ||
      voterIds.some(uid => new Set(nominees.filter(n => allowSelfVote || n.uid !== uid).map(n => n.uid)).size < body.topSize)) {
    throw new CeremonyError('Chaque votant doit disposer d\'assez de joueurs différents pour remplir le top.');
  }
  return { title, category: body.category, topSize: body.topSize, allowSelfVote, nominees, voterIds };
}
export function validateBallot(event: Ceremony, uid: string, choices: unknown): string[] {
  if (event.status !== 'open') throw new CeremonyError('Le vote n\'est pas ouvert.', 409);
  if (!event.voterIds.includes(uid)) throw new CeremonyError('Tu ne fais pas partie des votants de cette cérémonie.', 403);
  if (!Array.isArray(choices) || choices.length !== event.topSize || new Set(choices).size !== choices.length ||
      choices.some(choice => !event.nominees.some(n => n.id === choice && (event.allowSelfVote || n.uid !== uid)))) {
    throw new CeremonyError(`Classe ${event.topSize} nominations différentes et autorisées.`);
  }
  if (new Set(choices.map(choice => event.nominees.find(n => n.id === choice)!.uid)).size !== choices.length) {
    throw new CeremonyError('Un joueur ne peut figurer qu\'une seule fois dans ton classement, même avec plusieurs actions nominées.');
  }
  return choices;
}
export function tallyCeremony(event: Ceremony, ballots: { uid: string; choices: string[] }[]): AwardResult[] {
  const scores = new Map<string, AwardResult>();
  const seen = new Set<string>();
  for (const ballot of ballots) {
    if (seen.has(ballot.uid)) continue;
    validateBallot({ ...event, status: 'open' }, ballot.uid, ballot.choices);
    seen.add(ballot.uid);
    ballot.choices.forEach((choice, i) => {
      const nominee = event.nominees.find(n => n.id === choice)!;
      const score = scores.get(choice) ?? { ...nominee, points: 0, counts: Array(event.topSize).fill(0), rank: 0 };
      score.points += event.topSize - i;
      score.counts[i]++;
      scores.set(choice, score);
    });
  }
  const compare = (a: AwardResult, b: AwardResult) => {
    if (a.points !== b.points) return b.points - a.points;
    for (let i = 0; i < event.topSize; i++) if (a.counts[i] !== b.counts[i]) return b.counts[i] - a.counts[i];
    return 0;
  };
  const sorted = [...scores.values()].sort((a, b) => compare(a, b) || a.id.localeCompare(b.id));
  sorted.forEach((row, i) => { row.rank = i > 0 && compare(row, sorted[i - 1]) === 0 ? sorted[i - 1].rank : i + 1; });
  return sorted; // zero-point nominations are never ranked or awarded
}
async function member(db: Firestore, uid: string, admin = false) {
  const doc = await db.doc(`users/${id(uid)}`).get();
  if (doc.data()?.isActive !== true || (admin && doc.data()?.role !== 'admin')) throw new CeremonyError('Accès non autorisé.', 403);
}
async function prepareCeremony(body: unknown, db: Firestore) {
  const event = validateCeremony(body);
  const uids = [...new Set([...event.voterIds, ...event.nominees.map(n => n.uid)])];
  const docs = await db.getAll(...uids.map(uid => db.doc(`users/${uid}`)));
  const users = new Map(docs.map(doc => [doc.id, doc.data()]));
  if (uids.some(uid => users.get(uid)?.isActive !== true || users.get(uid)?.role === 'reviewer')) throw new CeremonyError('Un joueur sélectionné est absent ou inactif.');
  if (event.voterIds.some(uid => !users.get(uid)?.email)) throw new CeremonyError('Les votants doivent disposer d\'un compte avec e-mail.');
  for (const n of event.nominees) {
    const user = users.get(n.uid)!;
    n.name = `${user.firstName ?? ''} ${user.lastName ?? ''}`.trim();
    if (['ballon_or', 'golden_boy'].includes(event.category)) n.label = n.name;
  }
  return event;
}
export async function createCeremony(body: unknown, actor: string, db = getFirestore()) {
  await member(db, actor, true);
  const event = await prepareCeremony(body, db);
  const ref = await db.collection('ceremonies').add({ ...event, status: 'draft', voteCount: 0,
    revision: 0, createdBy: actor, createdAt: Timestamp.now() });
  return ref.id;
}
export async function updateCeremony(eventId: string, body: any, actor: string, db = getFirestore()) {
  await member(db, actor, true);
  if (body?.resetVotes !== true) throw new CeremonyError('Confirme la remise à zéro des votes avant de modifier la cérémonie.');
  const next = await prepareCeremony(body, db);
  const ref = db.doc(`ceremonies/${id(eventId)}`);
  await db.runTransaction(async tx => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new CeremonyError('Cérémonie introuvable.', 404);
    const event = snap.data() as Ceremony;
    if (event.status === 'deleting') throw new CeremonyError('Suppression en cours.', 409);
    if (body.expectedRevision !== (event.revision ?? 0)) throw new CeremonyError('Cette cérémonie a été modifiée. Recharge sa fiche.', 409);
    tx.update(ref, { ...next, status: 'draft', voteCount: 0, results: [],
      revision: (event.revision ?? 0) + 1, updatedAt: Timestamp.now(), updatedBy: actor,
      openedAt: null, closedAt: null, cancelledAt: null, reopenedAt: null });
  });
}
export async function ceremonyAction(eventId: string, actor: string, action: string, db = getFirestore()) {
  await member(db, actor, true);
  const ref = db.doc(`ceremonies/${id(eventId)}`);
  await db.runTransaction(async tx => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new CeremonyError('Cérémonie introuvable.', 404);
    const event = snap.data() as Ceremony;
    if (action === 'open') {
      if (event.status === 'open') return;
      if (event.status !== 'draft') throw new CeremonyError('Seul un brouillon peut être ouvert.', 409);
      tx.update(ref, { status: 'open', openedAt: Timestamp.now() });
    } else if (action === 'close') {
      if (event.status === 'closed') return;
      if (event.status !== 'open') throw new CeremonyError('Le vote doit être ouvert.', 409);
      const votes = await tx.get(ref.collection('votes'));
      const currentVotes = votes.docs.filter(d => (d.data().revision ?? 0) === (event.revision ?? 0));
      const results = tallyCeremony(event, currentVotes.map(d => ({ uid: d.id, choices: d.data().choices })));
      tx.update(ref, { status: 'closed', results, voteCount: currentVotes.length, closedAt: Timestamp.now() });
    } else if (action === 'reopen') {
      if (!['closed', 'cancelled'].includes(event.status)) throw new CeremonyError('Seule une cérémonie terminée ou annulée peut être rouverte.', 409);
      const votes = await tx.get(ref.collection('votes'));
      let count = 0;
      // Legacy ballots with two actions from one player must be cast again.
      for (const vote of votes.docs) {
        if ((vote.data().revision ?? 0) !== (event.revision ?? 0)) continue;
        try { validateBallot({ ...event, status: 'open' }, vote.id, vote.data().choices); count++; }
        catch { tx.update(vote.ref, { revision: -1 }); }
      }
      tx.update(ref, { status: 'open', results: [], voteCount: count, closedAt: null, cancelledAt: null, reopenedAt: Timestamp.now() });
    } else if (action === 'delete') {
      tx.update(ref, { status: 'deleting', results: [] });
    } else if (action === 'cancel') {
      if (!['draft', 'open'].includes(event.status)) throw new CeremonyError('Cette cérémonie est déjà terminée.', 409);
      tx.update(ref, { status: 'cancelled', cancelledAt: Timestamp.now() });
    } else throw new CeremonyError('Action inconnue.');
    if (!reviewDatabaseOwner(db) && ['open', 'reopen', 'close'].includes(action)) {
      const notification = db.collection('ceremony_notifications').doc();
      tx.set(notification, { ceremonyId: eventId, action, done: false, createdAt: Timestamp.now() });
      tx.update(ref, { notificationId: notification.id });
    }

  });
  if (action === 'delete') await db.recursiveDelete(ref);
}
export async function castCeremonyVote(eventId: string, uid: string, choices: unknown, db = getFirestore(), expectedRevision?: number) {
  const ref = db.doc(`ceremonies/${id(eventId)}`);
  await db.runTransaction(async tx => {
    const [user, snap, prior] = await tx.getAll(db.doc(`users/${id(uid)}`), ref, ref.collection('votes').doc(uid));
    if (user.data()?.isActive !== true || user.data()?.role === 'reviewer') throw new CeremonyError('Compte inactif.', 403);
    if (!snap.exists) throw new CeremonyError('Cérémonie introuvable.', 404);
    const event = snap.data() as Ceremony;
    if ((event.revision ?? 0) !== (expectedRevision ?? 0)) throw new CeremonyError('La cérémonie a été modifiée. Recharge la page avant de voter.', 409);
    const ordered = validateBallot(event, uid, choices);
    if (prior.exists && (prior.data()?.revision ?? 0) === (event.revision ?? 0)) {
      if (JSON.stringify(prior.data()?.choices) === JSON.stringify(ordered)) return;
      throw new CeremonyError('Ton vote est déjà enregistré.', 409);
    }
    tx.set(ref.collection('votes').doc(uid), { choices: ordered, revision: event.revision ?? 0, votedAt: Timestamp.now() });
    tx.update(ref, { voteCount: event.voteCount + 1 });
  });
}

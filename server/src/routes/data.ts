import { getFirestore } from "../database";
import { reviewDatabaseOwner } from "../database";
import { initializeVotingWindow } from "../votingLifecycle";
import { recomputeClosedMatch } from "../rebuildRankings";
import { Router } from 'express';
import { Timestamp } from "firebase-admin/firestore";
import { requireAuth, AuthedRequest } from '../middleware/auth';
import { auditChange, auditRequest } from '../audit';
import { canManageMatch } from '../reviewAccess';

const fail = (status: number, message: string): never => { throw Object.assign(new Error(message), { status }); };
const fieldsByKind: Record<string, string[]> = {
  matches: ['date','time','opponent','opponentId','isHome','team','status','matchType','presentPlayerIds','votingOpensAt','votingClosesAt','reminderSentAt','pointsScale','allowSelfVote','opponentLogoAsset','scoreHome','scoreAway'],
  playerStats: ['goals','assists','greenCards','yellowCards','redCards'],
  users: ['firstName','lastName','team','photoUrl','jerseyNumber'],
  teams: ['name'], opponents: ['name','logoAsset'],
};

export async function writeData(uid: string, input: any, db = getFirestore()) {
  const { path, operation, data = {} } = input ?? {};
  if (typeof path !== 'string' || !['create','update','merge','delete'].includes(operation) ||
      !data || typeof data !== 'object' || Array.isArray(data)) fail(400, 'Écriture invalide.');
  const p = path.split('/');
  const matchCollection = ['matches','test_matches'].includes(p[0]);
  const kind = p.length === 4 && matchCollection && p[2] === 'playerStats' ? 'playerStats'
    : p.length === 2 ? (matchCollection ? 'matches' : p[0]) : '';
  if (p.some((s: string) => !s || s === '.' || s === '..') || !Object.prototype.hasOwnProperty.call(fieldsByKind, kind) ||
      Object.keys(data).some(k => !fieldsByKind[kind].includes(k))) fail(400, 'Champs ou chemin non autorisés.');
  if (matchCollection && ((p[0] === 'test_matches') !== p[1].startsWith('test:'))) fail(400, 'Collection de match invalide.');
  if (operation === 'delete' && !['teams','opponents'].includes(kind)) fail(400, 'Utilisez la suppression dédiée.');
  if (kind === 'users' && operation !== 'update') fail(400, 'Utilisez la gestion des comptes.');
  const ref = db.doc(path);
  await db.runTransaction(async tx => {
    const actor = { ...(await tx.get(db.doc(`users/${uid}`))).data(), uid } as any;
    const snapshot = await tx.get(ref);
    const before = snapshot.data();
    const parent = kind === 'playerStats' ? (await tx.get(db.doc(p.slice(0,2).join('/')))).data() : before;
    if (actor.isActive !== true) fail(403, 'Compte inactif.');
    const creatingReview = kind === 'matches' && operation === 'create' && p[0] === 'test_matches' && actor.role === 'reviewer';
    if (actor.role !== 'admin' && !creatingReview &&
        !(matchCollection && canManageMatch(actor, p[1], parent)) &&
        !(kind === 'users' && p[1] === uid)) fail(403, 'Action non autorisée.');
    if (operation === 'create' && snapshot.exists) fail(409, 'Cet objet existe déjà.');
    if (operation === 'update' && !snapshot.exists) fail(404, 'Objet introuvable.');
    if (kind === 'playerStats' && !parent) fail(404, 'Match introuvable.');
    const converted = { ...data };
    if (kind === 'matches') {
      for (const key of ['date','votingOpensAt','votingClosesAt','reminderSentAt']) {
        if (converted[key] != null) {
          const date = new Date(converted[key]);
          if (typeof converted[key] !== 'string' || !Number.isFinite(date.getTime())) fail(400, 'Date invalide.');
          converted[key] = Timestamp.fromDate(date);
        }
      }
      const next = { ...before, ...converted };
      if (!['championship','friendly','playoff'].includes(next.matchType ?? 'championship') ||
          !['upcoming','voting_open','voting_closed'].includes(next.status) ||
          !(next.date instanceof Timestamp) || typeof next.time !== 'string' || !/^([01]\d|2[0-3]):[0-5]\d$/.test(next.time) ||
          typeof next.team !== 'string' || !next.team.trim() || typeof next.opponent !== 'string' || !next.opponent.trim() ||
          typeof next.isHome !== 'boolean' || typeof next.allowSelfVote !== 'boolean' ||
          !Array.isArray(next.presentPlayerIds) || next.presentPlayerIds.some((v: any) => typeof v !== 'string' || !v || v.includes('/')) ||
          !next.pointsScale || ['first','second','third'].some(k => !Number.isInteger(next.pointsScale[k]) || next.pointsScale[k] < 0)) fail(400, 'Match invalide.');
      if (operation === 'merge') fail(400, 'Mise à jour explicite requise.');
      if (operation === 'create' && next.status !== 'upcoming') fail(400, 'Le match doit être à venir.');
      if ((before?.status === 'voting_closed' && next.status !== 'voting_closed') ||
          (before?.manualCloseRequired && (next.status === 'upcoming' || next.votingClosesAt != null))) fail(409, 'Utilisez la réouverture dédiée.');
      for (const key of ['scoreHome','scoreAway']) if (next[key] != null && (!Number.isInteger(next[key]) || next[key] < 0)) fail(400, 'Score invalide.');
      if (p[0] === 'matches' && next.presentPlayerIds.length) {
        const players = await tx.getAll(...next.presentPlayerIds.map((id: string) => db.doc(`users/${id}`)));
        if (players.some(player => (player.data() as any)?.role === 'reviewer')) fail(400, 'Un compte de validation ne peut pas participer à un match réel.');
      }
      if (creatingReview) Object.assign(converted, { reviewCreatedBy: uid, reviewSource: 'Équipe de validation', createdAt: Timestamp.now() });
    }
    if (kind === 'playerStats' && Object.values(data).some(v => !Number.isInteger(v) || (v as number) < 0)) fail(400, 'Statistiques invalides.');
    if (['teams','opponents'].includes(kind) && operation !== 'delete' && (typeof data.name !== 'string' || !data.name.trim())) fail(400, 'Nom requis.');
    if (kind === 'users') {
      for (const key of ['firstName','lastName','team']) if (key in data && (typeof data[key] !== 'string' || !data[key].trim())) fail(400, 'Profil invalide.');
      if (data.jerseyNumber != null && (!Number.isInteger(data.jerseyNumber) || data.jerseyNumber < 0)) fail(400, 'Numéro invalide.');
    }
    // Keep only editable fields in snapshots; profile tokens and emails are never copied.
    const clean = (value: any) => value ? Object.fromEntries(Object.entries(value).filter(([k]) => fieldsByKind[kind].includes(k))) : null;
    auditChange(tx, db, uid, actor, operation, path, clean(before), operation === 'delete' ? null : clean({ ...before, ...converted }));
    if (operation === 'delete') tx.delete(ref);
    else if (operation === 'create') tx.create(ref, converted);
    else if (operation === 'update') tx.update(ref, converted);
    else tx.set(ref, converted, { merge: true });
  });
  if (reviewDatabaseOwner(db) && kind === 'matches') {
    const match = (await ref.get()).data();
    if (match?.status === 'voting_open') await initializeVotingWindow(p[1], 48, db);
    if (match?.status === 'voting_closed') await recomputeClosedMatch(p[1], db);
  }
  return { success: true };
}

export const dataRouter = Router();
dataRouter.use(requireAuth, auditRequest);
dataRouter.post('/stats', async (req: AuthedRequest, res) => {
  try {
    const { matchId, stats } = req.body ?? {};
    if (typeof matchId !== 'string' || !matchId || matchId.includes('/') || !Array.isArray(stats) || stats.length > 150 ||
      stats.some(s => !s || typeof s.playerId !== 'string' || !s.playerId || s.playerId.includes('/') ||
        Object.keys(s).some(k => k !== 'playerId' && !fieldsByKind.playerStats.includes(k)) ||
        fieldsByKind.playerStats.some(k => !Number.isInteger(s[k]) || s[k] < 0)) ||
      new Set(stats.map(s => s.playerId)).size !== stats.length) fail(400, 'Statistiques invalides.');
    const db = getFirestore();
    const parent = db.doc(`${matchId.startsWith('test:') ? 'test_matches' : 'matches'}/${matchId}`);
    await db.runTransaction(async tx => {
      const actor = { ...(await tx.get(db.doc(`users/${req.uid}`))).data(), uid: req.uid };
      const match = (await tx.get(parent)).data();
      if (!canManageMatch(actor, matchId, match)) fail(403, 'Accès refusé.');
      if (!match) fail(404, 'Match introuvable.');
      const refs = stats.map((s: any) => parent.collection('playerStats').doc(s.playerId));
      const previous = refs.length ? await tx.getAll(...refs) : [];
      stats.forEach((s: any, i: number) => {
        const { playerId, ...data } = s;
        auditChange(tx, db, req.uid!, actor, 'update', refs[i].path, previous[i].data() ?? null, data);
        tx.set(refs[i], data);
      });
    });
    res.json({ success: true });
  } catch (error: any) { res.status(error.status ?? 500).json({ error: error.message }); }
});
dataRouter.post('/', async (req: AuthedRequest, res) => {
  try { res.json(await writeData(req.uid!, req.body)); }
  catch (error: any) { res.status(error.status ?? 500).json({ error: error.message }); }
});

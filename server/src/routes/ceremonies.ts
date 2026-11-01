import { Router } from 'express';
import { requireAuth, AuthedRequest } from '../middleware/auth';
import { createCeremony, updateCeremony, ceremonyAction, castCeremonyVote } from '../ceremonies';
export const ceremoniesRouter = Router();
ceremoniesRouter.use(requireAuth);
ceremoniesRouter.post('/', async (req: AuthedRequest, res) => {
  try { res.json({ id: await createCeremony(req.body, req.uid!) }); }
  catch (e: any) { res.status(e.status ?? 500).json({ error: e.message }); }
});
ceremoniesRouter.post('/:id/vote', async (req: AuthedRequest, res) => {
  try { await castCeremonyVote(req.params.id, req.uid!, req.body?.choices, undefined, req.body?.revision); res.json({ success: true }); }
  catch (e: any) { res.status(e.status ?? 500).json({ error: e.message }); }
});
ceremoniesRouter.post('/:id/update', async (req: AuthedRequest, res) => {
  try { await updateCeremony(req.params.id, req.body, req.uid!); res.json({ success: true }); }
  catch (e: any) { res.status(e.status ?? 500).json({ error: e.message }); }
});
ceremoniesRouter.post('/:id/:action', async (req: AuthedRequest, res) => {
  try { await ceremonyAction(req.params.id, req.uid!, req.params.action); res.json({ success: true }); }
  catch (e: any) { res.status(e.status ?? 500).json({ error: e.message }); }
});

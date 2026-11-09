import { createHash } from 'node:crypto';
import { RequestHandler } from 'express';

/** Bounded single-process limiter. The global ceiling also bounds SMTP work.
 * Use a shared limiter before running multiple API processes. */
export function passwordResetHandler(
  send: (email: string) => Promise<void>,
  now: () => number = Date.now,
): RequestHandler {
  const buckets = new Map<string, { count: number; expires: number }>();
  const windowMs = 15 * 60 * 1000;
  return async (req, res) => {
    const email = typeof req.body?.email === 'string' ? req.body.email.trim().toLowerCase() : '';
    if (email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      res.status(400).json({ error: 'Adresse e-mail invalide.' }); return;
    }
    const time = now();
    for (const [key, bucket] of buckets) if (bucket.expires <= time) buckets.delete(key);
    const digest = createHash('sha256').update(email).digest('hex');
    // req.ip only trusts proxies explicitly configured by the application.
    const limits: Array<[string, number]> = [['global', 100], [`ip:${req.ip}`, 10], [`email:${digest}`, 3]];
    if (limits.some(([key, limit]) => (buckets.get(key)?.count ?? 0) >= limit)) {
      res.setHeader('Retry-After', '900');
      res.status(429).json({ error: 'Trop de demandes. Réessayez dans 15 minutes.' }); return;
    }
    for (const [key] of limits) {
      const bucket = buckets.get(key) ?? { count: 0, expires: time + windowMs };
      bucket.count++; buckets.set(key, bucket);
    }
    try { await send(email); }
    catch {
      // No address, reset link or upstream error in logs; same response for unknown accounts.
      console.warn('Réinitialisation : demande non remise.');
    }
    res.json({ success: true });
  };
}

import type { RequestHandler } from "express";

/** Liste explicite : les origines de preview ne sont jamais autorisées en bloc. */
export function createCorsMiddleware(origins: string[]): RequestHandler {
  const allowed = new Set(origins.map((origin) => origin.trim()).filter(Boolean));
  return (req, res, next) => {
    const origin = req.headers.origin;
    res.vary("Origin");
    if (!origin) return next(); // Applications natives / appels serveur.
    if (!allowed.has(origin)) {
      res.status(403).json({ error: "Origine web non autorisée." });
      return;
    }
    res.setHeader("Access-Control-Allow-Origin", origin);
    res.setHeader("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS");
    res.setHeader("Access-Control-Allow-Headers", "Authorization, Content-Type");
    res.setHeader("Access-Control-Max-Age", "600");
    if (req.method === "OPTIONS") {
      res.sendStatus(204);
      return;
    }
    next();
  };
}

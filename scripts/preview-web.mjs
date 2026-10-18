import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { resolve, extname, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

// Serve uniquement build/web, jamais le dépôt (qui contient des fichiers privés).
const root = fileURLToPath(new URL('../build/web/', import.meta.url));
const types = { '.html':'text/html; charset=utf-8', '.js':'text/javascript', '.json':'application/json', '.css':'text/css', '.png':'image/png', '.wasm':'application/wasm', '.woff2':'font/woff2', '.otf':'font/otf', '.svg':'image/svg+xml' };
createServer(async (req, res) => {
  try {
    const pathname = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
    const file = resolve(root, `.${pathname === '/' ? '/index.html' : pathname}`);
    if (!file.startsWith(resolve(root) + sep) || !(await stat(file)).isFile()) throw new Error('Not found');
    res.writeHead(200, { 'Content-Type':types[extname(file)] ?? 'application/octet-stream', 'Cache-Control':'no-store' });
    res.end(await readFile(file));
  } catch {
    res.writeHead(404, { 'Content-Type':'text/plain; charset=utf-8' });
    res.end('Page introuvable');
  }
}).listen(8085, '127.0.0.1', () => console.log('CHC MVP : http://127.0.0.1:8085'));

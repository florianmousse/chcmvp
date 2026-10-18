const { test } = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const { createCorsMiddleware } = require('../dist/middleware/cors');

test('CORS : preflight autorisé, origine étrangère refusée, client natif accepté', async () => {
  const app = express();
  app.use(createCorsMiddleware(['https://club.example']));
  app.post('/members/invite', (_req, res) => res.json({ ok: true }));
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  const url = `http://127.0.0.1:${server.address().port}/members/invite`;
  try {
    const preflight = await fetch(url, { method:'OPTIONS', headers:{ Origin:'https://club.example', 'Access-Control-Request-Method':'POST', 'Access-Control-Request-Headers':'authorization,content-type' } });
    assert.equal(preflight.status, 204);
    assert.equal(preflight.headers.get('access-control-allow-origin'), 'https://club.example');
    assert.match(preflight.headers.get('access-control-allow-headers'), /Authorization/);
    const denied = await fetch(url, { method:'POST', headers:{ Origin:'https://evil.example' } });
    assert.equal(denied.status, 403);
    assert.equal(denied.headers.get('access-control-allow-origin'), null);
    const native = await fetch(url, { method:'POST' });
    assert.equal(native.status, 200);
    const web = await fetch(url, { method:'POST', headers:{ Origin:'https://club.example' } });
    assert.equal(web.status, 200);
  } finally {
    await new Promise(resolve => server.close(resolve));
  }
});

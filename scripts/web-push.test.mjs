import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';

const source = readFileSync(new URL('../web/firebase-messaging-sw.js', import.meta.url), 'utf8');
function worker(windows = []) {
  let handler;
  const opened = [];
  const context = {
    URL,
    self: {
      location: { origin: 'https://club.example' },
      addEventListener: (name, callback) => { assert.equal(name, 'notificationclick'); handler = callback; },
      clients: {
        matchAll: async () => windows,
        openWindow: async url => { opened.push(url); },
      },
    },
    importScripts: () => assert.ok(handler, 'Click handler precedes Firebase imports'),
    firebase: { initializeApp() {}, messaging() {} },
  };
  vm.runInNewContext(source, context);
  return {
    opened,
    async click(data) {
      let work, closed = false, stopped = false;
      handler({
        notification: { data, close: () => { closed = true; } },
        stopImmediatePropagation: () => { stopped = true; },
        waitUntil: promise => { work = promise; },
      });
      await work;
      return { closed, stopped };
    },
  };
}

test('Cold start opens the match on the same origin, encoding untrusted IDs', async () => {
  const w = worker();
  assert.deepEqual(await w.click({ FCM_MSG: { data: { matchId: 'test:a&redirect=https://evil.example' } } }), { closed: true, stopped: true });
  const url = new URL(w.opened[0]);
  assert.equal(url.origin, 'https://club.example');
  assert.equal(url.searchParams.get('notification'), 'test:a&redirect=https://evil.example');
  assert.equal(url.searchParams.size, 1);
});
test('Existing app is navigated and focused for a ceremony', async () => {
  let navigated, focused = false;
  const w = worker([{ url: 'https://club.example/', navigate: async url => {
    navigated = url;
    return { focus: async () => { focused = true; } };
  } }]);
  await w.click({ FCM_MSG: { data: { ceremonyId: 'awards', matchId: 'ignored' } } });
  assert.equal(new URL(navigated).searchParams.get('notification'), 'ceremony:awards');
  assert.equal(focused, true);
  assert.equal(w.opened.length, 0);
});
test('Badge notifications without a route open the home page', async () => {
  const w = worker();
  await w.click({ FCM_MSG: {} });
  assert.deepEqual(w.opened, ['https://club.example/']);
});
test('Unrelated notifications are left to their own handler', async () => {
  const w = worker();
  assert.deepEqual(await w.click({}), { closed: false, stopped: false });
  assert.equal(w.opened.length, 0);
});
test('A closed window during navigation falls back to opening the app', async () => {
  const w = worker([{ url: 'https://club.example/', navigate: async () => null }]);
  await w.click({ FCM_MSG: { data: { matchId: 'match' } } });
  assert.equal(w.opened.length, 1);
});

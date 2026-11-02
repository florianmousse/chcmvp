/* Handle clicks before Firebase installs its default click listener. */
self.addEventListener('notificationclick', (event) => {
  const payload = event.notification.data?.FCM_MSG;
  if (!payload) return;
  event.stopImmediatePropagation();
  event.notification.close();
  const data = payload.data || {};
  const target = data.ceremonyId ? `ceremony:${data.ceremonyId}` : data.matchId;
  const url = new URL('/', self.location.origin);
  if (typeof target === 'string') url.searchParams.set('notification', target);
  event.waitUntil((async () => {
    const windows = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
    const existing = windows.find((client) => new URL(client.url).origin === url.origin);
    if (existing) {
      // Navigation preserves the target even when Flutter has not yet initialized.
      const navigated = await existing.navigate(url.href);
      if (navigated) return navigated.focus();
    }
    return self.clients.openWindow(url.href);
  })());
});

// Match the Firebase SDK version used by firebase_core_web 2.17.5.
importScripts('https://www.gstatic.com/firebasejs/10.11.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.11.1/firebase-messaging-compat.js');
firebase.initializeApp({
  apiKey: 'AIzaSyB3-bohM5NMom10OMbOBUVPjf1LHZfmff8',
  appId: '1:64422446249:web:1d86f46b48c6dc6a1795b8',
  messagingSenderId: '64422446249',
  projectId: 'chc-mvp',
  authDomain: 'chc-mvp.firebaseapp.com',
  storageBucket: 'chc-mvp.firebasestorage.app',
});
// Existing server messages include `notification`; Firebase displays them once.
firebase.messaging();

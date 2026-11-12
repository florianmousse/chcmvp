import type { MulticastMessage } from 'firebase-admin/messaging';

/** Relative web URLs resolve against the receiving service worker's origin,
 * keeping previews and production independent. */
export const notificationAppearance: Pick<MulticastMessage, 'android' | 'webpush'> = {
  android: { notification: { icon: 'ic_stat_chc', color: '#1B5E20' } },
  webpush: { notification: { icon: '/logo.png', badge: '/notification-badge.png' } },
};

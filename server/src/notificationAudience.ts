/** Old malformed data must not interrupt delivery to other members. */
export function validNotificationTokens(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.filter((token): token is string => typeof token === 'string' &&
    token.length > 0 && token.length <= 4096 && !/\s/.test(token)).slice(0, 10);
}

/** Shared token filter, testable without Firebase or sending a notification. */
export function notificationTokens(
  users: Array<{ uid: string; role?: string; isActive?: boolean; fcmTokens?: unknown }>,
  options: { adminsOnly?: boolean; onlyUids?: string[]; excludeUids?: string[] },
): string[] {
  const tokens = new Set<string>();
  for (const user of users) {
    if (user.isActive !== true || user.role === "reviewer") continue;
    if (options.adminsOnly) {
      // A simulated voter's team/presence must never redirect test notifications.
      if (user.role !== "admin") continue;
    } else {
      if (options.onlyUids && !options.onlyUids.includes(user.uid)) continue;
      if (options.excludeUids?.includes(user.uid)) continue;
    }
    for (const token of validNotificationTokens(user.fcmTokens)) tokens.add(token);
  }
  return [...tokens];
}

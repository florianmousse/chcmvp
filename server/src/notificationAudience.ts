/** Shared token filter, testable without Firebase or sending a notification. */
export function notificationTokens(
  users: Array<{ uid: string; role?: string; isActive?: boolean; fcmTokens?: string[] }>,
  options: { adminsOnly?: boolean; onlyUids?: string[]; excludeUids?: string[] },
): string[] {
  const tokens = new Set<string>();
  for (const user of users) {
    if (user.isActive !== true) continue;
    if (options.adminsOnly) {
      // A simulated voter's team/presence must never redirect test notifications.
      if (user.role !== "admin") continue;
    } else {
      if (options.onlyUids && !options.onlyUids.includes(user.uid)) continue;
      if (options.excludeUids?.includes(user.uid)) continue;
    }
    for (const token of user.fcmTokens ?? []) tokens.add(token);
  }
  return [...tokens];
}

type Level = 'info' | 'warn' | 'error';
type Context = { matchId?: string; collection?: string; count?: number; code?: string };

// Only explicitly permitted operational fields enter server logs. Never pass an
// upstream Error, request body, recipient, token or ballot to this function.
export function logEvent(level: Level, event: string, message: string, context: Context = {}): void {
  const labels = { info: 'INFO', warn: 'ATTENTION', error: 'ERREUR' };
  const clean = (value: string) => value.replace(/[\r\n\x00-\x1f]/g, ' ').slice(0, 160);
  const details = Object.entries(context).map(([key, value]) => `${key}=${clean(String(value))}`).join(' | ');
  console[level === 'info' ? 'log' : level](
    `${new Date().toISOString()} | ${labels[level]} | ${clean(event)} | ${clean(message)}${details ? ` | ${details}` : ''}`,
  );
}

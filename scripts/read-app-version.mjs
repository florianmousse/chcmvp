import { readFileSync } from 'node:fs';

const source = readFileSync(new URL('../pubspec.yaml', import.meta.url), 'utf8');
const match = /^version:\s*(\d+\.\d+\.\d+\+\d+)\s*$/m.exec(source);
if (!match) throw new Error('Version X.Y.Z+N manquante dans pubspec.yaml');
process.stdout.write(match[1]);

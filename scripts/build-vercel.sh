#!/usr/bin/env bash
set -euo pipefail

# SDK verrouillé sur la version utilisée pour vérifier ce projet.
FLUTTER_VERSION="${FLUTTER_VERSION:-3.44.9}"
FLUTTER_DIR="${TMPDIR:-/tmp}/chc-flutter-${FLUTTER_VERSION}"
if [[ ! -x "$FLUTTER_DIR/bin/flutter" ]]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"
export CI=true
flutter config --no-analytics --enable-web
flutter pub get --enforce-lockfile
node scripts/generate-legal.mjs
flutter build web --release --no-web-resources-cdn \
  --dart-define="SERVER_BASE_URL=${SERVER_BASE_URL:-https://chc-mvp.duckdns.org}"

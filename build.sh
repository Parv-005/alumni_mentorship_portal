#!/bin/bash
set -e

# ── 1. Install Flutter SDK (Vercel runners don't have it) ──────────────
echo "Cloning Flutter SDK..."
export FLUTTER_HOME="$HOME/flutter"
if [ ! -d "$FLUTTER_HOME" ]; then
  git clone https://github.com/flutter/flutter.git "$FLUTTER_HOME" --depth 1 --branch stable
fi
export PATH="$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH"

echo "Flutter precache..."
flutter precache --web

# ── 2. Generate .env from Vercel environment variables ─────────────────
# flutter_dotenv bundles .env as a web asset at build time, so the file
# must exist when `flutter build web` runs.
echo "Generating .env from Vercel environment variables..."
cat > .env <<EOF
SUPABASE_URL=${SUPABASE_URL}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
EOF

# ── 3. Install dependencies and build ──────────────────────────────────
echo "Running flutter pub get..."
flutter pub get

echo "Building Flutter web..."
flutter build web --release --base-href "/"

echo "Build complete."

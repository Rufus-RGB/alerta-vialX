#!/usr/bin/env bash
# Compila la web. Las claves de Supabase vienen de las variables de entorno de Vercel.
set -e
"$HOME/flutter/bin/flutter" build web --release \
  --dart-define=SUPABASE_URL="${SUPABASE_URL:-}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"

#!/usr/bin/env bash
# Instala Flutter (misma versión del proyecto) en el build de Vercel.
set -e
if [ ! -d "$HOME/flutter" ]; then
  git clone --depth 1 --branch 3.47.7 https://github.com/flutter/flutter.git "$HOME/flutter"
fi
"$HOME/flutter/bin/flutter" config --enable-web --no-analytics
"$HOME/flutter/bin/flutter" pub get

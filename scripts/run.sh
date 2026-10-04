#!/usr/bin/env bash
# Ejecuta la app inyectando las variables de ../.env como --dart-define.
# Uso: ./scripts/run.sh [args extra de flutter run, ej. -d emulator-5554]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ ! -f "$ROOT/.env" ]]; then
  echo "Falta $ROOT/.env — copia .env.example y complétalo." >&2
  exit 1
fi
cd "$ROOT/app"
flutter run --dart-define-from-file="$ROOT/.env" "$@"

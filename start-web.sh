#!/bin/bash

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOST="127.0.0.1"
PORT="5173"
URL="http://${HOST}:${PORT}/"

cd "$PROJECT_DIR"

if [ ! -d "node_modules" ]; then
  echo "Dipendenze non trovate: eseguo npm install..."
  npm install
fi

echo "Avvio Screenshot2PDF..."
echo "URL: ${URL}"
echo "Per fermare l'app premi Ctrl+C."

npm run dev -- --host "$HOST" --port "$PORT" &
SERVER_PID=$!

cleanup() {
  kill "$SERVER_PID" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

for _ in $(seq 1 30); do
  if curl --silent --fail "$URL" >/dev/null 2>&1; then
    open "$URL"
    break
  fi
  sleep 1
done

wait "$SERVER_PID"

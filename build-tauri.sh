#!/bin/bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

if ! command -v cargo >/dev/null 2>&1; then
  echo "Errore: Rust/Cargo non è installato o non è disponibile nel PATH."
  exit 1
fi

if ! command -v cargo-tauri >/dev/null 2>&1; then
  echo "Errore: cargo-tauri non è installato o non è disponibile nel PATH."
  echo "Installalo con: cargo install tauri-cli"
  exit 1
fi

if [ ! -d "node_modules" ]; then
  echo "Dipendenze JavaScript non trovate: eseguo npm install..."
  npm install
fi

echo "Controllo il frontend..."
npm run check

echo "Creo i bundle Tauri macOS..."
cargo tauri build

APP_PATH="$PROJECT_DIR/src-tauri/target/release/bundle/macos/Screenshot2PDF.app"
DMG_PATH="$PROJECT_DIR/src-tauri/target/release/bundle/dmg/Screenshot2PDF_0.1.1_aarch64.dmg"

echo
echo "Build completata."
echo "App: $APP_PATH"
if [ -f "$DMG_PATH" ]; then
  echo "DMG: $DMG_PATH"
fi

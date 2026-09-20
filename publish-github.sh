#!/bin/bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

RELEASE=false
COMMIT_MESSAGE="Update Screenshot2PDF"

for argument in "$@"; do
  case "$argument" in
    --release)
      RELEASE=true
      ;;
    --help|-h)
      echo "Uso: ./publish-github.sh [messaggio-commit] [--release]"
      echo
      echo "Senza --release: crea il commit (se necessario) e fa push su GitHub."
      echo "Con --release: crea anche il bundle Tauri, il tag e la release GitHub."
      exit 0
      ;;
    *)
      COMMIT_MESSAGE="$argument"
      ;;
  esac
done

if ! command -v gh >/dev/null 2>&1; then
  echo "Errore: GitHub CLI (gh) non è installato."
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "Errore: GitHub CLI non autenticato. Esegui: gh auth login"
  exit 1
fi

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "Errore: questa cartella non è un repository Git."
  exit 1
fi

VERSION="$(node -p "require('./package.json').version")"
TAG="v${VERSION}"
DMG_PATH="$PROJECT_DIR/src-tauri/target/release/bundle/dmg/Screenshot2PDF_${VERSION}_aarch64.dmg"

if [ -n "$(git status --short)" ]; then
  git add -A
  git commit -m "$COMMIT_MESSAGE" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
else
  echo "Nessuna modifica locale da committare."
fi

git push origin main

if [ "$RELEASE" = false ]; then
  echo "Codice pubblicato su GitHub."
  exit 0
fi

if ! git rev-parse "$TAG" >/dev/null 2>&1; then
  git tag -a "$TAG" -m "Screenshot2PDF $TAG"
  git push origin "$TAG"
else
  echo "Il tag $TAG esiste già: non lo ricreo."
fi

if [ ! -f "$DMG_PATH" ]; then
  echo "DMG non trovato: eseguo la build Tauri..."
  ./build-tauri.sh
fi

if gh release view "$TAG" >/dev/null 2>&1; then
  echo "La release $TAG esiste già: non la ricreo."
else
  gh release create "$TAG" "$DMG_PATH" \
    --title "Screenshot2PDF $TAG" \
    --notes-file CHANGELOG.md
  echo "Release $TAG pubblicata."
fi

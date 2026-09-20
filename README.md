# Screenshot2PDF

Applicazione Svelte + TypeScript per trasformare screenshot musicali in un PDF A4 verticale. Funziona nel browser locale e come app desktop macOS tramite Tauri.

## Sviluppo web

```bash
./start-web.sh
```

Lo script installa le dipendenze se necessario, avvia Vite e apre il browser. In alternativa:

```bash
npm install
npm run dev
```

## Sviluppo desktop

```bash
npm run tauri:dev
```

## Build locale macOS

```bash
./build-tauri.sh
```

I bundle vengono creati in:

```text
src-tauri/target/release/bundle/macos/
src-tauri/target/release/bundle/dmg/
```

## Funzionalità

- Importazione di cartelle e immagini PNG, JPG/JPEG e WEBP;
- drag & drop web e nativo Tauri;
- ricerca ricorsiva nelle sottocartelle;
- riordinamento manuale delle immagini;
- titolo e autore;
- anteprima A4 in tempo reale;
- margini e spazio configurabili;
- esportazione PDF con immagini JPEG ottimizzate;
- dialog nativo “Salva con nome” su macOS;
- numero pagina e nome file `Titolo - Autore.pdf`.

## Versione

Per aggiornare in modo coerente tutti i file di versione:

```bash
npm run version:set -- 0.1.2
```

Lo script aggiorna `package.json`, `package-lock.json`, la configurazione Tauri, Cargo e la versione mostrata nell’interfaccia. Dopo l’aggiornamento, aggiungi una voce in [CHANGELOG.md](./CHANGELOG.md).

## Pubblicazione su GitHub

Per pubblicare solo le modifiche sul branch `main`:

```bash
./publish-github.sh "Descrizione della modifica"
```

Per creare anche il tag e avviare la release multipiattaforma:

```bash
./publish-github.sh "Release v0.1.2" --release
```

Il tag attiva [release.yml](./.github/workflows/release.yml), che compila e pubblica:

- macOS Apple Silicon;
- macOS Intel;
- Windows;
- Linux.

La release GitHub contiene gli installer generati dai quattro runner. Non sono necessari secret aggiuntivi: la workflow usa `GITHUB_TOKEN`.

È possibile avviare la workflow manualmente da GitHub in `Actions` → `Build and release` → `Run workflow`, inserendo il tag della release.

## CI

La workflow [ci.yml](./.github/workflows/ci.yml) esegue su push e pull request:

```bash
npm ci
npm run check
npm run build
cargo check --manifest-path src-tauri/Cargo.toml
```

## Release

La versione attuale è indicata in `package.json` e sincronizzata con Tauri e Cargo. Le modifiche pubblicate sono documentate in [CHANGELOG.md](./CHANGELOG.md).

La firma e la notarizzazione Apple non sono ancora configurate.

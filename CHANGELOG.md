# Changelog

Tutte le modifiche rilevanti a Screenshot2PDF sono documentate in questo file.

## [0.1.1] - 2026-09-20

### Corretto

- Esportazione PDF nella versione macOS Tauri.
- Salvataggio tramite finestra nativa “Salva con nome”.
- Scrittura del PDF direttamente nel percorso scelto dall’utente.

### Aggiunto

- Plugin Tauri Dialog per la selezione del percorso di esportazione.
- Permessi Tauri per la scrittura dei file PDF.

## [0.1.0] - 2026-09-20

### Aggiunto

- Importazione di immagini PNG, JPG/JPEG e WEBP.
- Importazione tramite selezione di una cartella.
- Drag & drop di immagini e cartelle nella versione web.
- Drag & drop nativo di cartelle nella versione macOS Tauri.
- Ricerca ricorsiva delle immagini nelle sottocartelle.
- Riordinamento delle immagini tramite drag & drop.
- Rimozione di singole immagini o di tutta la lista.
- Inserimento di titolo e autore del progetto.
- Prima pagina A4 con titolo e autore.
- Impaginazione automatica in formato A4 verticale.
- Anteprima delle pagine in tempo reale.
- Configurazione dei margini e dello spazio tra immagini.
- Numerazione delle pagine nel PDF.
- Esportazione PDF con immagini JPEG ottimizzate per ridurre il peso.
- Nome PDF nel formato `Titolo - Autore.pdf`.
- Interfaccia web locale basata su Svelte e TypeScript.
- App desktop macOS basata su Tauri.
- Finestra About con nome, versione e autore dell’app.
- Script `start-web.sh` per avviare la versione web.
- Script `build-tauri.sh` per verificare e creare i bundle macOS.

### Build

- Versione applicazione: `0.1.0`.
- Bundle macOS Apple Silicon (`aarch64`).
- Formati distribuiti: `.app` e `.dmg`.

### Note

- Il salvataggio e la riapertura dei progetti non sono ancora disponibili.
- La firma e la notarizzazione Apple non sono ancora configurate.

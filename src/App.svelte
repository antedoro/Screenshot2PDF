<script lang="ts">
  import { onMount } from 'svelte'
  import { jsPDF } from 'jspdf'

  type ImageItem = {
    id: string
    file: File
    url: string
    name: string
  }

  const A4_WIDTH = 210
  const A4_HEIGHT = 297

  let images: ImageItem[] = []
  let title = ''
  let author = ''
  let margin = 10
  let spacing = 4
  let draggedId: string | null = null
  let isExporting = false
  let status = ''
  let aboutOpen = false
  let fileInput: HTMLInputElement

  onMount(() => {
    if (!('__TAURI_INTERNALS__' in window)) return

    let unlisten: (() => void) | undefined
    void import('@tauri-apps/api/event').then(async ({ listen }) => {
      unlisten = await listen<{ paths: string[] }>('tauri://drag-drop', async (event) => {
        const files = await filesFromTauriPaths(event.payload.paths)
        if (files.length) addFiles(files)
      })
    })

    return () => unlisten?.()
  })

  $: contentWidth = A4_WIDTH - margin * 2
  $: imageHeight = contentWidth * (230 / 990)
  $: rowsPerPage = Math.max(1, Math.floor((A4_HEIGHT - margin * 2) / (imageHeight + spacing)))
  $: pages = Array.from({ length: Math.max(1, Math.ceil(images.length / rowsPerPage)) }, (_, pageIndex) =>
    images.slice(pageIndex * rowsPerPage, (pageIndex + 1) * rowsPerPage),
  )

  function addFiles(fileList: FileList | File[]) {
    const supported = Array.from(fileList).filter((file) => file.type.startsWith('image/'))
    const newItems = supported
      .sort((a, b) => a.name.localeCompare(b.name, undefined, { numeric: true }))
      .map((file) => ({
        id: `${file.name}-${file.lastModified}-${Math.random()}`,
        file,
        url: URL.createObjectURL(file),
        name: file.name,
      }))

    images = [...images, ...newItems]
    status = newItems.length ? `${newItems.length} immagini importate` : 'Nessuna immagine supportata trovata'
  }

  function onFolderChange(event: Event) {
    const target = event.currentTarget as HTMLInputElement
    if (target.files) addFiles(target.files)
    target.value = ''
  }

  async function onDrop(event: DragEvent) {
    event.preventDefault()
    if (!event.dataTransfer) return

    const files = await filesFromDataTransfer(event.dataTransfer)
    if (files.length) addFiles(files)
  }

  async function filesFromDataTransfer(dataTransfer: DataTransfer): Promise<File[]> {
    const items = Array.from(dataTransfer.items)
    const entries = items
      .map((item) => (item as DataTransferItem & { webkitGetAsEntry?: () => FileSystemEntry | null }).webkitGetAsEntry?.())
      .filter((entry): entry is FileSystemEntry => Boolean(entry))

    if (!entries.length) return Array.from(dataTransfer.files)

    const files: File[] = []
    await Promise.all(entries.map((entry) => collectEntryFiles(entry, files)))
    return files
  }

  async function filesFromTauriPaths(paths: string[]): Promise<File[]> {
    const { readDir, readFile } = await import('@tauri-apps/plugin-fs')
    const filePaths: string[] = []

    async function collectPath(path: string): Promise<void> {
      const entries = await readDir(path)
      if (entries.length === 0) {
        filePaths.push(path)
        return
      }

      for (const entry of entries) {
        const entryPath = `${path.replace(/[\\/]$/, '')}/${entry.name}`
        if (entry.isDirectory) await collectPath(entryPath)
        else if (entry.isFile) filePaths.push(entryPath)
      }
    }

    for (const path of paths) {
      try {
        await collectPath(path)
      } catch {
        filePaths.push(path)
      }
    }

    const files: File[] = []
    for (const path of filePaths) {
      const extension = path.split('.').pop()?.toLowerCase() ?? ''
      const type = extension === 'png' ? 'image/png' : extension === 'webp' ? 'image/webp' : 'image/jpeg'
      if (!['png', 'jpg', 'jpeg', 'webp'].includes(extension)) continue
      const bytes = await readFile(path)
      const name = path.split(/[\\/]/).pop() ?? path
      files.push(new File([bytes], name, { type, lastModified: Date.now() }))
    }
    return files
  }

  async function collectEntryFiles(entry: FileSystemEntry, files: File[]): Promise<void> {
    if (entry.isFile) {
      await new Promise<void>((resolve, reject) => {
        ;(entry as FileSystemFileEntry).file((file) => {
          files.push(file)
          resolve()
        }, reject)
      })
      return
    }

    const directory = entry as FileSystemDirectoryEntry
    const reader = directory.createReader()
    let entries: FileSystemEntry[] = []
    do {
      const batch = await new Promise<FileSystemEntry[]>((resolve, reject) => reader.readEntries(resolve, reject))
      entries = batch
      await Promise.all(batch.map((child) => collectEntryFiles(child, files)))
    } while (entries.length)
  }

  function moveImage(fromId: string, toId: string) {
    if (fromId === toId) return
    const fromIndex = images.findIndex((image) => image.id === fromId)
    const toIndex = images.findIndex((image) => image.id === toId)
    const next = [...images]
    const [moved] = next.splice(fromIndex, 1)
    next.splice(toIndex, 0, moved)
    images = next
  }

  function removeImage(id: string) {
    const item = images.find((image) => image.id === id)
    if (item) URL.revokeObjectURL(item.url)
    images = images.filter((image) => image.id !== id)
  }

  function clearImages() {
    images.forEach((image) => URL.revokeObjectURL(image.url))
    images = []
    status = ''
  }

  async function exportPdf() {
    if (!images.length) {
      status = 'Importa almeno un’immagine prima di esportare'
      return
    }

    isExporting = true
    status = 'Creo il PDF…'
    const pdf = new jsPDF({ orientation: 'portrait', unit: 'mm', format: 'a4' })

    if (title || author) {
      pdf.setFontSize(22)
      pdf.text(title || 'Screenshot PDF', A4_WIDTH / 2, 35, { align: 'center' })
      pdf.setFontSize(12)
      if (author) pdf.text(author, A4_WIDTH / 2, 45, { align: 'center' })
    }

    for (let pageIndex = 0; pageIndex < pages.length; pageIndex += 1) {
      if (pageIndex > 0) pdf.addPage()
      const yStart = pageIndex === 0 && (title || author) ? 58 : margin
      for (let rowIndex = 0; rowIndex < pages[pageIndex].length; rowIndex += 1) {
        const image = pages[pageIndex][rowIndex]
        const y = yStart + rowIndex * (imageHeight + spacing)
        pdf.addImage(await fileToJpegDataUrl(image.file), 'JPEG', margin, y, contentWidth, imageHeight)
      }
      pdf.setFontSize(9)
      pdf.setTextColor(110)
      pdf.text(`${pageIndex + 1} / ${pages.length}`, A4_WIDTH - margin, A4_HEIGHT - 5, { align: 'right' })
      pdf.setTextColor(0)
    }

    const safeTitle = (title.trim() || 'screenshot').replace(/[^\w\s-]/g, '').replace(/\s+/g, ' ')
    const safeAuthor = author.trim().replace(/[^\w\s-]/g, '').replace(/\s+/g, ' ')
    const filename = `${safeTitle}${safeAuthor ? ` - ${safeAuthor}` : ''}.pdf`

    try {
      if ('__TAURI_INTERNALS__' in window) {
        const { save } = await import('@tauri-apps/plugin-dialog')
        const { writeFile } = await import('@tauri-apps/plugin-fs')
        const path = await save({
          defaultPath: filename,
          filters: [{ name: 'PDF', extensions: ['pdf'] }],
        })

        if (!path) {
          status = 'Esportazione annullata'
          return
        }

        await writeFile(path, new Uint8Array(pdf.output('arraybuffer')))
      } else {
        pdf.save(filename)
      }
      status = `PDF esportato: ${filename}`
    } catch (error) {
      console.error('Esportazione PDF non riuscita', error)
      status = 'Esportazione PDF non riuscita'
    } finally {
      isExporting = false
    }
  }

  function fileToJpegDataUrl(file: File): Promise<string> {
    return new Promise((resolve, reject) => {
      const image = new Image()
      const objectUrl = URL.createObjectURL(file)
      image.onload = () => {
        const canvas = document.createElement('canvas')
        canvas.width = image.naturalWidth
        canvas.height = image.naturalHeight
        const context = canvas.getContext('2d')
        URL.revokeObjectURL(objectUrl)
        if (!context) {
          reject(new Error('Il browser non supporta la conversione delle immagini'))
          return
        }
        context.drawImage(image, 0, 0)
        resolve(canvas.toDataURL('image/jpeg', 0.82))
      }
      image.onerror = () => {
        URL.revokeObjectURL(objectUrl)
        reject(new Error(`Impossibile elaborare ${file.name}`))
      }
      image.src = objectUrl
    })
  }
</script>

<svelte:head>
  <title>Screenshot2PDF v0.1.3</title>
  <meta name="description" content="Impagina screenshot musicali in un PDF A4" />
</svelte:head>

<main class="app-shell">
  <header class="topbar">
    <div class="brand">
      <p class="eyebrow">SCREENSHOT TO PDF</p>
      <div class="brand-title">
        <h1># Screenshot<span>2</span>PDF <small>v0.1.3</small></h1>
        <button class="about-button" aria-label="Informazioni su Screenshot2PDF" title="Informazioni su Screenshot2PDF" onclick={() => (aboutOpen = true)}>i</button>
      </div>
    </div>
    <div class="topbar-actions">
      <button class="primary-button" onclick={exportPdf} disabled={isExporting || !images.length}>
          {isExporting ? 'Esportazione…' : 'Esporta PDF'}
      </button>
    </div>
  </header>

  <section class="workspace">
    <aside class="sidebar">
      <div class="panel-heading">
        <div>
          <p class="eyebrow">PROGETTO</p>
          <h2>Impostazioni</h2>
        </div>
        <span class="count-badge">{images.length}</span>
      </div>

      <p class="section-label">Dati del progetto</p>
      <label class="field-label" for="title">Titolo</label>
      <input id="title" bind:value={title} placeholder="Es. Hey Jude" />
      <label class="field-label" for="author">Autore</label>
      <input id="author" bind:value={author} placeholder="Es. The Beatles" />

      <p class="section-label">Impaginazione</p>
      <div class="settings-grid">
        <label>
          <span class="field-label">Margini <b>{margin} mm</b></span>
          <input type="range" min="5" max="25" step="1" bind:value={margin} />
        </label>
        <label>
          <span class="field-label">Spazio <b>{spacing} mm</b></span>
          <input type="range" min="0" max="12" step="1" bind:value={spacing} />
        </label>
      </div>
      <p class="hint">A4 verticale · {rowsPerPage} immagini per pagina</p>

      <p class="section-label">Importa immagini</p>
      <div
        class="drop-zone"
        role="button"
        tabindex="0"
        ondragover={(event) => event.preventDefault()}
        ondrop={onDrop}
        onclick={() => fileInput.click()}
        onkeydown={(event) => event.key === 'Enter' && fileInput.click()}
      >
        <span class="upload-icon">↑</span>
        <strong>Trascina qui una cartella</strong>
        <span>oppure clicca per selezionare le immagini</span>
        <input
          bind:this={fileInput}
          class="hidden-input"
          type="file"
          accept="image/png,image/jpeg,image/webp"
          webkitdirectory
          multiple
          onchange={onFolderChange}
        />
      </div>

      <div class="list-toolbar">
        <span>{images.length ? 'Trascina per riordinare' : 'Nessuna immagine'}</span>
        {#if images.length}
          <button class="text-button" onclick={clearImages}>Svuota</button>
        {/if}
      </div>
      <div class="image-list" role="list">
        {#each images as image, index (image.id)}
          <div
            role="listitem"
            class:dragging={draggedId === image.id}
            class="image-row"
            draggable="true"
            ondragstart={() => (draggedId = image.id)}
            ondragend={() => (draggedId = null)}
            ondragover={(event) => event.preventDefault()}
            ondrop={() => {
              if (draggedId) moveImage(draggedId, image.id)
            }}
          >
            <span class="drag-handle">⠿</span>
            <span class="row-number">{String(index + 1).padStart(2, '0')}</span>
            <img src={image.url} alt="" />
            <span class="file-name">{image.name}</span>
            <button class="remove-button" aria-label={`Rimuovi ${image.name}`} onclick={() => removeImage(image.id)}>×</button>
          </div>
        {/each}
      </div>
      {#if status}<p class="status">{status}</p>{/if}
    </aside>

    <section class="preview-area">
      <div class="preview-heading">
        <div>
          <p class="eyebrow">ANTEPRIMA</p>
          <h2>Pagine A4</h2>
        </div>
        <span class="page-count">{pages.length} {pages.length === 1 ? 'pagina' : 'pagine'}</span>
      </div>
      <div class="pages">
        {#each pages as page, pageIndex}
          <article class="page">
            {#if pageIndex === 0 && (title || author)}
              <div class="page-title">
                <h3>{title || 'Screenshot PDF'}</h3>
                {#if author}<p>{author}</p>{/if}
              </div>
            {/if}
            <div class="page-images" style={`gap: ${spacing}mm; padding: ${margin}mm`}>
              {#each page as image}
                <img src={image.url} alt={image.name} />
              {/each}
            </div>
            <span class="page-number">{pageIndex + 1} / {pages.length}</span>
          </article>
        {:else}
          <div class="empty-preview">
            <div class="empty-icon">▱</div>
            <h3>Il tuo PDF inizia qui</h3>
            <p>Importa una cartella di screenshot per vedere l’anteprima A4.</p>
          </div>
        {/each}
      </div>
    </section>
  </section>
</main>

{#if aboutOpen}
  <div class="about-backdrop" role="presentation" onclick={(event) => event.currentTarget === event.target && (aboutOpen = false)}>
    <div class="about-window" role="dialog" aria-modal="true" aria-labelledby="about-title">
      <button class="about-close" aria-label="Chiudi informazioni" onclick={() => (aboutOpen = false)}>×</button>
      <img class="about-icon" src="/screenshot2pdf-icon.svg" alt="Icona Screenshot2PDF" />
      <h2 id="about-title">Screenshot2PDF</h2>
      <p class="about-version">Versione 0.1.3</p>
      <p class="about-author">Developed by V.Antedoro</p>
      <button class="about-ok" onclick={() => (aboutOpen = false)}>OK</button>
    </div>
  </div>
{/if}

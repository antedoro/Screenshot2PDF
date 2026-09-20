import fs from 'node:fs'
import path from 'node:path'

const version = process.argv[2]
if (!/^\d+\.\d+\.\d+$/.test(version ?? '')) {
  throw new Error('Uso: npm run version:set -- 0.1.2')
}

const root = process.cwd()
const read = (file) => fs.readFileSync(path.join(root, file), 'utf8')
const write = (file, content) => fs.writeFileSync(path.join(root, file), content)

const packageJson = JSON.parse(read('package.json'))
packageJson.version = version
write('package.json', `${JSON.stringify(packageJson, null, 2)}\n`)

const packageLock = JSON.parse(read('package-lock.json'))
packageLock.version = version
if (packageLock.packages?.['']) packageLock.packages[''].version = version
write('package-lock.json', `${JSON.stringify(packageLock, null, 2)}\n`)

const replacements = [
  ['src-tauri/tauri.conf.json', /"version": "\d+\.\d+\.\d+"/, `"version": "${version}"`],
  ['src-tauri/tauri.conf.json', /Screenshot2PDF v\d+\.\d+\.\d+/, `Screenshot2PDF v${version}`],
  ['src-tauri/Cargo.toml', /^version = "\d+\.\d+\.\d+"/m, `version = "${version}"`],
  ['src-tauri/Cargo.lock', /name = "app"\nversion = "\d+\.\d+\.\d+"/, `name = "app"\nversion = "${version}"`],
  ['src/App.svelte', /v\d+\.\d+\.\d+/g, `v${version}`],
  ['src/App.svelte', /Versione \d+\.\d+\.\d+/g, `Versione ${version}`],
  ['build-tauri.sh', /Screenshot2PDF_\d+\.\d+\.\d+_aarch64\.dmg/g, `Screenshot2PDF_${version}_aarch64.dmg`],
]

for (const [file, pattern, replacement] of replacements) {
  write(file, read(file).replace(pattern, replacement))
}

console.log(`Versione aggiornata a ${version}`)

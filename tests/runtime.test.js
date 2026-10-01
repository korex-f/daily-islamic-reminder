const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const model = require("../Model.js")
const paths = require("../Paths.js")

const root = path.resolve(__dirname, "..")
const manifest = JSON.parse(fs.readFileSync(path.join(root, "manifest.json"), "utf8"))
assert.equal(manifest.id, "dki.quran-verse-of-the-day")
assert.equal(manifest.entryPoints.barWidget, "BarWidget.qml")

assert.deepEqual(paths.pluginPaths("/custom/cache", "/custom/state", "/home/test"), {
  cacheDir: "/custom/cache/dki.quran-verse-of-the-day/",
  stateDir: "/custom/state/dki.quran-verse-of-the-day/",
  statePath: "/custom/state/dki.quran-verse-of-the-day/state.json",
  itemsPath: "/custom/cache/dki.quran-verse-of-the-day/items.json",
  editionsPath: "/custom/cache/dki.quran-verse-of-the-day/editions.json",
  migrationMarker: "/custom/state/dki.quran-verse-of-the-day/.legacy-cache-migrated"
})
const fallback = paths.pluginPaths("", "", "/home/test")
assert.equal(fallback.cacheDir, "/home/test/.cache/dki.quran-verse-of-the-day/")
assert.equal(fallback.statePath, "/home/test/.local/state/dki.quran-verse-of-the-day/state.json")
const migration = paths.migrationCommand(fallback, "/home/test/.config/omarchy/plugins/dki.quran-verse-of-the-day/cache")
assert.equal(migration[0], "sh")
assert.ok(migration[2].includes("if [ ! -e \"$3\" ]"), "migration must run only once")
assert.ok(migration[2].includes("[ ! -e \"$dst\" ]"), "migration must preserve existing XDG files")
assert.ok(migration[2].includes("state.json") && migration[2].includes("items.json") && migration[2].includes("editions.json"))

assert.equal(model.validAudioUrl("https://audio.example/1.mp3"), true)
assert.equal(model.validAudioUrl("http://audio.example/1.mp3"), false)
assert.equal(model.validAudioUrl("https://user@audio.example/file"), false)
assert.equal(model.validAudioUrl("https://audio.example/a b"), false)
assert.equal(model.translationFromReturn("  EN.Pickthall  "), "en.pickthall")
assert.equal(model.translationFromReturn("  "), "")

const panel = fs.readFileSync(path.join(root, "Panel.qml"), "utf8")
const service = fs.readFileSync(path.join(root, "Service.qml"), "utf8")
assert.match(panel, /Keys\.onReturnPressed/)
assert.match(panel, /Model\.translationFromReturn\(text\)/)
assert.match(service, /property FileView stateFile: FileView[\s\S]*?onLoaded:/)
assert.match(service, /property FileView itemsFile: FileView[\s\S]*?onLoaded:/)
assert.match(service, /property FileView editionsFile: FileView[\s\S]*?onLoaded:/)
assert.match(service, /onLoadFailed:/, "missing or malformed files must have fallback handlers")
assert.match(service, /statusText: loading \? "Loading…" : \(lastError !== ""/, "IPC status should report fetch failures even when one source loaded")
assert.match(fs.readFileSync(path.join(root, ".gitignore"), "utf8"), /^\/cache\//m)

console.log("Runtime path, migration, manifest, and interaction regression tests passed")

import QtQuick
import Quickshell
import Quickshell.Io
import "Model.js" as Model

// Lazy, persistent reminder state. Nothing is fetched until load() is called
// by the panel. Text is immutable, so each selected reference is cached by
// source/reference/edition and never requested twice.
Item {
  id: root
  property var settings: ({})
  readonly property string home: Quickshell.env("HOME")
  readonly property string cacheDir: home + "/.config/omarchy/plugins/io.github.korex-f.daily-islamic-reminder/cache/"
  readonly property string statePath: cacheDir + "state.json"
  readonly property string itemsPath: cacheDir + "items.json"
  readonly property string editionsPath: cacheDir + "editions.json"
  readonly property string mode: Model.choice(setting("rotationMode", "both"), ["both", "quran-only", "hadith-only"], "both")
  readonly property string translation: String(setting("translation", "en.sahih") || "en.sahih").toLowerCase()
  readonly property string collection: Model.choice(setting("hadithCollection", "any"), ["any", "bukhari", "muslim", "abudawud", "tirmidhi"], "any")
  readonly property bool includeWeak: setting("includeWeakGrades", false) === true
  readonly property bool audioEnabled: setting("audioEnabled", false) === true

  property bool loaded: false
  property bool readingCache: false
  property bool stateRead: false
  property bool itemsRead: false
  property bool editionsRead: false
  property bool loadRequested: false
  property bool requestedMetadataRefresh: false
  property bool loading: false
  property string lastError: ""
  property var state: ({ last_shown_date: "", quran_position: -1, hadith_position: -1 })
  property var items: ({})
  property var editions: ({ fetched_at: "", quran: [], hadith: [] })
  property string quranReference: ""
  property string quranArabic: ""
  property string quranText: ""
  property string quranEditionName: ""
  property string quranAudio: ""
  property string hadithArabic: ""
  property string hadithText: ""
  property string hadithCollectionName: ""
  property string hadithBook: ""
  property string hadithNumber: ""
  property string hadithGrade: ""
  property bool showQuran: mode !== "hadith-only"
  property bool showHadith: mode !== "quran-only"
  property int pending: 0
  property string quranKey: ""
  property string hadithKey: ""
  property string hadithEnglishRaw: ""
  property int metadataPending: 0
  readonly property var quranEditions: editions && Array.isArray(editions.quran) ? editions.quran : []
  readonly property string statusText: loading ? "Loading…" : (quranReference !== "" || hadithNumber !== "" ? "Today’s Reminder" : (lastError !== "" ? lastError : "Ready"))

  function setting(name, fallback) {
    var v = settings ? settings[name] : undefined
    return v === undefined || v === null ? fallback : v
  }
  function parse(raw, fallback) { try { return JSON.parse(String(raw || "")) } catch (e) { return fallback } }
  function write(file, value) { file.setText(JSON.stringify(value, null, 2) + "\n") }
  function item(key) { return items[key] || null }
  function save() { write(stateFile, state); write(itemsFile, items) }
  function cacheKey(source, reference, edition) { return source + ":" + reference + ":" + edition }
  function todayIso() { return Model.isoDate(new Date()) }

  function load(forceMetadata) {
    loadRequested = true
    requestedMetadataRefresh = requestedMetadataRefresh || forceMetadata === true
    if (loading || !loaded) return
    loadRequested = false
    advanceIfNeeded()
    maybeRefreshEditions(requestedMetadataRefresh)
    requestedMetadataRefresh = false
    loadCurrent()
  }

  function advanceIfNeeded() {
    var date = todayIso()
    if (state.last_shown_date === date) return
    if (showQuran) state.quran_position = Model.nextPosition(state.quran_position, Model.AYAHS.length, setting("quranSequence", "sequential"), date + "q")
    if (showHadith) state.hadith_position = Model.nextPosition(state.hadith_position, Model.hadithPool(collection, includeWeak).length, setting("hadithSequence", "sequential"), date + "h")
    state.last_shown_date = date
    save()
  }

  function loadCurrent() {
    lastError = ""
    if (showQuran) {
      var ref = Model.AYAHS[Math.max(0, state.quran_position) % Model.AYAHS.length]
      quranKey = cacheKey("quran", ref, translation)
      var q = item(quranKey)
      if (q) applyQuran(q)
      else fetchQuran(ref)
    } else clearQuran()
    if (showHadith) {
      var pool = Model.hadithPool(collection, includeWeak)
      if (pool.length === 0) { clearHadith(); lastError = "No Hadith records match this collection and grade filter."; return }
      var candidate = pool[Math.max(0, state.hadith_position) % pool.length]
      hadithKey = cacheKey("hadith", candidate.collection + "/" + candidate.number, "eng")
      var h = item(hadithKey)
      if (h && Model.isAllowedGrade(h.grade, includeWeak)) applyHadith(h)
      else if (h) rejectHadith(h.grade)
      else fetchHadith(candidate)
    } else clearHadith()
  }

  function clearQuran() { quranReference = ""; quranArabic = ""; quranText = ""; quranEditionName = ""; quranAudio = "" }
  function clearHadith() { hadithArabic = ""; hadithText = ""; hadithCollectionName = ""; hadithBook = ""; hadithNumber = ""; hadithGrade = "" }
  function rejectHadith(grade) {
    // Cache excluded records, but never render them without an eligible grade.
    clearHadith()
    lastError = "The selected Hadith is graded “" + grade + "” and is excluded by the current filter. Enable other grades in settings to view it."
  }
  function fetchQuran(reference) {
    loading = true; pending += 1
    quranProc.reference = reference
    quranProc.command = ["curl", "-fsS", "--max-time", "10", Model.quranUrl(reference, translation)]
    quranProc.running = true
  }
  function fetchHadith(candidate) {
    loading = true; pending += 1
    hadithProc.candidate = candidate
    // Fetch matching language editions separately; the API is static and
    // record-numbered, so they can be joined without scraping.
    hadithProc.command = ["curl", "-fsS", "--max-time", "10", Model.hadithUrl("eng-" + candidate.collection, candidate.number)]
    hadithProc.running = true
  }
  function done() {
    pending = Math.max(0, pending - 1)
    loading = pending > 0
    // Settings may change while a request is in flight. Re-read the current
    // selection afterwards so an old response cannot remain on the panel.
    if (!loading && loadRequested) Qt.callLater(function() { root.load(requestedMetadataRefresh) })
  }
  function applyQuran(q) { quranReference = q.reference || ""; quranArabic = q.arabic || ""; quranText = q.text || ""; quranEditionName = q.edition || translation; quranAudio = q.audio || "" }
  function applyHadith(h) { hadithArabic = h.arabic || ""; hadithText = h.text || ""; hadithCollectionName = h.collection || ""; hadithBook = h.book || ""; hadithNumber = h.number || ""; hadithGrade = h.grade || "" }
  function maybeRefreshEditions(force) {
    if (!force && !Model.isOlderThanDays(editions.fetched_at, 7)) return
    if (editionsProc.running || hadithEditionsProc.running) return
    metadataPending = 2
    editionsProc.command = ["curl", "-fsS", "--max-time", "10", "https://api.alquran.cloud/v1/edition?format=text&type=translation"]
    editionsProc.running = true
    hadithEditionsProc.command = ["curl", "-fsS", "--max-time", "10", "https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions.min.json"]
    hadithEditionsProc.running = true
  }
  function metadataDone() {
    metadataPending = Math.max(0, metadataPending - 1)
    if (metadataPending === 0) {
      editions.fetched_at = new Date().toISOString()
      write(editionsFile, editions)
    }
  }

  Process {
    id: ensureDir
    command: ["mkdir", "-p", root.cacheDir]
    onExited: function(code) {
      if (code !== 0) { root.lastError = "Couldn’t create the reminder cache directory."; return }
      root.readingCache = true
      stateFile.reload(); itemsFile.reload(); editionsFile.reload()
    }
  }
  Process {
    id: quranProc
    property string reference: ""
    stdout: StdioCollector { id: quranOut; waitForEnd: true }
    onExited: function(code) {
      if (code !== 0) root.lastError = "Couldn’t fetch the Quran ayah."
      else {
        var value = Model.parseQuran(quranOut.text, quranProc.reference, root.translation)
        if (value) { root.items[root.quranKey] = value; root.applyQuran(value); root.save() }
        else root.lastError = "Couldn’t parse the Quran response."
      }
      root.done()
    }
  }
  Process {
    id: hadithProc
    property var candidate: null
    stdout: StdioCollector { id: hadithOut; waitForEnd: true }
    onExited: function(code) {
      if (code !== 0) { root.lastError = "Couldn’t fetch the Hadith translation."; root.done(); return }
      root.hadithEnglishRaw = hadithOut.text
      hadithArabicProc.candidate = hadithProc.candidate
      hadithArabicProc.command = ["curl", "-fsS", "--max-time", "10", Model.hadithUrl("ara-" + hadithProc.candidate.collection, hadithProc.candidate.number)]
      hadithArabicProc.running = true
    }
  }
  Process {
    id: hadithArabicProc
    property var candidate: null
    stdout: StdioCollector { id: hadithArabicOut; waitForEnd: true }
    onExited: function(code) {
      if (code !== 0) root.lastError = "Couldn’t fetch the Hadith Arabic text."
      else {
        var value = Model.parseHadith(root.hadithEnglishRaw, hadithArabicOut.text, hadithArabicProc.candidate)
        // Never render an ungraded Hadith: lack of usable grade is an error.
        if (value && value.grade !== "") {
          root.items[root.hadithKey] = value
          root.save()
          if (Model.isAllowedGrade(value.grade, root.includeWeak)) root.applyHadith(value)
          else root.rejectHadith(value.grade)
        }
        else root.lastError = "The Hadith source did not provide a visible grade."
      }
      root.done()
    }
  }
  Process {
    id: editionsProc
    stdout: StdioCollector { id: editionsOut; waitForEnd: true }
    onExited: function(code) {
      if (code === 0) root.editions.quran = root.parse(editionsOut.text, {}).data || []
      root.metadataDone()
    }
  }
  Process {
    id: hadithEditionsProc
    stdout: StdioCollector { id: hadithEditionsOut; waitForEnd: true }
    onExited: function(code) {
      if (code === 0) root.editions.hadith = root.parse(hadithEditionsOut.text, {})
      root.metadataDone()
    }
  }
  function markCacheRead(kind) {
    if (!readingCache) return
    if (kind === "state") stateRead = true
    else if (kind === "items") itemsRead = true
    else editionsRead = true
    if (stateRead && itemsRead && editionsRead) {
      readingCache = false
      loaded = true
      if (loadRequested) load(requestedMetadataRefresh)
    }
  }
  property FileView stateFile: FileView {
    path: root.statePath
    atomicWrites: true
    printErrors: false
    onLoaded: {
      root.state = root.parse(text(), root.state)
      root.markCacheRead("state")
    }
    onLoadFailed: {
      root.state = root.state
      root.markCacheRead("state")
    }
  }
  property FileView itemsFile: FileView {
    path: root.itemsPath
    atomicWrites: true
    printErrors: false
    onLoaded: {
      root.items = root.parse(text(), {})
      root.markCacheRead("items")
    }
    onLoadFailed: {
      root.items = ({})
      root.markCacheRead("items")
    }
  }
  property FileView editionsFile: FileView {
    path: root.editionsPath
    atomicWrites: true
    printErrors: false
    onLoaded: {
      root.editions = root.parse(text(), root.editions)
      root.markCacheRead("editions")
    }
    onLoadFailed: {
      root.editions = root.editions
      root.markCacheRead("editions")
    }
  }
  Component.onCompleted: ensureDir.running = true
}

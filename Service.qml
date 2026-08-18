import QtQuick
import Quickshell
import Quickshell.Io
import "Model.js" as Model

// Daily-ayah fetch + local cache. The widget picks a reference for the day
// (day-of-year indexed into Model.AYAHS) and fetches its Arabic text and the
// configured translation from alquran.cloud in one call. The result is cached
// under ~/.local/state/omarchy so the bar only hits the network once a day,
// not on every shell restart.
Item {
  id: root

  property var settings: ({})

  readonly property string home: Quickshell.env("HOME")
  readonly property string stateDir: home + "/.local/state/omarchy/"
  readonly property string cachePath: stateDir + "quran-verse-of-the-day.json"

  readonly property string translation: {
    var t = String(setting("translation", "en.sahih") || "").trim().toLowerCase()
    return t === "" ? "en.sahih" : t
  }
  onTranslationChanged: root.refreshIfStale()

  readonly property bool showArabic: setting("showArabic", true) !== false
  onShowArabicChanged: root.refreshIfStale()

  readonly property string todayReference: Model.referenceForDate(new Date())
  readonly property string todayIso: Model.isoDate(new Date())

  property string verseReference: ""
  property string verseArabic: ""
  property string verseText: ""
  property string translationName: ""
  property bool loading: false
  property string lastError: ""

  property string _cachedDate: ""
  property string _cachedTranslation: ""
  property bool _cachedShowArabic: false
  property string _fetchOutput: ""

  readonly property string statusText: loading
    ? "Loading…"
    : (verseReference !== "" ? verseReference : (lastError !== "" ? lastError : "Quran Verse"))

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  // Captures the reference/translation/date actually requested, so a
  // settings change or day rollover that lands mid-flight can't mislabel
  // the response that comes back (which still reflects the old request).
  function fetch() {
    if (fetchProc.running) return
    root.loading = true
    root.lastError = ""
    fetchProc.requestedTranslation = root.translation
    fetchProc.requestedReference = root.todayReference
    fetchProc.requestedDate = root.todayIso
    fetchProc.command = ["curl", "-fsS", "--max-time", "8",
      Model.apiUrl(fetchProc.requestedReference, fetchProc.requestedTranslation)]
    fetchProc.running = true
  }

  function refresh() {
    fetch()
  }

  function refreshIfStale() {
    if (fetchProc.running) return
    if (root._cachedDate !== root.todayIso || root._cachedTranslation !== root.translation) fetch()
  }

  function saveCache(date, translation) {
    cacheFile.setText(JSON.stringify({
      date: date,
      translation: translation,
      reference: root.verseReference,
      arabic: root.verseArabic,
      text: root.verseText,
      translationName: root.translationName
    }, null, 2) + "\n")
    root._cachedDate = date
    root._cachedTranslation = translation
  }

  function _applyCache(raw) {
    try {
      var data = JSON.parse(String(raw || ""))
      root._cachedDate = String(data.date || "")
      root._cachedTranslation = String(data.translation || "")
      if (data.reference) root.verseReference = String(data.reference)
      if (data.arabic) root.verseArabic = String(data.arabic)
      if (data.text) root.verseText = String(data.text)
      if (data.translationName) root.translationName = String(data.translationName)
    } catch (e) {
      root._cachedDate = ""
      root._cachedTranslation = ""
    }
    root.refreshIfStale()
  }

  Process {
    id: ensureDirProc
    command: ["mkdir", "-p", root.stateDir]
    running: false
  }

  Process {
    id: fetchProc
    running: false
    property string requestedTranslation: ""
    property string requestedReference: ""
    property string requestedDate: ""
    stdout: StdioCollector { id: fetchStdout; waitForEnd: true; onStreamFinished: root._fetchOutput = text }
    stderr: StdioCollector { id: fetchStderr; waitForEnd: true }
    onExited: function(exitCode) {
      root.loading = false
      if (exitCode !== 0) {
        root.lastError = "Couldn't reach alquran.cloud"
        Qt.callLater(root.refreshIfStale)
        return
      }
      var stdout = String(fetchStdout.text || root._fetchOutput || "")
      try {
        var data = JSON.parse(stdout)
        if (!data || !data.data || data.data.length < 2) throw new Error("empty response")
        // First entry is quran-uthmani (Arabic), second is the requested
        // translation; the API returns editions in the order requested.
        root.verseArabic = Model.cleanVerseText(data.data[0].text)
        root.verseText = Model.cleanVerseText(data.data[1].text)
        root.verseReference = Model.referenceLabel(fetchProc.requestedReference)
        root.translationName = String(data.data[1].edition.englishName || fetchProc.requestedTranslation.toUpperCase())
        root.lastError = ""
        root.saveCache(fetchProc.requestedDate, fetchProc.requestedTranslation)
      } catch (e) {
        root.lastError = "Couldn't parse ayah response"
      }
      // The setting or day may have moved on while this request was in
      // flight; re-check now that fetchProc.running has settled.
      Qt.callLater(root.refreshIfStale)
    }
  }

  property FileView cacheFile: FileView {
    path: root.cachePath
    watchChanges: false
    atomicWrites: true
    printErrors: false
    onLoaded: root._applyCache(text())
    onLoadFailed: root.fetch()
  }

  Timer {
    interval: 3600000
    repeat: true
    running: true
    onTriggered: root.refreshIfStale()
  }

  Component.onCompleted: {
    ensureDirProc.running = true
    Qt.callLater(function() { cacheFile.reload() })
  }
}
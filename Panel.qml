import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

// The Quran and Hadith are deliberately separate sections: commentary and
// grading metadata can never visually read as part of the Quranic ayah.
Panel {
  id: root
  moduleName: "dki.quran-verse-of-the-day"
  ipcTarget: "dki.quran-verse-of-the-day"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var service: null
  property bool showingSettings: false
  property string translationSearch: ""
  readonly property var barIdentity: hostWidget || root
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property var defaultTranslations: [
    { code: "en.sahih", name: "Saheeh International" }, { code: "en.pickthall", name: "Pickthall" },
    { code: "en.yusufali", name: "Yusuf Ali" }, { code: "en.asad", name: "Muhammad Asad" },
    { code: "en.hilali", name: "Hilali & Khan" }, { code: "en.arberry", name: "A. J. Arberry" }
  ]
  readonly property var translations: {
    var values = defaultTranslations.slice()
    var seen = ({})
    for (var i = 0; i < values.length; i++) seen[values[i].code] = true
    var remote = service && service.quranEditions ? service.quranEditions : []
    for (var j = 0; j < remote.length; j++) {
      var edition = remote[j]
      var code = String(edition.identifier || "").toLowerCase()
      if (code !== "" && !seen[code]) {
        values.push({ code: code, name: String(edition.englishName || edition.name || code) })
        seen[code] = true
      }
    }
    return values
  }

  function hasSavedSettings() {
    if (!settings) return false
    for (var key in settings) if (key !== "id") return true
    return false
  }
  function open() { controller.show(); if (!hasSavedSettings()) showingSettings = true; if (service) service.load() }
  function close() { controller.hide() }
  function toggle() { if (opened) close(); else open() }
  function switchPanel(direction) {
    if (bar && typeof bar.switchPanelFrom === "function") return bar.switchPanelFrom(barIdentity, direction)
    return false
  }
  function refresh() { if (service) service.load(true) }
  function openQuranAudio() {
    var target = String(service ? service.quranAudio : "").trim()
    if (target.indexOf("https://") === 0 && target.indexOf(" ") === -1) Qt.openUrlExternally(target)
  }
  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }
  function persist(values) {
    var entry = { id: moduleName }
    for (var key in settings) if (key !== "id") entry[key] = settings[key]
    for (var changed in values) entry[changed] = values[changed]
    settings = entry
    if (hostWidget && "settings" in hostWidget) hostWidget.settings = entry
    if (bar && bar.shell && typeof bar.shell.updateEntryInline === "function") bar.shell.updateEntryInline(moduleName, entry)
    if (service) service.load()
  }
  function cycle(key, values) {
    var current = String(setting(key, values[0]))
    var index = values.indexOf(current)
    persist((function() { var result = {}; result[key] = values[(index + 1 + values.length) % values.length]; return result })())
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: false
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(390))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(520))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) { if (t === "r" || t === "R") root.refresh() }

      Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
          id: column
          width: parent.width
          spacing: Style.space(10)

          Row {
            width: parent.width
            spacing: Style.space(8)
            PanelHero {
              width: parent.width - gear.width - Style.space(8)
              title: root.showingSettings ? "Reminder settings" : "Today’s Reminder"
              meta: root.showingSettings ? "Changes are saved to your Omarchy bar entry" : (root.service && root.service.loading ? "Loading…" : "Quran and Hadith")
              foreground: root.foreground
              fontFamily: root.fontFamily
              iconComponent: Component {
                Text { textFormat: Text.PlainText;
                  text: "🕌"
                  font.family: "Noto Color Emoji"
                  font.pixelSize: Style.font.display
                }
              }
            }
            Rectangle {
              id: gear
              width: Style.space(32); height: width; radius: height / 2
              color: "transparent"; border.color: root.dim
              Text { textFormat: Text.PlainText;  anchors.centerIn: parent; text: ""; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.body }
              MouseArea { anchors.fill: parent; onClicked: root.showingSettings = !root.showingSettings }
            }
          }

          Item {
            visible: !root.showingSettings
            width: parent.width
            height: reminderColumn.implicitHeight
            Column {
              id: reminderColumn
              width: parent.width
              spacing: Style.space(10)
              Text { textFormat: Text.PlainText;  visible: root.service && root.service.showQuran; text: "QURAN"; color: root.dim; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall; font.bold: true }
              Text { textFormat: Text.PlainText;  visible: root.service && root.service.showQuran; width: parent.width; text: root.service ? root.service.quranReference : ""; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.body; font.bold: true }
              Text { visible: root.service && root.service.showQuran && root.service.quranArabic !== ""; width: parent.width; text: root.service ? root.service.quranArabic : ""; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.subtitle; font.bold: true; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignRight; textFormat: Text.PlainText }
              Text { textFormat: Text.PlainText;  visible: root.service && root.service.showQuran; width: parent.width; text: root.service && root.service.quranText !== "" ? root.service.quranText : "Loading Quran ayah…"; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.body; wrapMode: Text.WordWrap }
              Text { textFormat: Text.PlainText;  visible: root.service && root.service.showQuran && root.service.quranEditionName !== ""; text: "Translation: " + root.service.quranEditionName + " · Al Quran Cloud"; color: root.dim; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall }
              Rectangle {
                visible: root.service && root.service.showQuran && root.setting("audioEnabled", false) && root.service.quranAudio !== ""
                width: parent.width
                height: Style.space(30)
                radius: 4
                color: "transparent"
                border.color: root.dim
                Text { textFormat: Text.PlainText;  anchors.centerIn: parent; text: "Open Quran audio"; color: root.dim; font.pixelSize: Style.font.bodySmall }
                MouseArea { anchors.fill: parent; onClicked: root.openQuranAudio() }
              }
              PanelSeparator { visible: root.service && root.service.showQuran && root.service.showHadith; foreground: root.foreground }
              Text { textFormat: Text.PlainText;  visible: root.service && root.service.showHadith; text: "HADITH"; color: root.dim; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall; font.bold: true }
              Text { textFormat: Text.PlainText;  visible: root.service && root.service.showHadith; width: parent.width; text: root.service ? root.service.hadithCollectionName + " · " + root.service.hadithBook + " · Hadith " + root.service.hadithNumber + "\nGrade: " + root.service.hadithGrade + " · Hadith API" : ""; color: root.dim; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall; wrapMode: Text.WordWrap }
              Text { visible: root.service && root.service.showHadith && root.service.hadithArabic !== ""; width: parent.width; text: root.service ? root.service.hadithArabic : ""; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.subtitle; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignRight; textFormat: Text.PlainText }
              Text { textFormat: Text.PlainText;  visible: root.service && root.service.showHadith; width: parent.width; text: root.service && root.service.hadithText !== "" ? root.service.hadithText : "Loading graded Hadith…"; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.body; wrapMode: Text.WordWrap }
              Text { textFormat: Text.PlainText;  visible: root.service && root.service.lastError !== ""; width: parent.width; text: root.service ? root.service.lastError : ""; color: root.dim; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall; wrapMode: Text.WordWrap }
              Rectangle {
                width: parent.width
                height: Style.space(30)
                radius: 4
                color: "transparent"
                border.color: root.dim
                Text { textFormat: Text.PlainText;  anchors.centerIn: parent; text: "Refresh metadata"; color: root.foreground; font.pixelSize: Style.font.bodySmall }
                MouseArea { anchors.fill: parent; onClicked: root.refresh() }
              }
            }
          }

          Item {
            visible: root.showingSettings
            width: parent.width
            height: settingsColumn.implicitHeight
            Column {
              id: settingsColumn
              width: parent.width
              spacing: Style.space(8)
              Text { textFormat: Text.PlainText;  visible: !root.hasSavedSettings(); text: "Welcome — choose your preferred translation, Hadith collection, and rotation mode. Suggested settings are ready to use."; width: parent.width; color: root.dim; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall; wrapMode: Text.WordWrap }
              SettingButton { visible: !root.hasSavedSettings(); label: "Use suggested settings"; onClicked: root.persist({ translation: "en.sahih", hadithCollection: "any", rotationMode: "both", quranSequence: "sequential", hadithSequence: "sequential", includeWeakGrades: false }) }
              Text { textFormat: Text.PlainText;  text: "Rotation mode: " + root.setting("rotationMode", "both"); color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.body }
              SettingButton { label: "Cycle rotation mode"; onClicked: root.cycle("rotationMode", ["both", "quran-only", "hadith-only"]) }
              Text { textFormat: Text.PlainText;  text: "Quran order: " + root.setting("quranSequence", "sequential") + " · Hadith order: " + root.setting("hadithSequence", "sequential"); color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.body }
              Row {
                spacing: Style.space(8)
                SettingButton { label: "Cycle Quran order"; onClicked: root.cycle("quranSequence", ["sequential", "random"]) }
                SettingButton { label: "Cycle Hadith order"; onClicked: root.cycle("hadithSequence", ["sequential", "random"]) }
              }
              Text { textFormat: Text.PlainText;  text: "Hadith collection: " + root.setting("hadithCollection", "any"); color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.body }
              SettingButton { label: "Cycle collection"; onClicked: root.cycle("hadithCollection", ["any", "bukhari", "muslim", "abudawud", "tirmidhi"]) }
              SettingButton { label: root.setting("includeWeakGrades", false) ? "Exclude weaker grades" : "Include grades beyond sahih/hasan"; onClicked: root.persist({ includeWeakGrades: !root.setting("includeWeakGrades", false) }) }
              SettingButton { label: root.setting("audioEnabled", false) ? "Hide Quran audio link" : "Show Quran audio link"; onClicked: root.persist({ audioEnabled: !root.setting("audioEnabled", false) }) }
              Text { textFormat: Text.PlainText;  text: "Quran translation edition"; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.body }
              Rectangle {
                width: parent.width
                height: Style.space(32)
                color: "transparent"
                border.color: root.dim
                radius: 4
                TextInput {
                  id: translationInput
                  anchors.fill: parent
                  anchors.margins: Style.space(7)
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  text: root.translationSearch
                  onTextChanged: root.translationSearch = text
                  Keys.onReturnPressed: function(event) {
                    if (text.trim() !== "") root.persist({ translation: text.trim().toLowerCase() })
                    event.accepted = true
                  }
                }
              }
              Repeater { model: root.translations; delegate: SettingButton { required property var modelData; visible: root.translationSearch === "" || modelData.code.indexOf(root.translationSearch.toLowerCase()) >= 0 || modelData.name.toLowerCase().indexOf(root.translationSearch.toLowerCase()) >= 0; label: modelData.name + " (" + modelData.code + ")"; onClicked: { root.translationSearch = ""; root.persist({ translation: modelData.code }) } } }
              Text { textFormat: Text.PlainText;  text: "Default: Saheeh International. The cached edition list refreshes weekly; direct valid Al Quran Cloud edition codes also work."; width: parent.width; color: root.dim; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall; wrapMode: Text.WordWrap }
            }
          }
        }
      }
    }
  }

  component SettingButton: Rectangle {
    property string label: ""
    signal clicked()
    implicitWidth: Math.max(Style.space(120), labelText.implicitWidth + Style.space(16))
    implicitHeight: Style.space(30)
    color: "transparent"; border.color: root.dim; radius: 4
    Text { textFormat: Text.PlainText;  id: labelText; anchors.centerIn: parent; text: parent.label; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall }
    MouseArea { anchors.fill: parent; onClicked: parent.clicked() }
  }
}

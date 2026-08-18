import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Bar entry for the daily-ayah widget: a book icon in the bar with today's
// ayah behind it. Left-click opens the popup, middle-click forces a refresh
// past the daily cache, right-click sends today's ayah as a notification.
//
// The Service lives here (not in the panel) so the bar icon can react to the
// same fetch state the panel shows, and so one fetch is shared across the
// whole widget.
BarWidget {
  id: root
  moduleName: "dki.quran-verse-of-the-day"

  Service {
    id: verse
    settings: root.settings
  }

  readonly property color barForeground: bar ? bar.barForeground : Color.foreground

  // ---- Panel lifecycle. Shape contract for shell.summon/hide/toggle
  //      routing: Bar.findPanelWidget requires open/close/opened on the
  //      bar-widget root.
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function togglePanel() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  function refresh() {
    verse.refresh()
  }

  function notifyToday() {
    notifyProc.command = ["omarchy-notification-send",
      verse.verseReference !== "" ? verse.verseReference : "Quran Verse of the Day",
      verse.verseText !== "" ? verse.verseText : "Still loading today's ayah…"]
    notifyProc.running = true
  }

  Process {
    id: notifyProc
    running: false
  }

  // Forwarded so this widget can stand in for the panel as the bar's popout
  // identity: Bar.requestPopout prefers closeForPopoutSwitch over close, and
  // KeyboardPanel reads popoutSwitchClosing back off its owner.
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
    if ("service" in target) target.service = verse
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  IpcHandler {
    target: "dki.quran-verse-of-the-day"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.togglePanel() }
    function refresh(): string { verse.refresh(); return "ok" }
    function status(): string { return verse.statusText }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    foreground: verse.lastError !== "" && verse.verseText === ""
      ? Qt.darker(root.barForeground, 1.2)
      : root.barForeground
    tooltipText: verse.verseReference !== "" ? verse.verseReference : "Quran Verse of the Day"

    onPressed: function(b) {
      if (b === Qt.RightButton) root.notifyToday()
      else if (b === Qt.MiddleButton) root.refresh()
      else root.togglePanel()
    }
  }
}
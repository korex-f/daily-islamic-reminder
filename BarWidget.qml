import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Compact entry point. Service.qml is deliberately lazy: opening this widget
// checks persisted daily state and only fetches an uncached selected item.
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
    verse.load()
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function togglePanel() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  function refresh() { verse.load(true) }

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
    function refresh(): string { verse.load(true); return "ok" }
    function status(): string { return verse.statusText }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "🕌"
    fontFamily: "Noto Color Emoji"
    foreground: verse.lastError !== "" && verse.quranText === "" && verse.hadithText === ""
      ? Qt.darker(root.barForeground, 1.2)
      : root.barForeground
    tooltipText: "Today’s Islamic reminder"

    onPressed: function(b) {
      if (b === Qt.MiddleButton) root.refresh()
      else root.togglePanel()
    }
  }
}

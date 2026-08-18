import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Popup for the daily-ayah widget: a hero with the reference and translation,
// then the Arabic text (when enabled) above the English translation. Arabic
// renders right-aligned and larger; the translation is the reading copy.
//
// BarWidget.qml owns the bar icon and hands this panel the button to anchor
// against and the shared Service to read from.
Panel {
  id: root
  moduleName: "dki.quran-verse-of-the-day"
  ipcTarget: "dki.quran-verse-of-the-day"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var service: null

  // The bar tracks the widget mounted in its slot — BarWidget.qml — not this
  // nested panel. Everything the bar identifies a panel by has to be that
  // widget: the popout coordinator (and with it the open-panel dot under the
  // pill) compares against `slot.activeItem`, and switchPanelFrom looks the
  // slot up the same way.
  readonly property var barIdentity: hostWidget || root

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  function open() {
    root.controller.show()
  }

  function close() {
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function refresh() {
    if (root.service) root.service.refresh()
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: true
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(420))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) { if (t === "r" || t === "R") root.refresh() }

      Flickable {
        id: scroll
        anchors.fill: parent
        contentWidth: column.width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height || contentWidth > width

        Column {
          id: column
          anchors.left: parent.left
          anchors.right: parent.right
          spacing: Style.space(12)

          PanelHero {
            width: parent.width
            title: root.service && root.service.verseReference !== ""
              ? root.service.verseReference
              : "Quran Verse of the Day"
            meta: root.service ? root.service.translationName : ""
            foreground: root.foreground
            fontFamily: root.fontFamily
            iconComponent: Component {
              Text {
                text: ""
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.display
              }
            }
          }

          PanelSeparator { foreground: root.foreground }

          // Arabic text first: the word of the Qur'an itself, above any
          // rendering of it. RTL and right-aligned, sized a step up from the
          // translation because it carries the verse numbers inline.
          Text {
            visible: root.service && root.service.showArabic && root.service.verseArabic !== ""
            width: parent.width
            text: root.service ? root.service.verseArabic : ""
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.subtitle
            font.weight: Font.DemiBold
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignRight
            textFormat: Text.PlainText
          }

          Text {
            width: parent.width
            text: root.service && root.service.verseText !== ""
              ? root.service.verseText
              : (root.service && root.service.loading
                ? "Loading…"
                : (root.service && root.service.lastError !== "" ? root.service.lastError : ""))
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            wrapMode: Text.WordWrap
          }

          Text {
            visible: root.service && root.service.lastError !== "" && root.service.verseText !== ""
            width: parent.width
            text: root.service ? root.service.lastError : ""
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
          }
        }
      }
    }
  }
}
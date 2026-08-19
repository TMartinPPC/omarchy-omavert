import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui

// Bar icon for the VERT converter. The conversion flow lives in Panel.qml;
// this shell routes open/close/toggle to it and mirrors the contract the bar
// relies on for panel widgets (open/close/opened, popout switching).
BarWidget {
  id: root
  moduleName: "io.github.tmartinppc.vert"

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function toggle() { if (panelLoader.item) panelLoader.item.toggle() }
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }

  function injectPanel() {
    if (!panelLoader.item) return
    panelLoader.item.bar = root.bar
    panelLoader.item.settings = root.settings
    panelLoader.item.anchorItem = button
    panelLoader.item.hostWidget = root
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
    target: root.moduleName

    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰿺"
    tooltipText: "Convert a file — or drop a file here"
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) root.toggle()
    }
  }

  // Accept a file dragged onto the bar icon itself. Dropping opens the panel
  // with the file pre-loaded, so no click is needed to start a conversion.
  DropArea {
    id: barDropArea
    anchors.fill: parent
    keys: ["text/uri-list"]
    onDropped: function(drop) {
      if (drop.hasUrls && drop.urls.length > 0 && panelLoader.item
          && typeof panelLoader.item.acceptDrop === "function") {
        panelLoader.item.acceptDrop(drop.urls[0])
        root.open()
      }
      drop.accept()
    }
  }

}
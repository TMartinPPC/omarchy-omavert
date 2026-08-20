import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Formats.js" as Formats

// The VERT converter panel. A file is picked with the desktop-portal chooser,
// classified by extension, and handed to the engine VERT uses for that
// family (ImageMagick / FFmpeg / Pandoc) through convert.sh. Results land
// in ~/Downloads (or the outputDir setting).
Panel {
  id: root
  moduleName: "io.github.tmartinppc.vert"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property color foreground: bar ? bar.barForeground : Color.foreground
  readonly property color accent: Color.accent
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.5)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property string scriptPath: root.pathFromUrl(Qt.resolvedUrl("convert.sh"))
  readonly property string outputDir: {
    var d = String(root.setting("outputDir", "")).trim()
    return d !== "" ? d : (root.home !== "" ? root.home + "/Downloads" : "/tmp")
  }

  property string inputPath: ""
  property string category: ""
  property var formatOptions: []
  property string targetExt: ""
  property bool busy: false
  property string errorText: ""
  property string outputPath: ""

  function open() {
    root.controller.show()
    Qt.callLater(function() { if (keyCatcher) keyCatcher.forceActiveFocus() })
  }

  function close() { root.controller.hide() }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.hostWidget || root, direction)
    return false
  }

  function basename(p) {
    var s = String(p || "")
    var i = s.lastIndexOf("/")
    return i >= 0 ? s.slice(i + 1) : s
  }

  function extension(p) {
    var s = String(p || "")
    var dot = s.lastIndexOf(".")
    var slash = s.lastIndexOf("/")
    return dot > slash ? s.slice(dot + 1) : ""
  }

  function pathFromUrl(url) {
    var s = String(url || "")
    if (s.indexOf("file://") === 0) {
      s = s.slice(7)
      if (s.charAt(0) !== "/") {
        var i = s.indexOf("/")
        s = i < 0 ? ("/" + s) : s.slice(i)
      }
    }
    return decodeURIComponent(s)
  }

  function acceptFile(path) {
    root.inputPath = path
    root.outputPath = ""
    root.errorText = ""
    root.category = Formats.classify(root.extension(path))
    root.formatOptions = Formats.targets(root.category)
    root.targetExt = root.formatOptions.length > 0 ? root.formatOptions[0].value : ""
  }

  function chooseFile() {
    if (selectProc.running) return
    root.errorText = ""
    selectProc.running = false
    selectProc.command = ["omarchy-file-select", "--title", "Choose a file to convert"]
    selectProc.running = true
  }

  function startConvert() {
    if (!root.canConvert()) return
    root.busy = true
    root.errorText = ""
    root.outputPath = ""
    convertProc.running = false
    convertProc.command = ["bash", root.scriptPath, Formats.engine(root.category), root.inputPath, root.targetExt, root.outputDir]
    convertProc.running = true
  }

  function canConvert() {
    return !root.busy && root.inputPath !== "" && root.category !== "" && root.targetExt !== ""
  }

  function openOutput() {
    if (root.outputPath !== "") Quickshell.execDetached(["xdg-open", root.outputPath])
  }

  function revealOutput() {
    Quickshell.execDetached(["xdg-open", root.outputDir])
  }
  // Clear everything so the panel is ready for the next conversion.
  function reset() {
    root.inputPath = ""
    root.category = ""
    root.formatOptions = []
    root.targetExt = ""
    root.errorText = ""
    root.outputPath = ""
  }


  // ------------------------------------------------------------------ picker

  Process {
    id: selectProc
    running: false
    command: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var lines = String(text || "").split("\n")
        for (var i = 0; i < lines.length; i++) {
          var p = lines[i].trim()
          if (p !== "") { root.acceptFile(p); break }
        }
      }
    }
  }

  // ----------------------------------------------------------------- convert

  Process {
    id: convertProc
    running: false
    command: []
    stdout: StdioCollector { id: convertStdout; waitForEnd: true }
    stderr: StdioCollector { id: convertStderr; waitForEnd: true }
    onExited: function(exitCode) {
      root.busy = false
      if (exitCode === 0) {
        var p = String(convertStdout.text || "").trim()
        if (p === "") root.errorText = "Conversion finished without producing a file."
        else root.outputPath = p
      } else {
        root.errorText = String(convertStderr.text || "").trim() || ("Conversion failed (exit " + exitCode + ").")
      }
    }
  }

  // ------------------------------------------------------------------ panel

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(300))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: content
        width: parent.width
        spacing: Style.space(8)

        PanelHero {
          width: parent.width
          title: "VERT"
          meta: root.category !== ""
            ? Formats.categoryLabel(root.category) + " converter"
            : "local file converter"
          detail: root.category !== "" ? Formats.categoryLabel(root.category).toUpperCase() : "ON-DEVICE"

          iconComponent: Component {
            Text {
              text: "󰿺"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.display
            }
          }
        }

        PanelSectionHeader {
          text: "SOURCE"
          foreground: root.foreground
          fontFamily: root.fontFamily
        }

        BorderSurface {
          id: fileStatus
          width: parent.width
          height: Style.space(72)
          radius: Style.cornerRadius
          color: Style.controlFill(false, false, root.foreground, root.accent)
          borderSpec: Border.controlSpec("normal", root.foreground, root.accent)

          Column {
            anchors.centerIn: parent
            width: parent.width - Style.space(32)
            spacing: Style.space(2)

            Text {
              width: parent.width
              horizontalAlignment: Text.AlignHCenter
              text: root.inputPath !== "" ? root.basename(root.inputPath) : "No file selected"
              elide: Text.ElideMiddle
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
            }

            Text {
              width: parent.width
              horizontalAlignment: Text.AlignHCenter
              visible: root.inputPath !== ""
              text: root.category !== "" ? Formats.categoryLabel(root.category) : "Unsupported type"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
          }
        }

        Button {
          width: parent.width
          bordered: true
          text: root.inputPath !== "" ? "Choose a different file…" : "Choose file…"
          onClicked: root.chooseFile()
        }

        PanelSectionHeader {
          visible: root.inputPath !== ""
          text: "FORMAT"
          foreground: root.foreground
          fontFamily: root.fontFamily
        }

        Dropdown {
          id: formatDropdown
          width: parent.width
          visible: root.inputPath !== "" && !root.busy
          label: "Convert to"
          value: root.targetExt
          options: root.formatOptions
          onChanged: function(v) { root.targetExt = v; root.errorText = "" }
        }

        Text {
          width: parent.width
          visible: root.inputPath !== "" && root.category === ""
          text: "This file type isn't supported yet."
          color: root.urgent
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          wrapMode: Text.WordWrap
        }

        Button {
          id: convertButton
          width: parent.width
          bordered: true
          opacity: root.canConvert() ? 1 : 0.45
          text: root.busy ? "Converting…" : "Convert"
          active: root.busy
          onClicked: root.startConvert()
        }

        Text {
          width: parent.width
          visible: root.errorText !== ""
          text: root.errorText
          color: root.urgent
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          wrapMode: Text.WordWrap
        }

        Column {
          width: parent.width
          visible: root.outputPath !== ""
          spacing: Style.space(6)

          PanelSectionHeader {
            width: parent.width
            text: "SAVED"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          Text {
            width: parent.width
            text: root.outputPath
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            wrapMode: Text.WrapAnywhere
          }

          Row {
            spacing: Style.space(8)

            Button {
              bordered: true
              text: "Open"
              onClicked: root.openOutput()
            }

            Button {
              bordered: true
              text: "Show folder"
              onClicked: root.revealOutput()
            }
          }
        }

        Item {
          width: parent.width
          height: resetButton.implicitHeight

          PanelActionButton {
            id: resetButton
            anchors.right: parent.right
            iconText: "󰑐"
            tooltipText: "Reset converter"
            fontFamily: root.fontFamily
            enabled: !root.busy
            onClicked: root.reset()
          }
        }
      }
    }
  }
}
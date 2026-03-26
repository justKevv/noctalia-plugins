import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property var mainInstance: pluginApi?.mainInstance

  readonly property var geometryPlaceholder: panelContainer
  readonly property bool allowAttach: true

  property real contentPreferredWidth: 400 * Style.uiScaleRatio
  property real contentPreferredHeight: 300 * Style.uiScaleRatio

  property string selectedSource: ""
  property string selectedDestination: ""
  readonly property bool sameSelection: selectedSource && selectedDestination && selectedSource === selectedDestination
  readonly property var sourceModel: Quickshell.screens.filter(screen => screen.name !== selectedDestination).map(screen => ({ key: screen.name, name: screen.name }))
  readonly property var destinationModel: Quickshell.screens.filter(screen => screen.name !== selectedSource).map(screen => ({ key: screen.name, name: screen.name }))
  readonly property bool hasEnoughMonitors: Quickshell.screens.length >= 2
  readonly property bool controlsLocked: !hasEnoughMonitors

  anchors.fill: parent

  Component.onCompleted: {
    if (Quickshell.screens.length > 0) {
      selectedSource = Quickshell.screens[0].name;
      selectedDestination = Quickshell.screens.length > 1 ? Quickshell.screens[1].name : Quickshell.screens[0].name;
    }
  }
  onVisibleChanged: {
    if (visible && Quickshell.screens.length > 0) {
      if (!selectedSource || !Quickshell.screens.some(screen => screen.name === selectedSource)) {
        selectedSource = Quickshell.screens[0].name;
      }
      if (!selectedDestination || !Quickshell.screens.some(screen => screen.name === selectedDestination) || selectedDestination === selectedSource) {
        selectedDestination = Quickshell.screens.length > 1 ? Quickshell.screens[1].name : Quickshell.screens[0].name;
      }
    }
  }

  function startMirror() {
    if (!selectedSource || !selectedDestination || selectedSource === selectedDestination) {
      return;
    }
    mainInstance?.startMirror(selectedSource, selectedDestination);
  }

  function stopMirror() {
    mainInstance?.stopMirror();
  }

  function ensureDifferentSelection() {
    if (!sameSelection && Quickshell.screens.length >= 2) return;
    for (let i = 0; i < Quickshell.screens.length; i++) {
      const screen = Quickshell.screens[i];
      if (screen.name !== selectedSource) {
        selectedDestination = screen.name;
        return;
      }
    }
  }
  onSelectedSourceChanged: ensureDifferentSelection()
  onSelectedDestinationChanged: ensureDifferentSelection()



  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
      anchors {
        fill: parent
        margins: Style.marginL
      }
      spacing: Style.marginM


      NText {
        Layout.fillWidth: true
        text: pluginApi?.tr("panel.title")
        pointSize: Style.fontSizeL
        font.weight: Font.DemiBold
        color: Color.mOnSurface
      }

      NText {
        Layout.fillWidth: true
        text: pluginApi?.tr("panel.subtitle")
        pointSize: Style.fontSizeS
        color: Color.mOnSurfaceVariant
        wrapMode: Text.WordWrap
      }


      NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("panel.source.label")
        description: pluginApi?.tr("panel.source.description")
        model: root.sourceModel
        currentKey: root.selectedSource
        enabled: !(mainInstance?.mirroringActive ?? false) && !root.controlsLocked
        onSelected: key => selectedSource = key
      }

      NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("panel.destination.label")
        description: pluginApi?.tr("panel.destination.description")
        model: root.destinationModel
        currentKey: root.selectedDestination
        enabled: !(mainInstance?.mirroringActive ?? false) && !root.controlsLocked
        onSelected: key => selectedDestination = key
      }

      NText {
        Layout.fillWidth: true
        visible: root.sameSelection
        text: pluginApi?.tr("panel.validation.sameSelection")
        pointSize: Style.fontSizeS
        color: Color.mError
      }

      NText {
        Layout.fillWidth: true
        visible: !root.hasEnoughMonitors
        text: pluginApi?.tr("panel.validation.needTwoMonitors")
        pointSize: Style.fontSizeS
        color: Color.mError
      }

      // No discoveryError needed with Quickshell.screens

      NText {
        Layout.fillWidth: true
        visible: (mainInstance?.lastError ?? "") !== ""
        text: mainInstance?.lastError ?? ""
        pointSize: Style.fontSizeS
        color: Color.mError
        wrapMode: Text.WordWrap
      }


      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NButton {
          Layout.fillWidth: true
          text: pluginApi?.tr("panel.actions.start")
          icon: "media-play"
          backgroundColor: Color.mPrimary
          textColor: Color.mOnPrimary
          enabled: !(mainInstance?.mirroringActive ?? false)
              && !root.controlsLocked
              && root.selectedSource !== ""
              && root.selectedDestination !== ""
              && !root.sameSelection
          onClicked: root.startMirror()
        }
      }

      NButton {
        Layout.fillWidth: true
        visible: mainInstance?.mirroringActive ?? false
        text: pluginApi?.tr("panel.actions.stop")
        icon: "stop"
        backgroundColor: Color.mError
        textColor: Color.mOnError
        enabled: true
        onClicked: root.stopMirror()
      }
    }
  }
}

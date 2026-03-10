import QtQuick 2.15

import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

NIconButton {
    id: root
    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""

    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    readonly property string iconColorKey: cfg.iconColor ?? defaults.iconColor

    icon: "coin"
    tooltipText: pluginApi?.tr("widget.tooltip")
    tooltipDirection: BarService.getTooltipDirection(screen?.name)
    baseSize: Style.getCapsuleHeightForScreen(screen?.name)
    applyUiScale: false
    colorFg: Color.resolveColorKey(iconColorKey)
    customRadius: Style.radiusL
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    // центр трансформации (чтобы масштаб происходил из центра кнопки)
    transformOrigin: Item.Center

    // Анимация масштаба через Behavior на свойстве scale (надёжно)
    Behavior on scale {
        NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
    }

    onClicked: {
        // подпрыгивание: увеличиваем scale, затем таймер вернёт обратно
        root.scale = 1.25
        bounceBack.start()

        // бросок монетки
        var result = Math.random() < 0.5 ? pluginApi?.tr("common.heads") : pluginApi?.tr("common.tails")
        if (pluginApi) {
            pluginApi.pluginSettings.lastResult = result
            pluginApi.saveSettings()
        }

        ToastService.showNotice(result)
    }

    Timer {
        id: bounceBack
        interval: 150
        running: false
        repeat: false
        onTriggered: {
            root.scale = 1.0
        }
    }

    NPopupContextMenu {
        id: contextMenu
        model: [
            { "label": pluginApi?.tr("menu.settings"), "action": "settings", "icon": "settings" },
        ]
        onTriggered: function(action) {
            contextMenu.close();
            PanelService.closeContextMenu(screen);
            if (action === "settings") {
                BarService.openPluginSettings(screen, pluginApi.manifest);
            }
        }
    }

    onRightClicked: {
        PanelService.showContextMenu(contextMenu, root, screen);
    }
}
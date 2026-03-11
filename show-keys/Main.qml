import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: root
    property var pluginApi: null

    // ── Settings (reactive, with defaults) ───────────────
    property var cfg: pluginApi?.pluginSettings || ({})
    property var def: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    property bool captureEnabled: cfg.captureEnabled ?? def.captureEnabled ?? true
    readonly property string evtestDevice: cfg.evtestDevice || def.evtestDevice || "/dev/input/event3"
    readonly property string pillColor:    cfg.pillColor   || def.pillColor   || "#ffffff"
    readonly property string pillBg:       cfg.pillBg      || def.pillBg      || "#000000"
    readonly property string position:     cfg.position    || def.position    || "bottom"
    readonly property int    marginPx:     cfg.marginPx    ?? def.marginPx    ?? 60
    readonly property int    hideDelaySec: cfg.hideDelaySec ?? def.hideDelaySec ?? 2

    // ── State ────────────────────────────────────────────
    property var  keyList: []
    property bool shiftHeld: false
    property bool ctrlHeld:  false
    property bool altHeld:   false
    property bool metaHeld:  false
    readonly property int maxKeys: 12

    // Build modifier prefix from held state
    readonly property string modPrefix: {
        var p = "";
        if (metaHeld)  p += "󰴈 +";
        if (ctrlHeld)  p += "CTRL+";
        if (altHeld)   p += "ALT+";
        return p;
    }

    // ── evtest process ───────────────────────────────────
    Process {
        id: evtest
        command: ["evtest", root.evtestDevice]
        running: root.captureEnabled

        stdout: SplitParser {
            onRead: data => root.handleLine(data)
        }

        onExited: (code, status) => {
            if (root.captureEnabled)
                Qt.callLater(() => evtest.running = true);
        }
    }

    // ── IPC handler (toggle via keybinding) ──────────────
    IpcHandler {
        target: "plugin:show-keys"

        function toggle(): void {
            root.captureEnabled = !root.captureEnabled;
            if (pluginApi) {
                pluginApi.pluginSettings.captureEnabled = root.captureEnabled;
                pluginApi.saveSettings();
            }
        }
    }

    // ── Event parsing ────────────────────────────────────
    function handleLine(line) {
        if (line.indexOf("type 1 (EV_KEY)") === -1) return;

        var m = line.match(/\(KEY_([^)]+)\).*value (\d+)/);
        if (!m) return;

        var keycode = m[1];
        var value   = parseInt(m[2]);
        if (value === 2) return;          // ignore repeat

        // Modifier tracking
        if (/SHIFT$/.test(keycode))  { shiftHeld = (value === 1); return; }
        if (/CTRL$/.test(keycode))   { ctrlHeld  = (value === 1); return; }
        if (/ALT$/.test(keycode))    { altHeld   = (value === 1); return; }
        if (/META$/.test(keycode))   { metaHeld  = (value === 1); return; }

        if (value !== 0) return;          // only emit on key release

        var label = keyLabel(keycode);
        if (label === "") return;

        var display = modPrefix + label;
        var list = keyList.slice();
        if (list.length >= maxKeys) list = [];
        list.push(display);
        keyList = list;

        osdWindow.visible = true;
        osdContent.opacity = 1;
        hideTimer.restart();
    }

    // ── Key label (case-aware) ───────────────────────────
    // Normal / Shifted symbol pairs
    readonly property var shiftMap: ({
        "1":"!",  "2":"@",  "3":"#",  "4":"$",  "5":"%",
        "6":"^",  "7":"&",  "8":"*",  "9":"(",  "0":")",
        "MINUS":"_",       "EQUAL":"+",
        "LEFTBRACE":"{",   "RIGHTBRACE":"}",
        "SEMICOLON":":",   "APOSTROPHE":"\"",
        "GRAVE":"~",       "BACKSLASH":"|",
        "COMMA":"<",       "DOT":">",  "SLASH":"?"
    })

    readonly property var normalMap: ({
        "MINUS":"-",       "EQUAL":"=",
        "LEFTBRACE":"[",   "RIGHTBRACE":"]",
        "SEMICOLON":";",   "APOSTROPHE":"'",
        "GRAVE":"`",       "BACKSLASH":"\\",
        "COMMA":",",       "DOT":".",  "SLASH":"/"
    })

    readonly property var specialMap: ({
        "BACKSPACE":"󰁮",  "ENTER":"󰌑",   "ESC":"󱊷",
        "SPACE":"󱁐",      "TAB":"󰌒",     "DELETE":"󰆴",
        "UP":"↑",         "DOWN":"↓",    "LEFT":"←",   "RIGHT":"→",
        "HOME":"Home",    "END":"End",
        "PAGEUP":"PgUp",  "PAGEDOWN":"PgDn",
        "INSERT":"Ins",   "CAPSLOCK":"Caps",
        "NUMLOCK":"Num",  "SCROLLLOCK":"Scr",
        "SYSRQ":"PrtSc",  "PAUSE":"Pause"
    })

    function keyLabel(k) {
        // Special keys (icons, unaffected by shift)
        if (specialMap[k] !== undefined) return specialMap[k];
        // F-keys
        if (/^F\d+$/.test(k)) return k;
        // KP keys
        if (k.indexOf("KP") === 0) return k;

        // Single alpha → case-aware
        if (/^[A-Z]$/.test(k))
            return shiftHeld ? k : k.toLowerCase();

        // Digit keys
        if (/^\d$/.test(k))
            return shiftHeld ? (shiftMap[k] || k) : k;

        // Symbol keys
        if (shiftHeld && shiftMap[k] !== undefined) return shiftMap[k];
        if (normalMap[k] !== undefined) return normalMap[k];

        return k;
    }

    // ── OSD Window ───────────────────────────────────────
    PanelWindow {
        id: osdWindow
        visible: false
        color: "transparent"

        anchors {
            top:    root.position === "top"
            bottom: root.position !== "top"
            left: true
            right: true
        }
        margins.top:    root.position === "top"  ? root.marginPx : 0
        margins.bottom: root.position !== "top"  ? root.marginPx : 0

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "show-keys-osd"
        implicitHeight: 52

        Item {
            id: osdContent
            anchors.fill: parent
            opacity: 0

            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
            }

            Row {
                anchors.centerIn: parent
                spacing: 6

                Repeater {
                    model: root.keyList

                    Rectangle {
                        width: pillText.implicitWidth + 20
                        height: 36
                        radius: 8
                        color: Qt.alpha(root.pillBg, 0.8)
                        border.color: Qt.alpha(root.pillColor, 0.27)
                        border.width: 1

                        Text {
                            id: pillText
                            anchors.centerIn: parent
                            text: modelData
                            color: root.pillColor
                            font.pixelSize: 16
                            font.family: "monospace"
                            font.bold: true
                        }

                        scale: 0.7
                        Component.onCompleted: scale = 1.0
                        Behavior on scale {
                            NumberAnimation { duration: 120; easing.type: Easing.OutBack }
                        }
                    }
                }
            }
        }

        Timer {
            id: hideTimer
            interval: root.hideDelaySec * 1000
            onTriggered: {
                osdContent.opacity = 0;
                clearTimer.start();
            }
        }

        Timer {
            id: clearTimer
            interval: 250
            onTriggered: {
                osdWindow.visible = false;
                root.keyList = [];
            }
        }
    }
}

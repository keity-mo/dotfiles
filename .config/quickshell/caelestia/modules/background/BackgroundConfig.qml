import Quickshell.Io

JsonObject {
    property bool enabled: true
    property bool wallpaperEnabled: true
    property DesktopClock desktopClock: DesktopClock {}
    property Visualiser visualiser: Visualiser {}

    component DesktopClock: JsonObject {
        property bool enabled: true
        property string position: "top-left"
    }

    component Visualiser: JsonObject {
        property bool enabled: true
        property bool autoHide: false
        property real rounding: 1
        property real spacing: 1
    }
}
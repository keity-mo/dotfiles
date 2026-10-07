
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../../common"
import "../../common/widgets"

Item {
    id: root

    property var toplevel
    property var windowData
    property var monitorData
    property var widgetMonitorData
    property int widgetMonitorId: 0
    property real previewScale: 0.16
    property real sizeFactor: 1
    property real availableWidth: 100
    property real availableHeight: 100
    property real xOffset: 0
    property real yOffset: 0
    property real baseZ: 10
    property bool placed: true
    property bool hiddenByFullscreen: false
    property int recaptureToken: 0
    property real cornerRadius: 6

    signal focusRequested()
    signal closeRequested()
    signal dragStarted()
    signal dragFinished()

    property bool pressed: false
    property bool dragInProgress: false
    property bool initialized: false
    property bool previewCaptureEnabled: true
    readonly property bool hovered: hoverHandler.hovered && !dragInProgress
    readonly property bool isFocused: toplevel?.activated ?? false

    readonly property bool showIcons: Config.options.windowPreview.showIcons
    readonly property bool cropToFill: Config.options.windowPreview.cropToFill
    readonly property bool previewsEnabled: Config.options.overview.previewsEnabled
    readonly property bool includeInactive: Config.options.overview.includeInactiveMonitorPreviews
    readonly property string previewMode: `${Config.options.overview.previewMode}`.trim().toLowerCase()
    readonly property bool livePreview: previewsEnabled && !(previewMode === "event" || previewMode === "snapshot")
    readonly property bool onWidgetMonitor: (windowData?.monitor ?? -1) === widgetMonitorId

    readonly property real widthRatio: {
        if (!widgetMonitorData || !monitorData)
            return 1;
        const ww = (widgetMonitorData.transform % 2 === 1) ? widgetMonitorData.height : widgetMonitorData.width;
        const sw = (monitorData.transform % 2 === 1) ? monitorData.height : monitorData.width;
        return ((ww * (monitorData.scale ?? 1)) / (sw * (widgetMonitorData.scale ?? 1))) || 1;
    }
    readonly property real heightRatio: {
        if (!widgetMonitorData || !monitorData)
            return 1;
        const wh = (widgetMonitorData.transform % 2 === 1) ? widgetMonitorData.width : widgetMonitorData.height;
        const sh = (monitorData.transform % 2 === 1) ? monitorData.width : monitorData.height;
        return ((wh * (monitorData.scale ?? 1)) / (sh * (widgetMonitorData.scale ?? 1))) || 1;
    }
    readonly property real kx: previewScale * widthRatio * sizeFactor
    readonly property real ky: previewScale * heightRatio * sizeFactor
    readonly property real baseX: (monitorData?.x ?? 0) + (monitorData?.reserved?.[0] ?? 0)
    readonly property real baseY: (monitorData?.y ?? 0) + (monitorData?.reserved?.[1] ?? 0)
    readonly property real targetW: (windowData?.size?.[0] ?? 100) * kx
    readonly property real targetH: (windowData?.size?.[1] ?? 100) * ky
    readonly property real initX: Math.round(Math.max(((windowData?.at?.[0] ?? 0) - baseX) * kx, 0) + xOffset)
    readonly property real initY: Math.round(Math.max(((windowData?.at?.[1] ?? 0) - baseY) * ky, 0) + yOffset)

    readonly property bool compact: Appearance.font.pixelSize.smaller * 4 > targetH || Appearance.font.pixelSize.smaller * 4 > targetW
    readonly property var entry: {
        const appClass = `${windowData?.class ?? ""}`.trim().toLowerCase();
        if (appClass === "sonora")
            return null;
        DesktopEntries.applications.values;
        return DesktopEntries.heuristicLookup(windowData?.class);
    }
    readonly property string iconName: {
        const raw = `${entry?.icon ?? ""}`.trim();
        const noPrefix = raw.replace(/^image:/ + "/icon/", "");
        const noQuery = noPrefix.split("?")[0].trim();
        return noQuery.length > 0 ? noQuery : "application-x-executable";
    }
    readonly property string iconPath: iconName === "sonora" ? `file://${Quickshell.env("HOME")}/.local/share/icons/sonora.png` : Quickshell.iconPath(iconName, true)

    readonly property bool isFullscreen: (windowData?.fullscreen ?? 0) > 0
    visible: placed && (isFullscreen || !hiddenByFullscreen)
    width: Math.max(1, Math.round(Math.min(targetW, availableWidth)))
    height: Math.max(1, Math.round(Math.min(targetH, availableHeight)))
    z: dragInProgress ? 100000 : baseZ
    clip: true
    opacity: dragInProgress ? 0.92 : (onWidgetMonitor ? 1 : Config.options.windowPreview.inactiveMonitorOpacity)
    scale: dragInProgress ? 1.05 : pressed ? 0.97 : hovered ? 1.02 : 1

    // El binding se pausa mientras se arrastra y se restaura al soltar:
    // la ventana vuelve (o se mueve) sin timers ni carreras
    Binding { target: root; property: "x"; value: root.initX; when: !root.dragInProgress; restoreMode: Binding.RestoreNone }
    Binding { target: root; property: "y"; value: root.initY; when: !root.dragInProgress; restoreMode: Binding.RestoreNone }

    Behavior on x {
        enabled: root.initialized && !root.dragInProgress
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }
    Behavior on y {
        enabled: root.initialized && !root.dragInProgress
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }
    Behavior on width {
        enabled: root.initialized && !root.dragInProgress
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Behavior on height {
        enabled: root.initialized && !root.dragInProgress
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Behavior on scale {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    Component.onCompleted: Qt.callLater(() => root.initialized = true)

    // Fondo opaco para ventanas del monitor activo (evita ver el blur de lo que hay detras)
    Rectangle {
        visible: root.onWidgetMonitor
        anchors.fill: parent
        radius: root.cornerRadius
        color: Appearance.m3colors.m3surfaceContainerHigh
    }

    ScreencopyView {
        id: preview
        readonly property real srcAspect: {
            const w = root.windowData?.size?.[0] ?? 0;
            const h = root.windowData?.size?.[1] ?? 0;
            return (w > 0 && h > 0) ? (w / h) : 1;
        }
        anchors.centerIn: parent
        width: root.cropToFill ? Math.max(parent.width, parent.height * srcAspect) : Math.min(parent.width, parent.height * srcAspect)
        height: root.cropToFill ? Math.max(parent.height, parent.width / srcAspect) : Math.min(parent.height, parent.width / srcAspect)
        captureSource: (root.previewsEnabled && root.previewCaptureEnabled && (root.includeInactive || root.onWidgetMonitor)) ? root.toplevel : null
        live: root.livePreview
        layer.enabled: hasContent
        layer.smooth: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: previewMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }
    }

    Item {
        id: previewMask
        width: preview.width
        height: preview.height
        anchors.centerIn: parent
        visible: false
        layer.enabled: true
        layer.smooth: true
        Rectangle {
            anchors.centerIn: parent
            width: root.width
            height: root.height
            radius: root.cornerRadius
        }
    }

    // Tinte de hover y pressed
    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: Qt.alpha(Appearance.colors.colPrimary, root.pressed ? 0.22 : root.hovered ? 0.12 : 0)
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    // Icono: centrado si no hay captura, como insignia inferior si la hay
    Rectangle {
        id: badge
        visible: root.showIcons && Math.min(root.width, root.height) >= 22
        readonly property real iconSize: Math.max(16, Math.min(56, Math.round(Math.min(root.width, root.height) * (root.compact ? Config.options.windowPreview.iconToWindowRatioCompact : Config.options.windowPreview.iconToWindowRatio))))
        readonly property bool asBadge: preview.hasContent && Math.min(root.width, root.height) >= 48
        width: iconSize + (asBadge ? 8 : 0)
        height: width
        radius: width / 2
        x: Math.round((root.width - width) / 2)
        y: Math.round(asBadge ? root.height - height - 6 : (root.height - height) / 2)
        color: asBadge ? Qt.alpha(Appearance.m3colors.m3surfaceContainerHigh, 0.82) : "transparent"
        border.width: asBadge ? 1 : 0
        border.color: Qt.alpha(Appearance.m3colors.m3outlineVariant, 0.55)
        Image {
            anchors.centerIn: parent
            width: badge.iconSize
            height: badge.iconSize
            source: root.iconPath
            sourceSize: Qt.size(badge.iconSize * 2, badge.iconSize * 2)
            smooth: true
            mipmap: true
            asynchronous: true
        }
    }

    // Borde en capa superior: normal, enfocada y hover
    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: "transparent"
        antialiasing: true
        border.width: (root.hovered || root.isFocused) ? 2 : 1
        border.color: root.hovered ? Appearance.colors.colPrimary
                    : root.isFocused ? Qt.alpha(Appearance.colors.colPrimary, 0.8)
                    : Qt.alpha(Appearance.m3colors.m3outline, 0.35)
        Behavior on border.color { ColorAnimation { duration: 120 } }
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: root.dragInProgress ? Qt.ClosedHandCursor : Qt.PointingHandCursor
        drag.threshold: 8
        onPressed: mouse => {
            drag.target = mouse.button === Qt.LeftButton ? root : null;
            root.pressed = true;
            root.Drag.source = root;
            root.Drag.hotSpot.x = mouse.x;
            root.Drag.hotSpot.y = mouse.y;
        }
        onReleased: root.pressed = false
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton)
                root.focusRequested();
            else if (mouse.button === Qt.MiddleButton)
                root.closeRequested();
        }
        drag.onActiveChanged: {
            if (drag.active) {
                root.dragInProgress = true;
                root.Drag.active = true;
                root.dragStarted();
            } else if (root.dragInProgress) {
                // Primero se avisa (el destino sigue vigente) y luego se suelta
                root.dragFinished();
                root.Drag.active = false;
                root.dragInProgress = false;
            }
        }
    }

    Rectangle {
        id: closeButton
        readonly property bool shown: root.hovered && root.width >= 56 && root.height >= 40
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 5
        width: 22
        height: 22
        radius: 11
        opacity: shown ? 1 : 0
        scale: shown ? 1 : 0.7
        visible: opacity > 0.01
        color: closeArea.containsMouse ? Appearance.colors.colError : Qt.alpha(Appearance.m3colors.m3surfaceContainerHigh, 0.92)
        Behavior on opacity { NumberAnimation { duration: 120 } }
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        border.width: 1
        border.color: closeArea.containsMouse ? Qt.alpha(Appearance.colors.colError, 0.8) : Qt.alpha(Appearance.colors.colPrimary, 0.28)
        Behavior on color { ColorAnimation { duration: 100 } }
        Behavior on border.color { ColorAnimation { duration: 100 } }
        Text {
            anchors.centerIn: parent
            text: "close"
            font.family: Appearance.font.family.material
            font.pixelSize: 14
            color: closeArea.containsMouse ? Appearance.colors.colOnError : Appearance.colors.colOnLayer0
        }
        MouseArea {
            id: closeArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            onClicked: root.closeRequested()
        }
    }

    HoverHandler { id: hoverHandler }

    StyledToolTip {
        extraVisibleCondition: false
        alternativeVisibleCondition: root.hovered
        text: `${root.windowData?.title ?? "Unknown"}${String.fromCharCode(10)}[${root.windowData?.class ?? "unknown"}] ${root.windowData?.xwayland ? "[XWayland] " : ""}`
    }

    function refreshCapture() {
        if (livePreview || !previewsEnabled)
            return;
        previewCaptureEnabled = false;
        previewResetTimer.restart();
    }

    Timer {
        id: previewResetTimer
        interval: Math.max(1, Config.options.overview.previewRecaptureDelayMs)
        onTriggered: root.previewCaptureEnabled = true
    }

    onRecaptureTokenChanged: {
        if (recaptureToken > 0)
            refreshCapture();
    }
}


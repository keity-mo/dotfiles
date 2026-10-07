
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../common"
import "../../services"
import "."

Scope {
    id: overviewScope

    Connections {
        target: GlobalStates
        function onOverviewOpenChanged() {
            if (GlobalStates.overviewOpen)
                Appearance.reloadScheme();
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root
            required property var modelData
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
            readonly property bool monitorIsFocused: Hyprland.focusedMonitor?.id === monitor?.id
            readonly property bool blurEnabled: Config.options.overview.effects.enableBlur
            readonly property bool closeOnFocusLoss: Config.options.overview.closeOnFocusLoss
            readonly property bool showing: GlobalStates.overviewOpen

            // 0 = cerrado, 1 = abierto. La ventana sigue visible mientras se anima la salida
            property real progress: showing ? 1 : 0
            Behavior on progress {
                NumberAnimation {
                    duration: root.showing ? Appearance.animation.elementMoveEnter.duration : Math.round(Appearance.animation.elementMoveExit.duration * 1.6)
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.showing ? Appearance.animationCurves.emphasizedDecel : Appearance.animationCurves.expressiveEffects
                }
            }

            screen: modelData
            visible: showing || progress > 0.001
            color: "transparent"

            WlrLayershell.namespace: Config.read("overview.effects.namespace", blurEnabled ? "quickshell:overview-blur" : "quickshell:overview")
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            HyprlandFocusGrab {
                id: grab
                windows: [root]
                property bool canBeActive: root.monitorIsFocused
                active: false
                onCleared: () => {
                    if (root.closeOnFocusLoss && !active && canBeActive)
                        GlobalStates.overviewOpen = false;
                }
            }

            Connections {
                target: GlobalStates
                function onOverviewOpenChanged() {
                    if (GlobalStates.overviewOpen)
                        grabTimer.start();
                    else
                        grab.active = false;
                }
            }

            Connections {
                target: Hyprland
                function onFocusedMonitorChanged() {
                    if (!GlobalStates.overviewOpen)
                        return;
                    if (root.monitorIsFocused && !grab.active)
                        grab.active = true;
                    else if (!root.monitorIsFocused && grab.active)
                        grab.active = false;
                }
            }

            Timer {
                id: grabTimer
                interval: Config.options.hacks.arbitraryRaceConditionDelay
                onTriggered: {
                    if (grab.canBeActive)
                        grab.active = GlobalStates.overviewOpen;
                }
            }

            Item {
                id: keyHandler
                anchors.fill: parent
                focus: root.showing

                Rectangle {
                    anchors.fill: parent
                    visible: Config.options.overview.effects.enableBackdrop
                    color: Appearance.colors.colScrim
                    opacity: Math.max(0, Math.min(1, Config.options.overview.effects.backdropOpacity)) * root.progress
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    enabled: root.closeOnFocusLoss && root.showing
                    onPressed: mouse => {
                        GlobalStates.overviewOpen = false;
                        mouse.accepted = true;
                    }
                }

                Keys.onPressed: event => {
                    const key = event.key;
                    if (key === Qt.Key_Escape || key === Qt.Key_Return || key === Qt.Key_Enter) {
                        GlobalStates.overviewOpen = false;
                        event.accepted = true;
                        return;
                    }
                    const w = contentLoader.item;
                    if (!w)
                        return;
                    let handled = true;
                    switch (key) {
                    case Qt.Key_Left:
                    case Qt.Key_H:
                        w.navigate(0, -1);
                        break;
                    case Qt.Key_Right:
                    case Qt.Key_L:
                        w.navigate(0, 1);
                        break;
                    case Qt.Key_Up:
                    case Qt.Key_K:
                        w.navigate(-1, 0);
                        break;
                    case Qt.Key_Down:
                    case Qt.Key_J:
                        w.navigate(1, 0);
                        break;
                    case Qt.Key_Tab:
                        w.stepWorkspace(1);
                        break;
                    case Qt.Key_Backtab:
                        w.stepWorkspace(-1);
                        break;
                    default:
                        if (key >= Qt.Key_1 && key <= Qt.Key_9)
                            handled = w.jumpTo(key - Qt.Key_0);
                        else if (key === Qt.Key_0)
                            handled = w.jumpTo(10);
                        else
                            handled = false;
                    }
                    event.accepted = handled;
                }

                // El contenido solo existe mientras el overview es visible
                Loader {
                    id: contentLoader
                    active: root.visible && Config.options.overview.enable
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: Config.options.position.topMargin
                    sourceComponent: OverviewWidget {
                        panelWindow: root
                        progress: root.progress
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "overview"

        function toggle() {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
        function close() {
            GlobalStates.overviewOpen = false;
        }
        function open() {
            GlobalStates.overviewOpen = true;
        }
    }
}


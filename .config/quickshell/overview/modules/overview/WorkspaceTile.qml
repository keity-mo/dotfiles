import QtQuick
import QtQuick.Effects
import "../../common"

Item {
    id: root

    property string label: ""
    property string icon: ""
    property bool active: false
    property bool special: false
    property bool dropHover: false
    property string wallpaper: ""
    property real radius: 10
    property real numberSize: 40
    property real iconSize: 28

    readonly property bool hovered: hoverHandler.hovered

    signal clicked()
    signal dragEntered()
    signal dragExited()

    readonly property color baseColor: special ? Appearance.m3colors.m3surfaceContainerHigh : Appearance.m3colors.m3surfaceContainer

    Rectangle {
        id: fill
        anchors.fill: parent
        radius: root.radius
        antialiasing: true
        color: root.dropHover ? Qt.alpha(Appearance.colors.colPrimary, 0.28)
             : root.active ? Qt.tint(Qt.alpha(root.baseColor, Appearance.tileAlpha), Qt.alpha(Appearance.colors.colPrimary, 0.16))
             : root.icon === "add" ? Qt.alpha(root.baseColor, root.hovered ? 0.48 : 0.22)
             : Qt.alpha(root.baseColor, Appearance.tileAlpha)
        Behavior on color { ColorAnimation { duration: Appearance.animation.elementMoveFast.duration } }
    }

    Loader {
        anchors.fill: parent
        active: root.wallpaper.length > 0
        sourceComponent: Item {
            Image {
                anchors.fill: parent
                source: root.wallpaper
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                smooth: true
                sourceSize.width: Math.round(root.width * 2)
                layer.enabled: true
                layer.smooth: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: wallpaperMask
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                }
            }

            Item {
                id: wallpaperMask
                anchors.fill: parent
                visible: false
                layer.enabled: true
                Rectangle {
                    anchors.fill: parent
                    radius: root.radius
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: root.radius
                color: Qt.alpha(root.baseColor, 0.35)
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.active ? Qt.alpha(Appearance.colors.colPrimary, 0.06) : Qt.alpha(Appearance.m3colors.m3onSurface, root.hovered ? 0.06 : 0)
        Behavior on color { ColorAnimation { duration: Appearance.animation.elementMoveFast.duration } }
    }

    Text {
        anchors.centerIn: parent
        visible: root.label.length > 0
        text: root.label
        font.family: root.special ? Appearance.font.family.title : Appearance.font.family.expressive
        font.pixelSize: root.numberSize
        font.weight: Font.DemiBold
        color: Qt.alpha(Appearance.m3colors.m3onSurface, root.special ? (root.active ? 0.70 : 0.42) : (root.active ? 0.40 : 0.20))
        Behavior on color { ColorAnimation { duration: Appearance.animation.elementMoveFast.duration } }
    }

    Text {
        anchors.centerIn: parent
        visible: root.icon.length > 0
        text: root.icon
        font.family: Appearance.font.family.material
        font.pixelSize: root.iconSize
        color: Qt.alpha(Appearance.colors.colPrimary, root.dropHover ? 1 : 0.7)
        scale: root.dropHover ? 1.25 : 1
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        visible: root.special && root.icon !== "add"
        z: 99
        width: 3
        height: parent.height * 0.42
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        radius: 2
        color: Qt.alpha(Appearance.colors.colPrimary, root.active ? 0.95 : 0.35)
        Behavior on color { ColorAnimation { duration: Appearance.animation.elementMoveFast.duration } }
    }

    Rectangle {
        anchors.fill: parent
        z: 100
        radius: root.radius
        color: "transparent"
        antialiasing: true
        border.width: root.dropHover || root.active ? 2 : 1
        border.color: root.dropHover || root.active ? Appearance.colors.colPrimary
                    : root.icon === "add" ? Qt.alpha(Appearance.colors.colPrimary, root.hovered ? 0.55 : 0.22)
                    : root.hovered ? Qt.alpha(Appearance.m3colors.m3outline, 0.65)
                    : Qt.alpha(Appearance.m3colors.m3outlineVariant, root.special ? 0.8 : 0.5)
        Behavior on border.color { ColorAnimation { duration: Appearance.animation.elementMoveFast.duration } }
    }

    HoverHandler {
        id: hoverHandler
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: root.clicked()
    }

    DropArea {
        anchors.fill: parent
        onEntered: root.dragEntered()
        onExited: root.dragExited()
    }
}

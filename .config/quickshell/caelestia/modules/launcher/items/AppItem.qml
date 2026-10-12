import QtQuick
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.launcher.services

Item {
    id: root

    required property DesktopEntry modelData
    required property ScreenState screenState

    function materialAppIcon(entry): string {
        const id = String(entry.id || "").toLowerCase();
        const name = String(entry.name || "").toLowerCase();
        const categories = String(entry.categories || "").toLowerCase();
        const key = `${id} ${name}`;

        if (key.includes("firefox") || key.includes("chromium") || key.includes("browser"))
            return "language";
        if (key.includes("dolphin") || key.includes("thunar") || key.includes("file") || key.includes("files"))
            return "folder_open";
        if (key.includes("kitty") || key.includes("alacritty") || key.includes("foot") || key.includes("terminal"))
            return "terminal";
        if (key.includes("code") || key.includes("vscode") || key.includes("visual studio"))
            return "code";
        if (key.includes("discord") || key.includes("telegram") || key.includes("signal"))
            return "forum";
        if (key.includes("spotify") || key.includes("sonora") || key.includes("music"))
            return "music_note";
        if (key.includes("steam") || key.includes("game"))
            return "sports_esports";
        if (key.includes("vlc") || key.includes("mpv") || key.includes("video"))
            return "movie";
        if (key.includes("gimp") || key.includes("krita") || key.includes("inkscape"))
            return "image";
        if (key.includes("thunderbird") || key.includes("mail"))
            return "mail";
        if (key.includes("settings") || key.includes("systemsettings"))
            return "settings";
        if (key.includes("calculator") || key.includes("calc"))
            return "calculate";

        if (categories.includes("terminalemulator"))
            return "terminal";
        if (categories.includes("development") || categories.includes("ide"))
            return "code";
        if (categories.includes("audiovideo"))
            return "play_circle";
        if (categories.includes("graphics"))
            return "image";
        if (categories.includes("game"))
            return "sports_esports";
        if (categories.includes("office"))
            return "description";
        if (categories.includes("network") || categories.includes("internet"))
            return "language";
        if (categories.includes("utility"))
            return "build";
        if (categories.includes("system"))
            return "computer";

        return "apps";
    }

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: {
            Apps.launch(root.modelData);
            root.screenState.launcher = false;
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        anchors.margins: Tokens.padding.small

        MaterialIcon {
            id: icon

            anchors.verticalCenter: parent.verticalCenter
            text: root.materialAppIcon(root.modelData)
            color: Colours.palette.m3onSurfaceVariant
            fill: 0
            fontStyle: Tokens.font.icon.builders.large.scale(1.3).build()
        }

        Item {
            anchors.left: icon.right
            anchors.leftMargin: Tokens.spacing.medium
            anchors.verticalCenter: icon.verticalCenter

            implicitWidth: parent.width - icon.width - favouriteIcon.width
            implicitHeight: name.implicitHeight + comment.implicitHeight

            StyledText {
                id: name

                text: root.modelData?.name ?? ""
                font: Tokens.font.body.medium
            }

            StyledText {
                id: comment

                text: (root.modelData?.comment || root.modelData?.genericName || root.modelData?.name) ?? ""
                font: Tokens.font.body.small
                color: Colours.palette.m3outline

                elide: Text.ElideRight
                width: root.width - icon.width - favouriteIcon.width - Tokens.rounding.extraLargeIncreased

                anchors.top: name.bottom
            }
        }

        Loader {
            id: favouriteIcon

            asynchronous: true
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            active: root.modelData && Strings.testRegexList(GlobalConfig.launcher.favouriteApps, root.modelData.id)

            sourceComponent: MaterialIcon {
                text: "favorite"
                fill: 1
                color: Colours.palette.m3primary
            }
        }
    }
}

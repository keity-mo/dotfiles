
pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "functions"
import "." as Common

Singleton {
    id: root

    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/caelestia"
    readonly property string cfgDir: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/caelestia"

    property string colorSource: Common.Config.options.appearance.colorSource
    property bool caelestiaPaletteLoaded: false
    property QtObject m3colors: {
        if (colorSource === "matugen" && matugenLoader.item)
            return matugenLoader.item;
        if (colorSource === "caelestia" && caelestiaPaletteLoaded)
            return caelestiaColors;
        return defaultColors;
    }
    property QtObject animation
    property QtObject animationCurves
    property QtObject colors
    property QtObject rounding
    property QtObject font
    property QtObject sizes

    Loader {
        id: matugenLoader
        active: root.colorSource === "matugen"
        source: "Appearance.colors.qml"
    }

    // Valores leidos de ~/.config/caelestia/shell.json (solo lectura)
    property QtObject shell: QtObject {
        property bool transparencyEnabled: true
        property real transparencyBase: 0.78
        property real transparencyLayers: 0.58
        property real roundingScale: 1
        property real animScale: 1
        property string fontSans: "sans-serif"
        property string fontClock: "sans-serif"
        property string fontMono: "monospace"
        property string fontMaterial: "Material Symbols Rounded"
    }
    readonly property real panelAlpha: shell.transparencyEnabled ? shell.transparencyBase : 1
    readonly property real layerAlpha: shell.transparencyEnabled ? shell.transparencyLayers : 1
    readonly property real tileAlpha: shell.transparencyEnabled ? Math.min(1, shell.transparencyLayers + 0.14) : 1

    property QtObject defaultColors: QtObject {
        property bool darkmode: true
        property color m3primary: "#E5B6F2"
        property color m3onPrimary: "#452152"
        property color m3primaryContainer: "#5D386A"
        property color m3onPrimaryContainer: "#F9D8FF"
        property color m3secondary: "#D5C0D7"
        property color m3onSecondary: "#392C3D"
        property color m3secondaryContainer: "#534457"
        property color m3onSecondaryContainer: "#F2DCF3"
        property color m3tertiary: "#F5B7C0"
        property color m3error: "#FFB4AB"
        property color m3onError: "#690005"
        property color m3background: "#161217"
        property color m3onBackground: "#EAE0E7"
        property color m3surface: "#161217"
        property color m3surfaceContainerLow: "#1F1A1F"
        property color m3surfaceContainer: "#231E23"
        property color m3surfaceContainerHigh: "#2D282E"
        property color m3surfaceContainerHighest: "#383339"
        property color m3onSurface: "#EAE0E7"
        property color m3surfaceVariant: "#4C444D"
        property color m3onSurfaceVariant: "#CFC3CD"
        property color m3inverseSurface: "#EAE0E7"
        property color m3inverseOnSurface: "#342F34"
        property color m3outline: "#988E97"
        property color m3outlineVariant: "#4C444D"
        property color m3shadow: "#000000"
        property color m3scrim: "#000000"
    }

    property QtObject caelestiaColors: QtObject {
        property bool darkmode: root.defaultColors.darkmode
        property color m3primary: root.defaultColors.m3primary
        property color m3onPrimary: root.defaultColors.m3onPrimary
        property color m3primaryContainer: root.defaultColors.m3primaryContainer
        property color m3onPrimaryContainer: root.defaultColors.m3onPrimaryContainer
        property color m3secondary: root.defaultColors.m3secondary
        property color m3onSecondary: root.defaultColors.m3onSecondary
        property color m3secondaryContainer: root.defaultColors.m3secondaryContainer
        property color m3onSecondaryContainer: root.defaultColors.m3onSecondaryContainer
        property color m3tertiary: root.defaultColors.m3tertiary
        property color m3error: root.defaultColors.m3error
        property color m3onError: root.defaultColors.m3onError
        property color m3background: root.defaultColors.m3background
        property color m3onBackground: root.defaultColors.m3onBackground
        property color m3surface: root.defaultColors.m3surface
        property color m3surfaceContainerLow: root.defaultColors.m3surfaceContainerLow
        property color m3surfaceContainer: root.defaultColors.m3surfaceContainer
        property color m3surfaceContainerHigh: root.defaultColors.m3surfaceContainerHigh
        property color m3surfaceContainerHighest: root.defaultColors.m3surfaceContainerHighest
        property color m3onSurface: root.defaultColors.m3onSurface
        property color m3surfaceVariant: root.defaultColors.m3surfaceVariant
        property color m3onSurfaceVariant: root.defaultColors.m3onSurfaceVariant
        property color m3inverseSurface: root.defaultColors.m3inverseSurface
        property color m3inverseOnSurface: root.defaultColors.m3inverseOnSurface
        property color m3outline: root.defaultColors.m3outline
        property color m3outlineVariant: root.defaultColors.m3outlineVariant
        property color m3shadow: root.defaultColors.m3shadow
        property color m3scrim: root.defaultColors.m3scrim
    }

    function reloadScheme() {
        schemeFile.reload();
        shellFile.reload();
    }

    function applyScheme(raw) {
        let data;
        try {
            data = JSON.parse(raw);
        } catch (e) {
            console.warn("overview: scheme.json invalido", e);
            return;
        }
        const c = data.colours ?? data.colors ?? ({});
        const keys = ["primary", "onPrimary", "primaryContainer", "onPrimaryContainer", "secondary", "onSecondary", "secondaryContainer", "onSecondaryContainer", "tertiary", "error", "onError", "background", "onBackground", "surface", "surfaceContainerLow", "surfaceContainer", "surfaceContainerHigh", "surfaceContainerHighest", "onSurface", "surfaceVariant", "onSurfaceVariant", "inverseSurface", "inverseOnSurface", "outline", "outlineVariant", "shadow", "scrim"];
        let count = 0;
        for (const key of keys) {
            const v = c[key];
            if (typeof v !== "string" || v.length === 0)
                continue;
            const prop = "m3" + key;
            caelestiaColors[prop] = v.startsWith("#") ? v : "#" + v;
            count++;
        }
        caelestiaColors.darkmode = (data.mode ?? "dark") !== "light";
        root.caelestiaPaletteLoaded = count > 0;
    }

    function applyShell(raw) {
        let data;
        try {
            data = JSON.parse(raw);
        } catch (e) {
            return;
        }
        const a = data.appearance ?? data;
        const t = a.transparency ?? ({});
        const fam = a.font?.family ?? ({});
        shell.transparencyEnabled = t.enabled ?? true;
        shell.transparencyBase = t.base ?? 0.78;
        shell.transparencyLayers = t.layers ?? 0.58;
        shell.roundingScale = a.rounding?.scale ?? 1;
        shell.animScale = a.anim?.durations?.scale ?? 1;
        shell.fontSans = fam.sans ?? "sans-serif";
        shell.fontClock = fam.clock ?? fam.sans ?? "sans-serif";
        shell.fontMono = fam.mono ?? "monospace";
        shell.fontMaterial = fam.material ?? "Material Symbols Rounded";
    }

    FileView {
        id: schemeFile
        path: root.stateDir + "/scheme.json"
        watchChanges: root.colorSource === "caelestia"
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.applyScheme(text())
    }

    FileView {
        id: shellFile
        path: root.cfgDir + "/shell.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.applyShell(text())
    }

    colors: QtObject {
        property color colSubtext: root.m3colors.m3outline
        property color colLayer0: root.m3colors.m3background
        property color colOnLayer0: root.m3colors.m3onBackground
        property color colLayer0Border: ColorUtils.mix(root.m3colors.m3outlineVariant, colLayer0, 0.4)
        property color colLayer1: root.m3colors.m3surfaceContainerLow
        property color colOnLayer1: root.m3colors.m3onSurfaceVariant
        property color colOnLayer1Inactive: ColorUtils.mix(colOnLayer1, colLayer1, 0.45)
        property color colLayer1Hover: ColorUtils.mix(colLayer1, colOnLayer1, 0.92)
        property color colLayer1Active: ColorUtils.mix(colLayer1, colOnLayer1, 0.85)
        property color colLayer2: root.m3colors.m3surfaceContainer
        property color colOnLayer2: root.m3colors.m3onSurface
        property color colLayer2Hover: ColorUtils.mix(colLayer2, colOnLayer2, 0.90)
        property color colLayer2Active: ColorUtils.mix(colLayer2, colOnLayer2, 0.80)
        property color colPrimary: root.m3colors.m3primary
        property color colOnPrimary: root.m3colors.m3onPrimary
        property color colSecondary: root.m3colors.m3secondary
        property color colSecondaryContainer: root.m3colors.m3secondaryContainer
        property color colOnSecondaryContainer: root.m3colors.m3onSecondaryContainer
        property color colTooltip: root.m3colors.m3inverseSurface
        property color colOnTooltip: root.m3colors.m3inverseOnSurface
        property color colShadow: ColorUtils.transparentize(root.m3colors.m3shadow, 0.7)
        property color colOutline: root.m3colors.m3outline
        property color colTertiary: root.m3colors.m3tertiary ?? root.m3colors.m3secondary
        property color colError: root.m3colors.m3error ?? "#FFB4AB"
        property color colOnError: root.m3colors.m3onError ?? "#690005"
        property color colScrim: root.m3colors.m3scrim ?? root.m3colors.m3shadow
    }

    rounding: QtObject {
        readonly property real s: root.shell.roundingScale
        property int unsharpen: Math.round(2 * s)
        property int verysmall: Math.round(8 * s)
        property int small: Math.round(12 * s)
        property int normal: Math.round(17 * s)
        property int large: Math.round(25 * s)
        property int full: 9999
        property int screenRounding: large
        property int windowRounding: small
    }

    font: QtObject {
        property QtObject family: QtObject {
            property string main: root.shell.fontSans
            property string title: root.shell.fontSans
            property string expressive: root.shell.fontClock
            property string mono: root.shell.fontMono
            property string material: root.shell.fontMaterial
        }
        property QtObject pixelSize: QtObject {
            property int smaller: Common.Config.options.appearance.font.pixelSize.smaller
            property int small: Common.Config.options.appearance.font.pixelSize.small
            property int normal: Common.Config.options.appearance.font.pixelSize.normal
            property int larger: Common.Config.options.appearance.font.pixelSize.larger
            property int huge: Common.Config.options.appearance.font.pixelSize.huge
        }
    }

    animationCurves: QtObject {
        readonly property list<real> expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1.00, 1, 1]
        readonly property list<real> expressiveFastSpatial: [0.42, 1.67, 0.21, 0.90, 1, 1]
        readonly property list<real> expressiveEffects: [0.34, 0.80, 0.34, 1.00, 1, 1]
        readonly property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
        readonly property list<real> emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
        readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
        readonly property real expressiveDefaultSpatialDuration: Math.round(Common.Config.options.appearance.animation.duration.elementMove * root.shell.animScale)
        readonly property real expressiveEffectsDuration: Math.round(Common.Config.options.appearance.animation.duration.elementMoveFast * root.shell.animScale)
    }

    animation: QtObject {
        property QtObject elementMove: QtObject {
            property int duration: root.animationCurves.expressiveDefaultSpatialDuration
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: root.animationCurves.expressiveDefaultSpatial
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementMove.duration
                    easing.type: root.animation.elementMove.type
                    easing.bezierCurve: root.animation.elementMove.bezierCurve
                }
            }
        }

        property QtObject elementMoveEnter: QtObject {
            property int duration: Math.round(Common.Config.options.appearance.animation.duration.elementMoveEnter * root.shell.animScale)
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: root.animationCurves.emphasizedDecel
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementMoveEnter.duration
                    easing.type: root.animation.elementMoveEnter.type
                    easing.bezierCurve: root.animation.elementMoveEnter.bezierCurve
                }
            }
        }

        property QtObject elementMoveExit: QtObject {
            property int duration: Math.round(180 * root.shell.animScale)
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: root.animationCurves.emphasizedAccel
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementMoveExit.duration
                    easing.type: root.animation.elementMoveExit.type
                    easing.bezierCurve: root.animation.elementMoveExit.bezierCurve
                }
            }
        }

        property QtObject elementMoveFast: QtObject {
            property int duration: root.animationCurves.expressiveEffectsDuration
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: root.animationCurves.expressiveEffects
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementMoveFast.duration
                    easing.type: root.animation.elementMoveFast.type
                    easing.bezierCurve: root.animation.elementMoveFast.bezierCurve
                }
            }
        }
    }

    sizes: QtObject {
        property real elevationMargin: Common.Config.options.appearance.sizes.elevationMargin
    }
}


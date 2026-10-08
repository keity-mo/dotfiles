
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../common"
import "../../common/widgets"
import "../../services"
import "."

Item {
    id: root

    required property var panelWindow
    property real progress: 1

    // Datos de Hyprland
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)
    readonly property int monitorId: monitor?.id ?? 0
    readonly property var windowByAddress: HyprlandData.windowByAddress ?? ({})
    readonly property var monitorById: {
        const out = ({});
        for (const m of (HyprlandData.monitors ?? []))
            out[m.id] = m;
        return out;
    }
    readonly property var monitorData: monitorById[monitorId]
    readonly property var reserved: monitorData?.reserved ?? [0, 0, 0, 0]
    readonly property real monitorScale: monitor?.scale ?? 1
    readonly property bool rotated: (monitorData?.transform ?? 0) % 2 === 1
    readonly property real workW: Math.max(1, (rotated ? (monitor?.height ?? 1080) : (monitor?.width ?? 1920)) / monitorScale - reserved[0] - reserved[2])
    readonly property real workH: Math.max(1, (rotated ? (monitor?.width ?? 1920) : (monitor?.height ?? 1080)) / monitorScale - reserved[1] - reserved[3])

    // Tokens de layout (todo en pixeles enteros)
    readonly property int rows: Config.options.overview.rows
    readonly property int columns: Config.options.overview.columns
    readonly property real previewScale: Config.options.overview.scale
    readonly property real gap: Math.round(Math.max(8, Config.options.overview.workspaceSpacing))
    readonly property real pad: Math.round(Math.max(14, Config.options.overview.backgroundPadding))
    readonly property real tileRadius: Math.round(Appearance.rounding.small * 0.8)
    readonly property real windowRadius: Math.max(4, Math.round(tileRadius * 0.55))
    readonly property real panelRadius: tileRadius + pad
    readonly property real wsW: Math.max(40, Math.round(workW * previewScale))
    readonly property real wsH: Math.max(24, Math.round(workH * previewScale))
    readonly property bool blurOn: panelWindow.blurEnabled
    readonly property real panelAlpha: blurOn ? Appearance.panelAlpha : Math.max(Appearance.panelAlpha, 0.82)

    // Grupo de workspaces visible
    readonly property bool useWorkspaceMap: Config.options.overview.useWorkspaceMap
    readonly property int workspaceOffset: useWorkspaceMap ? Number((Config.options.overview.workspaceMap ?? [])[monitorId] ?? 0) : 0
    readonly property int perGroup: rows * columns
    readonly property int activeId: Math.max(1, monitor?.activeWorkspace?.id ?? 1)
    readonly property int group: Math.floor((activeId - workspaceOffset - 1) / perGroup)
    readonly property int firstId: group * perGroup + 1 + workspaceOffset
    readonly property int lastId: firstId + perGroup - 1
    readonly property string activeSpecial: `${monitorData?.specialWorkspace?.name ?? ""}`.replace("special:", "")

    function rowOf(wsId) {
        if (!Number.isFinite(wsId))
            return 0;
        const n = ((Math.floor((wsId - workspaceOffset - 1) / columns) % rows) + rows) % rows;
        return Config.options.overview.orderBottomUp ? rows - n - 1 : n;
    }

    function colOf(wsId) {
        if (!Number.isFinite(wsId))
            return 0;
        const n = (((wsId - workspaceOffset - 1) % columns) + columns) % columns;
        return Config.options.overview.orderRightLeft ? columns - n - 1 : n;
    }

    function cellId(visualRow, visualCol) {
        const r = Config.options.overview.orderBottomUp ? rows - visualRow - 1 : visualRow;
        const c = Config.options.overview.orderRightLeft ? columns - visualCol - 1 : visualCol;
        return group * perGroup + r * columns + c + 1 + workspaceOffset;
    }

    // Filas visibles (hideEmptyRows): slot de cada fila o -1 si esta oculta
    readonly property var rowSlots: {
        const hide = Config.options.overview.hideEmptyRows;
        const used = new Set();
        if (hide) {
            used.add(rowOf(activeId));
            for (const addr in windowByAddress) {
                const id = windowByAddress[addr]?.workspace?.id;
                if (id >= firstId && id <= lastId)
                    used.add(rowOf(id));
            }
        }
        const slots = [];
        let n = 0;
        for (let r = 0; r < rows; r++)
            slots.push((!hide || used.has(r)) ? n++ : -1);
        if (n === 0)
            slots[0] = 0;
        return slots;
    }
    readonly property int visibleRowCount: Math.max(1, rowSlots.filter(s => s >= 0).length)
    readonly property real gridW: columns * wsW + (columns - 1) * gap
    readonly property real gridH: visibleRowCount * wsH + (visibleRowCount - 1) * gap

    // Workspaces especiales
    readonly property bool specialEnabled: Config.options.overview.showSpecialWorkspaces
    readonly property var specialNames: {
        if (!specialEnabled)
            return [];
        const out = [];
        const push = v => {
            const s = `${v ?? ""}`.trim();
            if (s.length > 0 && !out.includes(s))
                out.push(s);
        };
        for (const c of (Config.options.overview.specialWorkspaces ?? []))
            push(c);
        for (const e of (GlobalStates.extraSpecials ?? []))
            push(e);
        const monName = monitor?.name ?? "";
        for (const ws of (HyprlandData.allWorkspaces ?? [])) {
            const n = `${ws?.name ?? ""}`;
            if (n.startsWith("special:") && `${ws?.monitor ?? ""}` === monName)
                push(n.slice(8));
        }
        for (const addr in windowByAddress) {
            const w = windowByAddress[addr];
            if ((w?.monitor ?? -1) !== monitorId)
                continue;
            const n = `${w?.workspace?.name ?? ""}`;
            if (n.startsWith("special:"))
                push(n.slice(8));
        }
        return out;
    }
    readonly property int specialSlotCols: Math.max(1, Math.min(Config.options.overview.specialWorkspaceColumns, 8))
    readonly property bool specialsFull: specialNames.length >= specialSlotCols * 2
    readonly property int specialTileCount: Math.max(1, specialNames.length)
    readonly property real stripPad: 12
    readonly property real stripHeaderH: 22
    readonly property real stripTop: gridH + gap * 2
    readonly property real stripInnerW: gridW - stripPad * 2
    readonly property real sTileW: Math.max(40, Math.floor((stripInnerW - (specialSlotCols - 1) * gap) / specialSlotCols))
    readonly property real sFactor: sTileW / wsW
    readonly property real sTileH: Math.round(wsH * sFactor)
    readonly property int sUsedCols: Math.min(specialTileCount, specialSlotCols)
    readonly property int sRows: Math.ceil(specialTileCount / specialSlotCols)
    readonly property real sOffsetX: stripPad + Math.round((stripInnerW - (sUsedCols * sTileW + (sUsedCols - 1) * gap)) / 2)
    readonly property real sTilesTop: stripTop + stripPad + stripHeaderH + 14
    readonly property real stripH: (sTilesTop - stripTop) + sRows * sTileH + (sRows - 1) * gap + stripPad
    readonly property real contentW: gridW
    readonly property real contentH: specialEnabled ? stripTop + stripH : gridH

    // Pantalla completa por workspace (una sola pasada)
    readonly property var fullscreenWorkspaces: {
        const s = new Set();
        for (const addr in windowByAddress) {
            const w = windowByAddress[addr];
            if ((w?.fullscreen ?? 0) > 0)
                s.add(w.workspace?.id);
        }
        return s;
    }

    // Wallpapers opcionales
    readonly property string emptyWallpaper: wallpaperSource(Config.options.overview.emptyWorkspaceWallpaper)
    readonly property string specialWallpaper: wallpaperSource(Config.options.overview.specialEmptyWorkspaceWallpaper)

    // Estado de arrastre: "ws:N", "special:nombre" o "new"
    property string dropTarget: ""
    property string dragFrom: ""

    function wallpaperSource(path) {
        const t = `${path ?? ""}`.trim();
        if (t.length === 0)
            return "";
        if (t.startsWith("file:/") || t.startsWith("qrc:/") || t.startsWith("image://") || t.startsWith("http://") || t.startsWith("https://"))
            return t;
        return t.startsWith("/") ? `file://${t}` : t;
    }

    function isSpecial(win) {
        return `${win?.workspace?.name ?? ""}`.startsWith("special:");
    }

    function specialNameOf(win) {
        const n = `${win?.workspace?.name ?? ""}`;
        return n.startsWith("special:") ? n.slice(8) : "";
    }

    function specialHasWindows(name) {
        for (const addr in windowByAddress) {
            if (specialNameOf(windowByAddress[addr]) === name)
                return true;
        }
        return false;
    }

    function removeExtraSpecial(name) {
        // Si es el special abierto, primero se pasa al anterior (o se vuelve a los normales)
        if (navSpecial === name) {
            const idx = specialNames.indexOf(name);
            goSpecial(idx > 0 ? specialNames[idx - 1] : "");
        }
        GlobalStates.extraSpecials = GlobalStates.extraSpecials.filter(n => n !== name);
    }

    function specialLabel(name) {
        const raw = `${name ?? ""}`.trim();
        const names = ({ "sysmon": "terminal", "music": "música", "communication": "comunicación", "todo": "to-do" });
        return raw.length === 0 ? "Special" : (names[raw.toLowerCase()] ?? raw.replace(/[-_]+/g, " "));
    }

    function specialIcon(name) {
        const icons = ({ "sysmon": "terminal", "music": "music_note", "communication": "forum", "todo": "checklist", "special": "star" });
        const raw = `${name ?? ""}`.trim().toLowerCase();
        return icons[raw] ?? (raw.startsWith("stash") ? "inventory_2" : "");
    }

    function nextSpecialName() {
        const taken = new Set(specialNames.map(n => n.toLowerCase()));
        if (!taken.has("stash"))
            return "stash";
        let i = 2;
        while (taken.has(`stash-${i}`))
            i += 1;
        return `stash-${i}`;
    }

    function stackRank(win) {
        return (win?.pinned ? 2000000 : 0) + (win?.floating ? 1000000 : 0) - (win?.focusHistoryID ?? 9999);
    }

    // Acciones de Hyprland (Lua y clasico)
    function dispatch(lua, classic) {
        Hyprland.dispatch(Hyprland.usingLua ? lua : classic);
    }

    function focusWorkspace(id) {
        dispatch(`hl.dsp.focus({workspace = "${id}"})`, `workspace ${id}`);
    }

    function toggleSpecial(name) {
        dispatch(`hl.dsp.workspace.toggle_special("${name}")`, `togglespecialworkspace ${name}`);
    }

    function activateWindow(address) {
        GlobalStates.overviewOpen = false;
        dispatch(`hl.dsp.focus({ window = "address:${address}" })`, `focuswindow address:${address}`);
    }

    function closeWindow(address) {
        console.log("DISPATCH CLOSE:", address); dispatch(`hl.dsp.window.close({ window = "address:${address}" })`, `closewindow address:${address}`);
    }

    function moveWindow(address, target) {
        dispatch(`hl.dsp.window.move({workspace = "${target}", follow = false, window = "address:${address}"})`, `movetoworkspacesilent ${target}, address:${address}`);
    }

    function finishDrag(address) {
        const t = dropTarget;
        const from = dragFrom;
        dropTarget = "";
        dragFrom = "";
        if (t.length === 0 || t === from || !address)
            return;
        if (t === "new")
            moveWindow(address, `special:${nextSpecialName()}`);
        else if (t.startsWith("special:"))
            moveWindow(address, t);
        else if (t.startsWith("ws:"))
            moveWindow(address, t.slice(3));
    }

    // Estado de navegacion por teclado en los special: se guarda el destino al instante
    // para no depender del retraso de Hyprland cuando se mantiene la tecla.
    property string pendingSpecial: ""
    property bool hasPendingSpecial: false
    readonly property string navSpecial: hasPendingSpecial ? pendingSpecial : activeSpecial

    Timer {
        id: pendingSpecialTimer
        interval: 450
        onTriggered: root.hasPendingSpecial = false
    }

    // name vacio = salir de los special y volver a los workspaces normales
    function goSpecial(name) {
        const target = name.length > 0 ? name : navSpecial;
        pendingSpecial = name;
        hasPendingSpecial = true;
        pendingSpecialTimer.restart();
        if (target.length > 0)
            toggleSpecial(target);
    }

    function isExtraSpecial(name) {
        return GlobalStates.extraSpecials.indexOf(name) >= 0;
    }

    // Quita todos los special extra vacios, salvo el indicado
    function pruneEmptyExtras(keep) {
        const list = GlobalStates.extraSpecials.filter(n => n === keep || specialHasWindows(n));
        if (list.length !== GlobalStates.extraSpecials.length)
            GlobalStates.extraSpecials = list;
    }

    function navigateSpecial(dRow, dCol) {
        const n = specialNames.length;
        const i = specialNames.indexOf(navSpecial);
        if (n === 0 || i < 0) {
            goSpecial("");
            pruneEmptyExtras("");
            return;
        }
        const cols = specialSlotCols;
        const rowCount = Math.ceil(n / cols);
        let r = Math.floor(i / cols);
        let c = i % cols;
        if (dRow < 0 && r === 0) {
            goSpecial("");
            pruneEmptyExtras("");
            return;
        }
        // Abajo desde la ultima fila sin extras: abre una fila nueva con un solo extra
        if (dRow > 0 && r === rowCount - 1 && GlobalStates.extraSpecials.length === 0 && !specialsFull) {
            const name = nextSpecialName();
            GlobalStates.extraSpecials = [name];
            goSpecial(name);
            return;
        }
        // Izquierda sobre un extra vacio: lo quita y pasa a la celda anterior (la primera fila fija no se toca)
        if (dCol < 0 && dRow === 0 && isExtraSpecial(navSpecial) && !specialHasWindows(navSpecial)) {
            removeExtraSpecial(navSpecial);
            return;
        }
        // Derecha en el ultimo extra con espacio en la fila: crea el siguiente
        if (dCol > 0 && dRow === 0 && isExtraSpecial(navSpecial) && i === n - 1 && (i + 1) % cols !== 0 && !specialsFull) {
            if (!hasPendingSpecial) {
                const name = nextSpecialName();
                GlobalStates.extraSpecials = [...GlobalStates.extraSpecials, name];
                goSpecial(name);
            }
            return;
        }
        if (dCol !== 0) {
            const inRow = Math.min(cols, n - r * cols);
            c = (c + dCol + inRow) % inRow;
        }
        if (dRow !== 0) {
            r = (r + dRow + rowCount) % rowCount;
            c = Math.min(c, Math.min(cols, n - r * cols) - 1);
        }
        const target = specialNames[r * cols + c];
        if (target !== navSpecial)
            goSpecial(target);
        if (!isExtraSpecial(target))
            pruneEmptyExtras(target);
    }

    // Navegacion (la usa Overview.qml)
    function navigate(dRow, dCol) {
        if (specialEnabled && navSpecial.length > 0) {
            navigateSpecial(dRow, dCol);
            return;
        }
        let r = rowOf(activeId);
        let c = colOf(activeId);
        if (specialEnabled && dRow > 0 && r === rows - 1 && specialNames.length > 0) {
            goSpecial(specialNames[Math.min(c, Math.min(specialSlotCols, specialNames.length) - 1)]);
            return;
        }
        if (dCol !== 0)
            c = (c + dCol + columns) % columns;
        if (dRow !== 0)
            r = (r + dRow + rows) % rows;
        focusWorkspace(cellId(r, c));
    }

    function jumpTo(position) {
        if (position < 1 || position > perGroup)
            return false;
        focusWorkspace(firstId + position - 1);
        return true;
    }

    function stepWorkspace(delta) {
        if (!Number.isFinite(delta) || delta === 0)
            return;
        const minId = workspaceOffset + 1;
        let maxId = minId + perGroup - 1;
        for (const id of (HyprlandData.workspaceIds ?? [])) {
            if (Number.isFinite(id) && id >= minId)
                maxId = Math.max(maxId, id);
        }
        maxId = Math.max(maxId, activeId);
        let target = activeId + delta;
        if (target < minId)
            target = maxId;
        else if (target > maxId)
            target = minId;
        focusWorkspace(target);
    }

    // Recaptura por eventos (modo snapshot), con anti-rebote
    property int recaptureToken: 0
    readonly property string previewMode: `${Config.options.overview.previewMode}`.trim().toLowerCase()
    readonly property bool eventPreviews: Config.options.overview.previewsEnabled && (previewMode === "event" || previewMode === "snapshot")

    Timer {
        id: recaptureDebounce
        interval: Math.max(10, Config.options.hacks.hyprlandEventDebounceMs)
        onTriggered: root.recaptureToken += 1
    }

    Connections {
        target: Hyprland
        enabled: root.eventPreviews
        function onRawEvent(event) {
            const name = `${event?.name ?? event?.event ?? event?.type ?? ""}`;
            if (name === "openwindow" || name === "closewindow" || name.startsWith("movewindow"))
                recaptureDebounce.restart();
        }
    }

    property bool wheelCooldown: false
    Timer {
        id: wheelTimer
        interval: 140
        onTriggered: root.wheelCooldown = false
    }

    // Entrada y salida del panel
    implicitWidth: panel.width
    implicitHeight: panel.height
    opacity: Math.min(1, progress * 1.5)
    scale: 0.96 + 0.04 * progress
    transform: Translate { y: (1 - root.progress) * 18 }

    Rectangle {
        id: panel
        width: root.contentW + root.pad * 2
        height: root.contentH + root.pad * 2
        radius: root.panelRadius
        antialiasing: true
        color: Qt.alpha(Appearance.m3colors.m3surface, root.panelAlpha)
        border.width: 1
        border.color: Qt.alpha(Appearance.m3colors.m3outlineVariant, 0.6)

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: mouse => mouse.accepted = true
        }

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                const dy = event.angleDelta.y;
                if (!dy || root.wheelCooldown)
                    return;
                root.wheelCooldown = true;
                wheelTimer.restart();
                root.stepWorkspace(dy > 0 ? -1 : 1);
            }
        }


        Item {
            id: content
            x: root.pad
            y: root.pad
            width: root.contentW
            height: root.contentH

            // Strip de special workspaces: fondo, cabecera y divisor
            Rectangle {
                visible: root.specialEnabled
                y: root.stripTop
                width: root.contentW
                height: root.stripH
                radius: root.tileRadius + 8
                antialiasing: true
                color: Qt.alpha(Appearance.m3colors.m3surfaceContainerLow, Appearance.tileAlpha)
                border.width: 1
                border.color: Qt.alpha(Appearance.m3colors.m3outlineVariant, 0.65)
            }

            Row {
                visible: root.specialEnabled
                x: root.stripPad + 4
                y: root.stripTop + root.stripPad
                height: root.stripHeaderH
                spacing: 9

                Rectangle {
                    width: 28
                    height: 28
                    radius: 9
                    anchors.verticalCenter: parent.verticalCenter
                    color: Qt.alpha(Appearance.colors.colPrimary, 0.12)
                    border.width: 1
                    border.color: Qt.alpha(Appearance.colors.colPrimary, 0.24)

                    Text {
                        anchors.centerIn: parent
                        text: "layers"
                        font.family: Appearance.font.family.material
                        font.pixelSize: 17
                        color: Appearance.colors.colPrimary
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Espacios de trabajo"
                    font.family: Appearance.font.family.title
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                }
            }

            Rectangle {
                visible: root.specialEnabled
                x: root.stripPad
                y: root.stripTop + root.stripPad + root.stripHeaderH + 6
                width: root.contentW - root.stripPad * 2
                height: 1
                color: Qt.alpha(Appearance.m3colors.m3outlineVariant, 0.6)
            }

            // Workspaces normales
            Repeater {
                model: root.rows * root.columns
                delegate: WorkspaceTile {
                    id: wsTile
                    required property int index
                    readonly property int r: Math.floor(index / root.columns)
                    readonly property int c: index % root.columns
                    readonly property int wsId: root.cellId(r, c)
                    readonly property int slot: root.rowSlots[r] ?? -1
                    readonly property string key: `ws:${wsId}`
                    z: 1
                    visible: slot >= 0
                    x: c * (root.wsW + root.gap)
                    y: Math.max(slot, 0) * (root.wsH + root.gap)
                    width: root.wsW
                    height: root.wsH
                    radius: root.tileRadius
                    label: `${wsId}`
                    numberSize: Math.round(root.wsH * 0.3)
                    active: wsId === root.activeId && root.navSpecial === ""
                    wallpaper: root.emptyWallpaper
                    dropHover: root.dropTarget === key && root.dragFrom !== key
                    Behavior on y { animation: Appearance.animation.elementMove.numberAnimation.createObject(this) }
                    onClicked: {
                        if (root.dropTarget.length > 0)
                            return;
                        GlobalStates.overviewOpen = false;
                        root.focusWorkspace(wsId);
                    }
                    onDragEntered: root.dropTarget = key
                    onDragExited: {
                        if (root.dropTarget === key)
                            root.dropTarget = "";
                    }
                }
            }

            // Special workspaces
            Repeater {
                model: root.specialEnabled ? root.specialNames : []
                delegate: WorkspaceTile {
                    id: spTile
                    required property string modelData
                    required property int index
                    readonly property string key: `special:${modelData}`
                    z: 1
                    x: root.sOffsetX + (index % root.specialSlotCols) * (root.sTileW + root.gap)
                    y: root.sTilesTop + Math.floor(index / root.specialSlotCols) * (root.sTileH + root.gap)
                    width: root.sTileW
                    height: root.sTileH
                    radius: root.tileRadius
                    special: true
                    label: root.specialIcon(modelData).length > 0 ? "" : root.specialLabel(modelData)
                    icon: root.specialIcon(modelData)
                    iconSize: Math.max(20, Math.round(root.sTileH * 0.26))
                    numberSize: Math.max(12, Math.round(root.sTileH * 0.2))
                    active: root.navSpecial === modelData
                    deletable: GlobalStates.extraSpecials.indexOf(modelData) >= 0 && !root.specialHasWindows(modelData)
                    onDeleteRequested: root.removeExtraSpecial(modelData)
                    wallpaper: root.specialWallpaper
                    dropHover: root.dropTarget === key && root.dragFrom !== key
                    onClicked: {
                        if (root.dropTarget.length > 0)
                            return;
                        GlobalStates.overviewOpen = false;
                        root.toggleSpecial(modelData);
                    }
                    onDragEntered: root.dropTarget = key
                    onDragExited: {
                        if (root.dropTarget === key)
                            root.dropTarget = "";
                    }
                }
            }

            // Chip para crear un special nuevo (click) o recibir una ventana arrastrada
            Rectangle {
                id: newSpecialChip
                opacity: root.specialsFull ? 0.35 : 1
                visible: root.specialEnabled
                readonly property bool hot: chipHover.hovered ? true : root.dropTarget === "new"
                z: 2
                width: 26
                height: 26
                radius: 13
                x: root.contentW - root.stripPad - 4 - width
                y: root.stripTop + root.stripPad + (root.stripHeaderH - height) / 2
                antialiasing: true
                color: Qt.alpha(Appearance.colors.colPrimary, hot ? 0.22 : 0.08)
                border.width: 1
                border.color: Qt.alpha(Appearance.colors.colPrimary, hot ? 0.6 : 0.24)
                Behavior on color { ColorAnimation { duration: Appearance.animation.elementMoveFast.duration } }
                Behavior on border.color { ColorAnimation { duration: Appearance.animation.elementMoveFast.duration } }
                Text {
                    anchors.centerIn: parent
                    text: "add"
                    font.family: Appearance.font.family.material
                    font.pixelSize: 16
                    color: Qt.alpha(Appearance.colors.colPrimary, newSpecialChip.hot ? 1 : 0.75)
                }
                HoverHandler { id: chipHover }
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                        if (root.dropTarget.length > 0)
                            return;
                        if (root.specialsFull)
                            return;
                        GlobalStates.extraSpecials = [...GlobalStates.extraSpecials, root.nextSpecialName()];
                    }
                }
                DropArea {
                    anchors.fill: parent
                    onEntered: root.dropTarget = "new"
                    onExited: {
                        if (root.dropTarget === "new")
                            root.dropTarget = "";
                    }
                }
            }

            // Ventanas (normales y special en una sola capa, sin reparentar al arrastrar)
            Repeater {
                model: ScriptModel {
                    values: {
                        const out = [];
                        for (const tl of ToplevelManager.toplevels.values) {
                            const win = root.windowByAddress[`0x${tl.HyprlandToplevel.address}`];
                            if (!win)
                                continue;
                            if (root.isSpecial(win)) {
                                if (!root.specialEnabled || win.monitor !== root.monitorId)
                                    continue;
                                if (root.specialNames.indexOf(root.specialNameOf(win)) < 0)
                                    continue;
                            } else {
                                const id = win.workspace?.id;
                                if (!(id >= root.firstId && id <= root.lastId))
                                    continue;
                            }
                            out.push(tl);
                        }
                        return out.sort((a, b) => root.stackRank(root.windowByAddress[`0x${a.HyprlandToplevel.address}`]) - root.stackRank(root.windowByAddress[`0x${b.HyprlandToplevel.address}`]));
                    }
                }
                delegate: OverviewWindow {
                    id: win
                    required property var modelData
                    required property int index
                    readonly property string windowAddress: `0x${modelData.HyprlandToplevel.address}`
                    readonly property bool inSpecial: root.isSpecial(windowData)
                    readonly property int sIndex: inSpecial ? root.specialNames.indexOf(root.specialNameOf(windowData)) : -1
                    readonly property int wsId: windowData?.workspace?.id ?? -1
                    readonly property int slot: root.rowSlots[root.rowOf(wsId)] ?? -1

                    windowData: root.windowByAddress[windowAddress]
                    toplevel: modelData
                    monitorData: root.monitorById[windowData?.monitor]
                    widgetMonitorData: root.monitorData
                    widgetMonitorId: root.monitorId
                    previewScale: root.previewScale
                    sizeFactor: inSpecial ? root.sFactor : 1
                    availableWidth: inSpecial ? root.sTileW : root.wsW
                    availableHeight: inSpecial ? root.sTileH : root.wsH
                    xOffset: inSpecial ? root.sOffsetX + (sIndex % root.specialSlotCols) * (root.sTileW + root.gap) : root.colOf(wsId) * (root.wsW + root.gap)
                    yOffset: inSpecial ? root.sTilesTop + Math.floor(sIndex / root.specialSlotCols) * (root.sTileH + root.gap) : Math.max(slot, 0) * (root.wsH + root.gap)
                    placed: inSpecial ? sIndex >= 0 : slot >= 0
                    hiddenByFullscreen: root.fullscreenWorkspaces.has(wsId)
                    baseZ: 10 + index
                    cornerRadius: root.windowRadius
                    recaptureToken: root.recaptureToken

                    onFocusRequested: root.activateWindow(windowAddress)
                    onCloseRequested: root.closeWindow(windowAddress)
                    onDragStarted: root.dragFrom = inSpecial ? `special:${root.specialNameOf(windowData)}` : `ws:${wsId}`
                    onDragFinished: root.finishDrag(windowAddress)
                }
            }

            // Marco del workspace activo (se desliza entre workspaces)
            Rectangle {
                readonly property int slot: root.rowSlots[root.rowOf(root.activeId)] ?? -1
                readonly property int sIdx: root.specialEnabled && root.navSpecial.length > 0 ? root.specialNames.indexOf(root.navSpecial) : -1
                readonly property bool onSpecial: sIdx >= 0
                visible: onSpecial || (slot >= 0 && root.activeId >= root.firstId && root.activeId <= root.lastId)
                z: 50000
                x: onSpecial ? root.sOffsetX + (sIdx % root.specialSlotCols) * (root.sTileW + root.gap) : root.colOf(root.activeId) * (root.wsW + root.gap)
                y: onSpecial ? root.sTilesTop + Math.floor(sIdx / root.specialSlotCols) * (root.sTileH + root.gap) : Math.max(slot, 0) * (root.wsH + root.gap)
                width: onSpecial ? root.sTileW : root.wsW
                height: onSpecial ? root.sTileH : root.wsH
                radius: root.tileRadius
                color: "transparent"
                antialiasing: true
                border.width: 2
                border.color: Appearance.colors.colPrimary
                Behavior on x { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                Behavior on y { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                Behavior on width { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                Behavior on height { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -3
                    radius: parent.radius + 3
                    color: "transparent"
                    antialiasing: true
                    border.width: 3
                    border.color: Qt.alpha(Appearance.colors.colPrimary, 0.22)
                }
            }
        }
    }
}


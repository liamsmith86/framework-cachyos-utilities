import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    property string currentProfile: "unknown"
    property var availableProfiles: []
    property bool loading: true
    property string errorMessage: ""
    property var statusInfo: null
    property var profileInfo: null
    property bool serviceActive: true
    property int refreshInterval: Plasmoid.configuration.pollingInterval * 1000
    property string gpuMode: "unknown"
    property bool gpuSwitching: false

    Plasmoid.icon: "speedometer"
    toolTipMainText: "Fan Control"
    toolTipSubText: {
        if (root.loading) return "Loading..."
        if (root.errorMessage !== "") return "Error: " + root.errorMessage
        var lines = root.currentProfile
        if (root.statusInfo) {
            lines += "  " + root.statusInfo.speed + "%"
            if (root.statusInfo.effectiveTemperature !== undefined)
                lines += "  " + root.statusInfo.effectiveTemperature + "\u00B0C"
        }
        return lines
    }

    compactRepresentation: RowLayout {
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            source: "speedometer"
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
            color: {
                if (root.errorMessage !== "") return Kirigami.Theme.negativeTextColor
                if (!root.serviceActive) return Kirigami.Theme.neutralTextColor
                return Kirigami.Theme.textColor
            }
        }

        PlasmaComponents.Label {
            visible: parent.width > Kirigami.Units.iconSizes.small * 2
            text: {
                if (root.loading) return "..."
                if (root.statusInfo) return root.statusInfo.speed + "%"
                return root.currentProfile
            }
            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
            Layout.alignment: Qt.AlignVCenter
        }
    }

    fullRepresentation: PlasmaExtras.Representation {
        id: fullRep

        header: PlasmaExtras.PlasmoidHeading {
            RowLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: "speedometer"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                }

                PlasmaExtras.Heading {
                    text: root.loading ? "Loading..." : root.currentProfile
                    level: 3
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                PlasmaComponents.BusyIndicator {
                    visible: root.loading
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                }

                PlasmaComponents.ToolButton {
                    icon.name: "view-refresh"
                    onClicked: { root.loading = true; root.errorMessage = ""; refreshAll() }
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: "Refresh"
                }

                PlasmaComponents.ToolButton {
                    icon.name: "edit-undo"
                    enabled: !root.loading
                    onClicked: {
                        root.loading = true; root.errorMessage = ""
                        runCommand("reset", "fw-fanctrl reset")
                        if (Plasmoid.configuration.autoClose) root.expanded = false
                    }
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: "Reset to default"
                }
            }
        }

        contentItem: Item {
            implicitWidth: Kirigami.Units.gridUnit * 16
            implicitHeight: contentCol.implicitHeight + Kirigami.Units.largeSpacing * 2

            ColumnLayout {
                id: contentCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Kirigami.Units.largeSpacing }
                spacing: Kirigami.Units.smallSpacing

                // Error banner
                PlasmaComponents.Label {
                    visible: root.errorMessage !== ""
                    text: root.errorMessage
                    color: Kirigami.Theme.negativeTextColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                // Live stats row
                RowLayout {
                    visible: root.statusInfo !== null
                    Layout.fillWidth: true
                    Layout.bottomMargin: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.largeSpacing

                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        PlasmaComponents.Label { text: "Fan"; color: Kirigami.Theme.disabledTextColor; font.pixelSize: Kirigami.Theme.smallFont.pixelSize }
                        PlasmaComponents.Label { text: root.statusInfo ? root.statusInfo.speed + "%" : ""; font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.4; font.bold: true }
                    }
                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        PlasmaComponents.Label { text: "Temp"; color: Kirigami.Theme.disabledTextColor; font.pixelSize: Kirigami.Theme.smallFont.pixelSize }
                        PlasmaComponents.Label { text: root.statusInfo ? root.statusInfo.temperature + "\u00B0C" : ""; font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.4; font.bold: true }
                    }
                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        PlasmaComponents.Label { text: "Avg"; color: Kirigami.Theme.disabledTextColor; font.pixelSize: Kirigami.Theme.smallFont.pixelSize }
                        PlasmaComponents.Label { text: root.statusInfo ? root.statusInfo.movingAverageTemperature + "\u00B0C" : ""; font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.4; font.bold: true }
                    }
                }

                // Separator
                Rectangle {
                    visible: root.statusInfo !== null
                    Layout.fillWidth: true
                    height: 1
                    color: Kirigami.Theme.textColor
                    opacity: 0.15
                }

                // Tab bar
                PlasmaComponents.TabBar {
                    id: tabBar
                    Layout.fillWidth: true

                    PlasmaComponents.TabButton { text: "Profiles" }
                    PlasmaComponents.TabButton { text: "Curve" }
                    PlasmaComponents.TabButton { text: "GPU" }
                }

                StackLayout {
                    Layout.fillWidth: true
                    currentIndex: tabBar.currentIndex

                    // Tab 0: Profiles
                    ColumnLayout {
                        spacing: 0

                        PlasmaComponents.Label {
                            visible: root.availableProfiles.length === 0 && !root.loading
                            text: "No profiles found."
                            color: Kirigami.Theme.disabledTextColor
                            Layout.fillWidth: true
                        }

                        Repeater {
                            model: root.availableProfiles

                            delegate: PlasmaComponents.ItemDelegate {
                                Layout.fillWidth: true
                                text: modelData
                                icon.name: modelData === root.currentProfile ? "dialog-ok-apply" : ""
                                highlighted: modelData === root.currentProfile
                                enabled: !root.loading

                                onClicked: {
                                    if (modelData !== root.currentProfile) {
                                        applyProfile(modelData)
                                        if (Plasmoid.configuration.autoClose) root.expanded = false
                                    }
                                }
                            }
                        }
                    }

                    // Tab 1: Speed curve chart
                    ColumnLayout {
                        spacing: Kirigami.Units.smallSpacing

                        PlasmaComponents.Label {
                            visible: root.profileInfo === null && !root.loading
                            text: "No curve data available."
                            color: Kirigami.Theme.disabledTextColor
                            Layout.fillWidth: true
                        }

                        // Curve details
                        RowLayout {
                            visible: root.profileInfo !== null
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.largeSpacing

                            PlasmaComponents.Label {
                                text: "Update: " + (root.profileInfo ? root.profileInfo.fanSpeedUpdateFrequency + "s" : "")
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                color: Kirigami.Theme.disabledTextColor
                            }
                            PlasmaComponents.Label {
                                text: "Avg window: " + (root.profileInfo ? root.profileInfo.movingAverageInterval + "s" : "")
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                color: Kirigami.Theme.disabledTextColor
                            }
                        }

                        Canvas {
                            id: speedCurveCanvas
                            visible: root.profileInfo !== null && root.profileInfo.speedCurve !== undefined
                            Layout.fillWidth: true
                            height: Kirigami.Units.gridUnit * 9

                            property real padL: 42
                            property real padR: 10
                            property real padT: 10
                            property real padB: 28
                            property real chartMaxTemp: 60

                            function px(temp)  { return padL + (temp / chartMaxTemp) * (width - padL - padR) }
                            function py(speed) { return padT + (1 - speed / 100) * (height - padT - padB) }

                            Connections {
                                target: root
                                function onProfileInfoChanged() {
                                    if (root.profileInfo && root.profileInfo.speedCurve) {
                                        var maxT = 60
                                        var curve = root.profileInfo.speedCurve
                                        for (var i = 0; i < curve.length; i++) {
                                            if (curve[i].temp > maxT) maxT = curve[i].temp
                                        }
                                        speedCurveCanvas.chartMaxTemp = maxT
                                    }
                                    speedCurveCanvas.requestPaint()
                                }
                                function onStatusInfoChanged() {
                                    speedCurveCanvas.requestPaint()
                                }
                            }

                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                if (!root.profileInfo || !root.profileInfo.speedCurve) return
                                var curve = root.profileInfo.speedCurve
                                if (curve.length < 2) return

                                var cw = width - padL - padR
                                var ch = height - padT - padB
                                var textCol = Kirigami.Theme.textColor
                                var gridCol = Qt.rgba(textCol.r, textCol.g, textCol.b, 0.15)
                                var lineCol = Kirigami.Theme.highlightColor
                                var fillCol = Qt.rgba(lineCol.r, lineCol.g, lineCol.b, 0.25)

                                // Grid
                                ctx.strokeStyle = gridCol; ctx.lineWidth = 1
                                ;[25, 50, 75, 100].forEach(function(pct) {
                                    var y = py(pct)
                                    ctx.beginPath(); ctx.moveTo(padL, y); ctx.lineTo(padL + cw, y); ctx.stroke()
                                })

                                // Axes
                                ctx.strokeStyle = textCol; ctx.lineWidth = 1
                                ctx.beginPath(); ctx.moveTo(padL, padT); ctx.lineTo(padL, padT + ch); ctx.lineTo(padL + cw, padT + ch); ctx.stroke()

                                // Fill
                                ctx.fillStyle = fillCol; ctx.beginPath()
                                ctx.moveTo(px(curve[0].temp), py(curve[0].speed))
                                for (var i = 1; i < curve.length; i++) ctx.lineTo(px(curve[i].temp), py(curve[i].speed))
                                ctx.lineTo(px(curve[curve.length - 1].temp), padT + ch)
                                ctx.lineTo(px(curve[0].temp), padT + ch)
                                ctx.closePath(); ctx.fill()

                                // Line
                                ctx.strokeStyle = lineCol; ctx.lineWidth = 2; ctx.beginPath()
                                ctx.moveTo(px(curve[0].temp), py(curve[0].speed))
                                for (var i = 1; i < curve.length; i++) ctx.lineTo(px(curve[i].temp), py(curve[i].speed))
                                ctx.stroke()

                                // Current temp marker
                                if (root.statusInfo && root.statusInfo.effectiveTemperature !== undefined) {
                                    var curTemp = root.statusInfo.effectiveTemperature
                                    if (curTemp > 0 && curTemp <= chartMaxTemp) {
                                        var markerX = px(curTemp)
                                        ctx.strokeStyle = Kirigami.Theme.negativeTextColor
                                        ctx.lineWidth = 1
                                        ctx.setLineDash([4, 3])
                                        ctx.beginPath(); ctx.moveTo(markerX, padT); ctx.lineTo(markerX, padT + ch); ctx.stroke()
                                        ctx.setLineDash([])

                                        ctx.fillStyle = Kirigami.Theme.negativeTextColor
                                        ctx.font = "bold 10px sans-serif"
                                        ctx.textAlign = "center"; ctx.textBaseline = "bottom"
                                        ctx.fillText(curTemp + "\u00B0", markerX, padT - 1)
                                    }
                                }

                                // Dots
                                ctx.fillStyle = lineCol
                                for (var i = 0; i < curve.length; i++) {
                                    ctx.beginPath(); ctx.arc(px(curve[i].temp), py(curve[i].speed), 3, 0, Math.PI * 2); ctx.fill()
                                }

                                // Y labels
                                ctx.fillStyle = textCol; ctx.font = "10px sans-serif"
                                ctx.textAlign = "right"; ctx.textBaseline = "middle"
                                ;[[0, "0%"], [50, "50%"], [100, "100%"]].forEach(function(pair) {
                                    ctx.fillText(pair[1], padL - 4, py(pair[0]))
                                })

                                // X labels
                                ctx.textAlign = "center"; ctx.textBaseline = "top"
                                var numXLabels = 6
                                for (var j = 0; j <= numXLabels; j++) {
                                    var t = Math.round(chartMaxTemp * j / numXLabels)
                                    ctx.fillText(t + "\u00B0", px(t), padT + ch + 4)
                                }
                            }

                            MouseArea {
                                id: chartMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                                property int hoveredIndex: -1

                                onPositionChanged: function(mouse) {
                                    if (!root.profileInfo || !root.profileInfo.speedCurve) { hoveredIndex = -1; return }
                                    var curve = root.profileInfo.speedCurve
                                    var best = -1, bestDist = 144
                                    for (var i = 0; i < curve.length; i++) {
                                        var dx = mouse.x - speedCurveCanvas.px(curve[i].temp)
                                        var dy = mouse.y - speedCurveCanvas.py(curve[i].speed)
                                        var dist = dx * dx + dy * dy
                                        if (dist < bestDist) { bestDist = dist; best = i }
                                    }
                                    hoveredIndex = best
                                }
                                onExited: hoveredIndex = -1

                                QQC2.ToolTip {
                                    visible: chartMouseArea.hoveredIndex >= 0
                                    x: chartMouseArea.hoveredIndex >= 0 ? speedCurveCanvas.px(root.profileInfo.speedCurve[chartMouseArea.hoveredIndex].temp) - width / 2 : 0
                                    y: chartMouseArea.hoveredIndex >= 0 ? speedCurveCanvas.py(root.profileInfo.speedCurve[chartMouseArea.hoveredIndex].speed) - height - 6 : 0
                                    text: {
                                        if (chartMouseArea.hoveredIndex < 0) return ""
                                        var pt = root.profileInfo.speedCurve[chartMouseArea.hoveredIndex]
                                        return pt.temp + "\u00B0C \u2014 " + pt.speed + "%"
                                    }
                                }
                            }
                        }
                    }

                    // Tab 2: GPU selector
                    ColumnLayout {
                        spacing: Kirigami.Units.smallSpacing

                        PlasmaComponents.Label {
                            text: "Compositor GPU"
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            color: Kirigami.Theme.disabledTextColor
                            Layout.fillWidth: true
                        }

                        PlasmaComponents.ItemDelegate {
                            Layout.fillWidth: true
                            text: "iGPU \u2014 AMD Radeon 890M"
                            icon.name: root.gpuMode === "igpu" ? "dialog-ok-apply" : ""
                            highlighted: root.gpuMode === "igpu"
                            enabled: !root.gpuSwitching && root.gpuMode !== "unknown"

                            onClicked: {
                                if (root.gpuMode !== "igpu") {
                                    root.gpuSwitching = true
                                    runCommand("gpuselect", "gpu-select igpu")
                                }
                            }
                        }

                        PlasmaComponents.ItemDelegate {
                            Layout.fillWidth: true
                            text: "dGPU \u2014 NVIDIA RTX 5070"
                            icon.name: root.gpuMode === "dgpu" ? "dialog-ok-apply" : ""
                            highlighted: root.gpuMode === "dgpu"
                            enabled: !root.gpuSwitching && root.gpuMode !== "unknown"

                            onClicked: {
                                if (root.gpuMode !== "dgpu") {
                                    root.gpuSwitching = true
                                    runCommand("gpuselect", "gpu-select dgpu")
                                }
                            }
                        }

                        PlasmaComponents.Label {
                            text: root.gpuSwitching ? "Switching, logging out\u2026"
                                : root.gpuMode === "dgpu" ? "Full refresh rate on external displays.\nSwitching will log you out."
                                : root.gpuMode === "igpu" ? "Best battery life, dGPU can sleep.\nSwitching will log you out."
                                : "Detecting\u2026"
                            color: root.gpuSwitching ? Kirigami.Theme.neutralTextColor : Kirigami.Theme.disabledTextColor
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }

    // Context menu
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: "Refresh"
            icon.name: "view-refresh"
            onTriggered: { root.loading = true; root.errorMessage = ""; refreshAll() }
        },
        PlasmaCore.Action {
            text: "Reload Config"
            icon.name: "document-revert"
            onTriggered: runCommand("reload", "fw-fanctrl reload")
        },
        PlasmaCore.Action {
            text: root.serviceActive ? "Pause" : "Resume"
            icon.name: root.serviceActive ? "media-playback-pause" : "media-playback-start"
            onTriggered: runCommand("toggle", root.serviceActive ? "fw-fanctrl pause" : "fw-fanctrl resume")
        }
    ]

    // Command execution with tagged routing
    property var pendingCommands: ({})

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            var stdout = (data["stdout"] || "").trim()
            var stderr = (data["stderr"] || "").trim()
            var exitCode = data["exit code"] !== undefined ? data["exit code"] : 0
            executable.disconnectSource(sourceName)

            var tag = root.pendingCommands[sourceName] || ""
            delete root.pendingCommands[sourceName]

            if (tag === "list") {
                handleListOutput(stdout, stderr, exitCode)
            } else if (tag === "status") {
                handleStatusOutput(stdout, stderr, exitCode)
            } else if (tag === "use" || tag === "reset") {
                if (exitCode !== 0) {
                    root.errorMessage = stderr !== "" ? stderr : "Command failed (exit " + exitCode + ")"
                    root.loading = false
                } else {
                    runCommand("status", "fw-fanctrl --output-format JSON print")
                }
            } else if (tag === "reload" || tag === "toggle") {
                runCommand("status", "fw-fanctrl --output-format JSON print")
            } else if (tag === "gpudetect") {
                if (stdout.indexOf("NVIDIA") >= 0) {
                    root.gpuMode = "dgpu"
                } else if (stdout.indexOf("AMD") >= 0) {
                    root.gpuMode = "igpu"
                }
            } else if (tag === "gpuselect") {
                if (exitCode !== 0) {
                    root.gpuSwitching = false
                    root.errorMessage = "GPU switch failed: " + (stderr !== "" ? stderr : "exit " + exitCode)
                }
            }
        }
    }

    function runCommand(tag, cmd) {
        root.pendingCommands[cmd] = tag
        executable.connectSource(cmd)
    }

    function handleListOutput(stdout, stderr, exitCode) {
        if (exitCode !== 0 || stdout === "") {
            root.errorMessage = stderr !== "" ? stderr : "fw-fanctrl list failed"
            root.loading = false
            return
        }
        try {
            var result = JSON.parse(stdout)
            if (result.strategies && Array.isArray(result.strategies)) {
                root.availableProfiles = result.strategies
                root.errorMessage = ""
            }
        } catch (e) {
            root.errorMessage = "Parse error: " + e.message
        }
        root.loading = false
    }

    function handleStatusOutput(stdout, stderr, exitCode) {
        if (exitCode !== 0 || stdout === "") {
            root.errorMessage = stderr !== "" ? stderr : "fw-fanctrl status failed"
            root.loading = false
            return
        }
        try {
            var result = JSON.parse(stdout)
            if (typeof result.strategy === "string") root.currentProfile = result.strategy
            root.serviceActive = result.active === true
            root.errorMessage = ""
            root.statusInfo = {
                speed: result.speed,
                temperature: result.temperature,
                movingAverageTemperature: result.movingAverageTemperature,
                effectiveTemperature: result.effectiveTemperature,
                active: result.active,
                "default": result["default"]
            }
            try {
                var strategies = result.configuration.data.strategies
                if (strategies && strategies[result.strategy]) {
                    root.profileInfo = strategies[result.strategy]
                }
            } catch (pe) {
                root.profileInfo = null
            }
        } catch (e) {
            root.errorMessage = "Parse error: " + e.message
        }
        root.loading = false
    }

    function applyProfile(profile) {
        root.loading = true
        root.errorMessage = ""
        runCommand("use", "fw-fanctrl use " + profile)
    }

    function refreshAll() {
        runCommand("list", "fw-fanctrl --output-format JSON print list")
        runCommand("status", "fw-fanctrl --output-format JSON print")
        runCommand("gpudetect", "qdbus6 org.kde.KWin /KWin org.kde.KWin.supportInformation 2>/dev/null | grep 'OpenGL renderer'")
    }

    Timer {
        id: pollTimer
        interval: root.refreshInterval
        repeat: true
        running: true
        onTriggered: runCommand("status", "fw-fanctrl --output-format JSON print")
    }

    Component.onCompleted: refreshAll()
}

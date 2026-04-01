import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami 2.20 as Kirigami

PlasmoidItem {
    id: root

    property string statusText: "..."
    property bool charging: false
    property string cpuTemp: ""
    property string gpuTemp: ""

    preferredRepresentation: compactRepresentation

    compactRepresentation: RowLayout {
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            source: root.charging ? "battery-charging" : "battery"
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
        }

        PlasmaComponents.Label {
            text: root.statusText
            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
            Layout.alignment: Qt.AlignVCenter
        }

        Kirigami.Icon {
            source: "cpu"
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
            visible: root.cpuTemp !== ""
            opacity: 0.7
        }

        PlasmaComponents.Label {
            text: root.cpuTemp
            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
            opacity: 0.7
            Layout.alignment: Qt.AlignVCenter
            visible: root.cpuTemp !== ""
        }

        Kirigami.Icon {
            source: "graphics"
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
            visible: root.gpuTemp !== ""
            opacity: 0.7
        }

        PlasmaComponents.Label {
            text: root.gpuTemp
            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
            opacity: 0.7
            Layout.alignment: Qt.AlignVCenter
            visible: root.gpuTemp !== ""
        }
    }

    fullRepresentation: ColumnLayout {
        spacing: Kirigami.Units.largeSpacing
        Layout.preferredWidth: Kirigami.Units.gridUnit * 14
        Layout.preferredHeight: Kirigami.Units.gridUnit * 6

        PlasmaComponents.Label {
            text: root.charging ? "Charging" : "Discharging"
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        PlasmaComponents.Label {
            text: root.statusText
            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 2
            Layout.alignment: Qt.AlignHCenter
        }

        PlasmaComponents.Label {
            text: "CPU: " + root.cpuTemp + (root.gpuTemp !== "" ? "  GPU: " + root.gpuTemp : "")
            Layout.alignment: Qt.AlignHCenter
            visible: root.cpuTemp !== ""
        }
    }

    Plasma5Support.DataSource {
        id: batterySource
        engine: "executable"
        connectedSources: [
            "cat /sys/class/power_supply/BAT1/current_now /sys/class/power_supply/BAT1/voltage_now /sys/class/power_supply/BAT1/status; grep -l k10temp /sys/class/hwmon/hwmon*/name 2>/dev/null | sed 's/name$/temp1_input/' | xargs cat 2>/dev/null; for h in /sys/class/hwmon/hwmon*/name; do if grep -q nvidia $h 2>/dev/null; then cat ${h%name}temp1_input 2>/dev/null; break; fi; done"
        ]
        interval: 3000

        onNewData: function(source, data) {
            var lines = data["stdout"].trim().split("\n");
            if (lines.length < 3) return;

            var currentUa = parseInt(lines[0]) || 0;
            var voltageUv = parseInt(lines[1]) || 0;
            var status = lines[2].trim();

            var watts = (currentUa * voltageUv) / 1000000000000;
            root.charging = (status === "Charging");

            if (status === "Full") {
                root.statusText = "Full";
            } else if (status === "Not charging") {
                root.statusText = "AC";
            } else if (root.charging) {
                root.statusText = "+" + watts.toFixed(1) + "W";
            } else {
                root.statusText = watts.toFixed(1) + "W";
            }

            // CPU temp (line 4 if present)
            if (lines.length >= 4) {
                var cpuMilli = parseInt(lines[3]) || 0;
                root.cpuTemp = Math.round(cpuMilli / 1000) + "°C";
            }

            // GPU temp (line 5 if nvidia hwmon exists and GPU is awake)
            if (lines.length >= 5 && lines[4].trim() !== "") {
                var gpuMilli = parseInt(lines[4]) || 0;
                if (gpuMilli > 0) {
                    root.gpuTemp = Math.round(gpuMilli / 1000) + "°C";
                } else {
                    root.gpuTemp = "";
                }
            } else {
                root.gpuTemp = "";
            }
        }
    }
}

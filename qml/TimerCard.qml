import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

Rectangle {
    id: root

    required property var timer
    property bool flash: false

    radius: 18
    color: flash ? Theme.tint(Theme.timer, 0.28) : Theme.card
    Behavior on color { ColorAnimation { duration: 250 } }

    // ------------------------------------------------------------ presets
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8
        visible: !root.timer.active

        RowLayout {
            spacing: 6
            Icon { name: "timer"; size: 14; color: Theme.timer }
            Text {
                text: root.flash ? "Время вышло!" : "Фокус"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: root.flash ? Theme.timer : Theme.text
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 2
            rowSpacing: 6
            columnSpacing: 6

            Repeater {
                model: [5, 15, 25, 45]
                delegate: Rectangle {
                    id: preset
                    required property int modelData
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 10
                    color: presetMouse.containsMouse ? Theme.tint(Theme.timer, 0.25) : Theme.track
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: preset.modelData + " мин"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: Theme.text
                    }
                    MouseArea {
                        id: presetMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.timer.startMinutes(preset.modelData)
                    }
                }
            }
        }
    }

    // ------------------------------------------------------------ running
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6
        visible: root.timer.active

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            readonly property real ringSize: Math.min(width, height)

            Shape {
                id: ring
                width: parent.ringSize
                height: parent.ringSize
                anchors.centerIn: parent
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeColor: Theme.track
                    strokeWidth: 6
                    fillColor: "transparent"
                    PathAngleArc {
                        centerX: ring.width / 2; centerY: ring.height / 2
                        radiusX: (ring.width - 7) / 2; radiusY: (ring.height - 7) / 2
                        startAngle: 0; sweepAngle: 360
                    }
                }
                ShapePath {
                    strokeColor: Theme.timer
                    strokeWidth: 6
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathAngleArc {
                        centerX: ring.width / 2; centerY: ring.height / 2
                        radiusX: (ring.width - 7) / 2; radiusY: (ring.height - 7) / 2
                        startAngle: -90
                        sweepAngle: 360 * Math.max(0.005, 1 - root.timer.progress)
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: root.timer.remainingText
                font.pixelSize: 17
                font.weight: Font.Bold
                font.family: Theme.mono
                color: root.timer.running ? Theme.text : Theme.textSecondary
            }
        }

        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6
            IconButton {
                icon: root.timer.running ? "pause" : "play"
                iconSize: 13
                size: 28
                background: true
                onClicked: root.timer.toggle()
            }
            IconButton {
                icon: "plus"
                iconSize: 13
                size: 28
                background: true
                onClicked: root.timer.addMinutes(5)
            }
            IconButton {
                icon: "reset"
                iconSize: 13
                size: 28
                background: true
                onClicked: root.timer.reset()
            }
        }
    }
}

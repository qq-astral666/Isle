import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property var media

    radius: 18
    color: Theme.card

    // ------------------------------------------------------------- empty
    Column {
        anchors.centerIn: parent
        spacing: 6
        visible: !root.media.available

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: "music"
            size: 26
            color: Theme.textTertiary
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Ничего не играет"
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: Theme.textSecondary
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Включи музыку в Spotify или «Музыке»"
            font.pixelSize: 11
            color: Theme.textTertiary
        }
    }

    // ----------------------------------------------------------- playing
    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 14
        visible: root.media.available

        Item {
            Layout.preferredWidth: 88
            Layout.preferredHeight: 88
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                anchors.fill: parent
                radius: 14
                color: Theme.track
                visible: !art.ready
                Icon {
                    anchors.centerIn: parent
                    name: "music"
                    size: 30
                    color: Theme.textTertiary
                }
            }
            RoundedImage {
                id: art
                anchors.fill: parent
                radius: 14
                source: root.media.artworkSource
                scale: root.media.playing ? 1.0 : 0.92
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Text {
                    Layout.fillWidth: true
                    text: root.media.title
                    elide: Text.ElideRight
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    color: Theme.text
                }
                EqBars {
                    visible: root.media.playing
                    maxHeight: 12
                    barWidth: 2.5
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.media.artist + (root.media.appName !== "" ? "  ·  " + root.media.appName : "")
                elide: Text.ElideRight
                font.pixelSize: 12
                color: Theme.textSecondary
            }

            Item { Layout.fillHeight: true }

            // progress
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                visible: root.media.duration > 0
                Rectangle {
                    anchors.fill: parent
                    radius: 2
                    color: Theme.track
                }
                Rectangle {
                    height: parent.height
                    radius: 2
                    color: Theme.text
                    width: parent.width * Math.min(1, root.media.position / Math.max(1, root.media.duration))
                    Behavior on width { NumberAnimation { duration: 250 } }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                visible: root.media.duration > 0
                Text {
                    text: root.media.formatTime(root.media.position)
                    font.pixelSize: 10
                    font.family: Theme.mono
                    color: Theme.textTertiary
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "-" + root.media.formatTime(root.media.duration - root.media.position)
                    font.pixelSize: 10
                    font.family: Theme.mono
                    color: Theme.textTertiary
                }
            }

            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 14
                IconButton { icon: "prev"; iconSize: 17; onClicked: root.media.previous() }
                IconButton {
                    icon: root.media.playing ? "pause" : "play"
                    iconSize: 20
                    size: 34
                    onClicked: root.media.togglePlay()
                }
                IconButton { icon: "next"; iconSize: 17; onClicked: root.media.next() }
            }
        }
    }
}

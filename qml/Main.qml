import QtQuick
import QtQuick.Layouts
import Isle

// A transparent window over the notch. Only the black NotchShape is
// visible; the C++ controller makes the rest click-through.
Window {
    id: win

    required property NotchController notch
    readonly property var media: notch.media
    readonly property var timer: notch.timer

    width: notch.windowWidth
    height: notch.windowHeight
    visible: false
    color: "transparent"
    title: "Isle"
    flags: Qt.FramelessWindowHint | Qt.Tool | Qt.WindowStaysOnTopHint | Qt.NoDropShadowWindowHint

    readonly property bool expanded: notch.expanded
    readonly property bool musicActivity: media.available && media.playing && notch.showMediaCollapsed
    readonly property bool timerActivity: timer.active
    readonly property bool hasActivity: musicActivity || timerActivity
    readonly property int nh: notch.notchHeight
    readonly property int wing: timerActivity ? nh + 30 : nh + 8

    readonly property size collapsedSize: Qt.size(notch.notchWidth + (hasActivity ? 2 * wing : 0), nh)
    readonly property size expandedSize: Qt.size(660, nh + 168)

    Binding { target: win.notch; property: "collapsedSize"; value: win.collapsedSize }
    Binding { target: win.notch; property: "expandedSize"; value: win.expandedSize }

    Connections {
        target: win.notch
        function onToast(message) { toast.show(message) }
    }

    // Drops land anywhere on the expanded island.
    DropArea {
        anchors.fill: island
        enabled: win.expanded
        onDropped: (drop) => {
            if (drop.hasUrls) {
                win.notch.addFiles(drop.urls)
                drop.acceptProposedAction()
            }
        }
    }

    NotchShape {
        id: island

        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        targetWidth: win.expanded ? win.expandedSize.width : win.collapsedSize.width
        targetHeight: win.expanded ? win.expandedSize.height : win.collapsedSize.height
        targetRadius: win.expanded ? 32 : Math.round(win.nh * 0.32)
        targetEar: win.expanded ? 14 : 6

        // ------------------------------------------------ collapsed: wings
        Item {
            anchors.fill: parent
            opacity: !win.expanded && win.hasActivity ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            // left wing
            Item {
                x: 0
                width: win.wing
                height: win.nh

                RoundedImage {
                    anchors.centerIn: parent
                    width: win.nh - 12
                    height: width
                    radius: 5
                    visible: win.musicActivity
                    source: win.media.artworkSource
                }
                Icon {
                    anchors.centerIn: parent
                    visible: !win.musicActivity && win.timerActivity
                    name: "timer"
                    size: win.nh - 16
                    color: Theme.timer
                }
            }

            // right wing
            Item {
                x: parent.width - width
                width: win.wing
                height: win.nh

                Text {
                    anchors.centerIn: parent
                    visible: win.timerActivity
                    text: win.timer.remainingText
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    font.family: Theme.mono
                    color: win.timer.running ? Theme.timer : Theme.textSecondary
                }
                EqBars {
                    anchors.centerIn: parent
                    visible: !win.timerActivity && win.musicActivity
                    playing: win.media.playing
                    maxHeight: win.nh - 16
                }
            }
        }

        // ------------------------------------------------ expanded: panel
        Item {
            id: panel
            anchors.fill: parent
            opacity: win.expanded ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: win.expanded ? 260 : 120 } }

            // Top band sits beside the camera housing.
            Item {
                id: band
                x: 20
                width: parent.width - 40
                height: win.nh

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 7
                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        anchors.verticalCenter: parent.verticalCenter
                        color: win.media.playing ? Theme.music : Theme.accent
                    }
                    Text {
                        text: win.notch.settingsOpen ? "Настройки" : "Isle"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: Theme.textSecondary
                    }
                }

                IconButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    size: Math.min(28, win.nh - 4)
                    icon: win.notch.settingsOpen ? "back" : "settings"
                    iconSize: 14
                    color: Theme.textSecondary
                    onClicked: win.notch.settingsOpen = !win.notch.settingsOpen
                }
            }

            RowLayout {
                visible: !win.notch.settingsOpen
                anchors.top: band.bottom
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                anchors.bottomMargin: 14
                spacing: 10

                MediaCard {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 300
                    media: win.media
                }
                TimerCard {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 138
                    timer: win.timer
                    flash: win.notch.timerFlash
                }
                ShelfCard {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    notch: win.notch
                }
            }

            SettingsPanel {
                visible: win.notch.settingsOpen
                anchors.top: band.bottom
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                anchors.bottomMargin: 14
                notch: win.notch
            }

            // toast
            Rectangle {
                id: toast

                function show(message) {
                    toastText.text = message
                    opacity = 1
                    toastTimer.restart()
                }

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 20
                width: toastText.implicitWidth + 26
                height: 30
                radius: 15
                color: "#2c2c30"
                opacity: 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 160 } }

                Text {
                    id: toastText
                    anchors.centerIn: parent
                    font.pixelSize: 12
                    color: "white"
                }
                Timer {
                    id: toastTimer
                    interval: 1800
                    onTriggered: toast.opacity = 0
                }
            }
        }
    }
}

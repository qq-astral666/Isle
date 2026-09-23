import QtQuick
import QtQuick.Layouts

// Drop files here, drag them out later in any app.
Rectangle {
    id: root

    required property var notch
    readonly property var shelf: notch.shelf
    readonly property bool dropping: notch.dragHover

    radius: 18
    color: dropping ? Theme.tint(Theme.shelf, 0.22) : Theme.card
    border.width: dropping ? 2 : 0
    border.color: Theme.shelf
    Behavior on color { ColorAnimation { duration: 150 } }

    // --------------------------------------------------------------- empty
    Column {
        anchors.centerIn: parent
        spacing: 6
        visible: root.shelf.count === 0

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: "tray"
            size: 26
            color: root.dropping ? Theme.shelf : Theme.textTertiary
            scale: root.dropping ? 1.15 : 1.0
            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.dropping ? "Отпусти, чтобы положить" : "Полка"
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: root.dropping ? Theme.shelf : Theme.textSecondary
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !root.dropping
            text: "Перетащи файлы на чёлку"
            font.pixelSize: 11
            color: Theme.textTertiary
        }
    }

    // --------------------------------------------------------------- files
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6
        visible: root.shelf.count > 0

        RowLayout {
            Layout.fillWidth: true
            Icon { name: "tray"; size: 13; color: Theme.shelf }
            Text {
                text: "Полка · " + root.shelf.count
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: Theme.text
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "Очистить"
                font.pixelSize: 11
                color: clearMouse.containsMouse ? Theme.text : Theme.textTertiary
                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.shelf.clear()
                }
            }
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            orientation: ListView.Horizontal
            spacing: 6
            clip: true
            model: root.shelf
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                id: tile

                required property int index
                required property string path
                required property string name
                required property string fileUrl
                required property string iconKey
                required property string sizeText

                width: 68
                height: ListView.view.height

                // Invisible handle for the drag gesture, so the tile itself
                // doesn't fly around while a native drag is in progress.
                Item {
                    id: handle
                    width: 1
                    height: 1
                    Drag.active: dragArea.drag.active
                    Drag.dragType: Drag.Automatic
                    Drag.supportedActions: Qt.CopyAction
                    Drag.mimeData: ({ "text/uri-list": tile.fileUrl + "\r\n", "text/plain": tile.path })
                    Drag.imageSource: "image://img/" + tile.iconKey
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: dragArea.containsMouse ? Theme.cardHover : "transparent"
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 3

                    Image {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 40
                        height: 40
                        source: "image://img/" + tile.iconKey
                        sourceSize.width: 80
                        sourceSize.height: 80
                        asynchronous: true
                        smooth: true
                        opacity: dragArea.drag.active ? 0.4 : 1
                    }
                    Text {
                        width: 62
                        horizontalAlignment: Text.AlignHCenter
                        text: tile.name
                        elide: Text.ElideMiddle
                        font.pixelSize: 10
                        color: Theme.text
                    }
                    Text {
                        width: 62
                        horizontalAlignment: Text.AlignHCenter
                        text: tile.sizeText
                        font.pixelSize: 9
                        color: Theme.textTertiary
                    }
                }

                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    drag.target: handle
                    cursorShape: Qt.OpenHandCursor
                    onDoubleClicked: root.notch.openFile(tile.path)
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton)
                            root.notch.revealFile(tile.path)
                    }
                    onReleased: { handle.x = 0; handle.y = 0 }
                }

                // remove
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 2
                    width: 16
                    height: 16
                    radius: 8
                    color: removeMouse.containsMouse ? Theme.danger : Theme.track
                    visible: dragArea.containsMouse || removeMouse.containsMouse
                    Icon {
                        anchors.centerIn: parent
                        name: "close"
                        size: 9
                        strokeWidth: 3
                        color: "white"
                    }
                    MouseArea {
                        id: removeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.shelf.remove(tile.index)
                    }
                }
            }
        }
    }
}

import QtQuick

Item {
    id: root

    property string icon: ""
    property real iconSize: 16
    property color color: Theme.text
    property real size: 30
    property bool background: false
    signal clicked()

    width: size
    height: size

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.background ? Theme.card : (mouse.containsMouse ? Theme.card : "transparent")
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    Icon {
        anchors.centerIn: parent
        name: root.icon
        size: root.iconSize
        color: root.color
        scale: mouse.pressed ? 0.86 : 1.0
        Behavior on scale { NumberAnimation { duration: 90 } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

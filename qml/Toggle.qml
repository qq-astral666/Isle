import QtQuick

Rectangle {
    id: root

    property bool checked: false
    signal toggled(bool value)

    implicitWidth: 36
    implicitHeight: 21
    radius: height / 2
    color: checked ? Theme.accent : Theme.track
    Behavior on color { ColorAnimation { duration: 140 } }

    Rectangle {
        width: parent.height - 4
        height: width
        radius: width / 2
        y: 2
        x: root.checked ? root.width - width - 2 : 2
        color: "white"
        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}

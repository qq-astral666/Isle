import QtQuick

// Little "sound is playing" equalizer.
Row {
    id: root

    property bool playing: true
    property color color: Theme.music
    property real barWidth: 3
    property real maxHeight: 14

    spacing: 2
    height: maxHeight

    Repeater {
        model: 4
        delegate: Rectangle {
            id: bar
            required property int index
            property real level: 0.3
            anchors.bottom: parent.bottom
            width: root.barWidth
            height: Math.max(root.barWidth, root.maxHeight * (root.playing ? level : 0.2))
            radius: width / 2
            color: root.color
            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

            Timer {
                interval: 170 + bar.index * 40
                repeat: true
                running: root.playing && root.visible
                onTriggered: bar.level = 0.25 + Math.random() * 0.75
            }
        }
    }
}

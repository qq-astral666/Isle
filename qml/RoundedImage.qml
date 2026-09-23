import QtQuick
import QtQuick.Effects

Item {
    id: root

    property alias source: image.source
    property real radius: 8
    readonly property bool ready: image.status === Image.Ready

    Image {
        id: image
        anchors.fill: parent
        visible: false
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        mipmap: true
        sourceSize.width: Math.max(1, root.width * 2)
        sourceSize.height: Math.max(1, root.height * 2)
    }

    Rectangle {
        id: mask
        anchors.fill: parent
        radius: root.radius
        visible: false
        layer.enabled: true
    }

    MultiEffect {
        anchors.fill: parent
        source: image
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
        visible: root.ready
    }
}

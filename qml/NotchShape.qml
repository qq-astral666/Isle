import QtQuick
import QtQuick.Shapes

// The black "island": flush with the top of the screen, rounded bottom
// corners and small concave "ears" where it meets the menu bar — the same
// silhouette as the MacBook notch, so collapsed it blends into the hardware.
// Size changes are springy, like Dynamic Island.
Item {
    id: root

    property real targetWidth: 200
    property real targetHeight: 32
    property real targetRadius: 10
    property real targetEar: 6
    default property alias content: contentItem.data

    property real w: targetWidth
    property real h: targetHeight
    property real r: targetRadius
    property real ear: targetEar

    Behavior on w { SpringAnimation { spring: 4.2; damping: 0.36; epsilon: 0.2 } }
    Behavior on h { SpringAnimation { spring: 4.2; damping: 0.40; epsilon: 0.2 } }
    Behavior on r { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    Behavior on ear { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

    readonly property real safeR: Math.max(0, Math.min(r, h / 2, w / 2))
    readonly property real safeEar: Math.max(0, Math.min(ear, h - safeR))

    width: w + 2 * safeEar
    height: h

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: Theme.notch
            strokeColor: "transparent"
            strokeWidth: 0
            startX: 0
            startY: 0

            // left ear
            PathQuad { x: root.safeEar; y: root.safeEar; controlX: root.safeEar; controlY: 0 }
            PathLine { x: root.safeEar; y: root.h - root.safeR }
            // bottom-left corner
            PathQuad { x: root.safeEar + root.safeR; y: root.h; controlX: root.safeEar; controlY: root.h }
            PathLine { x: root.safeEar + root.w - root.safeR; y: root.h }
            // bottom-right corner
            PathQuad { x: root.safeEar + root.w; y: root.h - root.safeR; controlX: root.safeEar + root.w; controlY: root.h }
            PathLine { x: root.safeEar + root.w; y: root.safeEar }
            // right ear
            PathQuad { x: root.w + 2 * root.safeEar; y: 0; controlX: root.safeEar + root.w; controlY: 0 }
            PathLine { x: 0; y: 0 }
        }
    }

    Item {
        id: contentItem
        x: root.safeEar
        width: root.w
        height: root.h
        clip: true
    }
}

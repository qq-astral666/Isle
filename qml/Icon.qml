import QtQuick
import QtQuick.Shapes

// SVG-path icons on a 24×24 grid. `filled` icons (play/pause) are drawn
// solid, the rest as strokes.
Item {
    id: root

    property string name: ""
    property color color: "white"
    property real size: 16
    property real strokeWidth: 2

    readonly property var strokes: ({
        "music": "M9 18V5l11 -2v13 M6 21a3 3 0 1 0 0 -6a3 3 0 0 0 0 6z M17 19a3 3 0 1 0 0 -6a3 3 0 0 0 0 6z",
        "timer": "M12 22a8 8 0 1 0 0 -16a8 8 0 0 0 0 16z M12 10v4l2 2 M10 2h4 M12 2v4",
        "tray": "M3 13l3 -8h12l3 8 M3 13v6h18v-6 M3 13h5l1.5 2.5h5L16 13h5",
        "settings": "M4 6h9 M17 6h3 M4 12h3 M11 12h9 M4 18h11 M19 18h1 M15 4v4 M9 10v4 M17 16v4",
        "back": "M15 18l-6 -6l6 -6",
        "close": "M6 6l12 12 M18 6L6 18",
        "reset": "M3 12a9 9 0 1 0 3 -6.7 M3 4v5h5",
        "plus": "M12 5v14 M5 12h14",
        "power": "M12 3v9 M6.3 7.3a8 8 0 1 0 11.4 0",
        "folder": "M3 7a2 2 0 0 1 2 -2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1 -2 2H5a2 2 0 0 1 -2 -2z",
        "trash": "M3 6h18 M8 6V4h8v2 M6 6l1 14h10l1 -14"
    })
    readonly property var fills: ({
        "play": "M7 4.5v15a1 1 0 0 0 1.5 .86l12.5 -7.5a1 1 0 0 0 0 -1.72L8.5 3.64A1 1 0 0 0 7 4.5z",
        "pause": "M6 4h4v16H6z M14 4h4v16h-4z",
        "next": "M5 5.5v13a1 1 0 0 0 1.55 .83L15 13.2V18.5a1 1 0 0 0 2 0v-13a1 1 0 0 0 -2 0v5.3L6.55 4.67A1 1 0 0 0 5 5.5z",
        "prev": "M19 5.5v13a1 1 0 0 1 -1.55 .83L9 13.2V18.5a1 1 0 0 1 -2 0v-13a1 1 0 0 1 2 0v5.3l8.45 -6.13A1 1 0 0 1 19 5.5z"
    })
    readonly property bool isFilled: fills[name] !== undefined

    implicitWidth: size
    implicitHeight: size
    width: size
    height: size

    Shape {
        width: 24
        height: 24
        scale: root.size / 24
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.isFilled ? "transparent" : root.color
            strokeWidth: root.isFilled ? 0 : root.strokeWidth
            fillColor: root.isFilled ? root.color : "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: root.isFilled ? root.fills[root.name] : (root.strokes[root.name] ?? "") }
        }
    }
}

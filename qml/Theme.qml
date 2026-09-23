pragma Singleton
import QtQuick

// The notch is always black, so the palette is dark-only.
QtObject {
    readonly property color notch: "#000000"
    readonly property color card: Qt.rgba(1, 1, 1, 0.07)
    readonly property color cardHover: Qt.rgba(1, 1, 1, 0.11)
    readonly property color track: Qt.rgba(1, 1, 1, 0.14)
    readonly property color text: "#ffffff"
    readonly property color textSecondary: Qt.rgba(1, 1, 1, 0.62)
    readonly property color textTertiary: Qt.rgba(1, 1, 1, 0.38)
    readonly property color accent: "#a594ff"
    readonly property color timer: "#ffb340"
    readonly property color shelf: "#5ac8fa"
    readonly property color music: "#30d158"
    readonly property color danger: "#ff453a"
    readonly property string mono: Qt.platform.os === "osx" ? "Menlo" : "monospace"

    function tint(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
}

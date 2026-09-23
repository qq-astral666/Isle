import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property var notch

    radius: 18
    color: Theme.card

    component SettingToggle: RowLayout {
        id: row
        property string title
        property string subtitle
        property bool checked
        signal toggled(bool value)

        Layout.fillWidth: true
        spacing: 12

        Column {
            Layout.fillWidth: true
            spacing: 1
            Text { text: row.title; font.pixelSize: 13; color: Theme.text }
            Text {
                text: row.subtitle
                visible: row.subtitle !== ""
                font.pixelSize: 11
                color: Theme.textTertiary
            }
        }
        Toggle {
            checked: row.checked
            onToggled: (value) => row.toggled(value)
        }
    }

    GridLayout {
        anchors.fill: parent
        anchors.margins: 16
        columns: 2
        columnSpacing: 28
        rowSpacing: 10

        SettingToggle {
            title: "Музыка в свёрнутой чёлке"
            subtitle: "Обложка и эквалайзер по краям"
            checked: root.notch.showMediaCollapsed
            onToggled: (value) => root.notch.showMediaCollapsed = value
        }
        SettingToggle {
            title: "Звук таймера"
            subtitle: "Сигнал, когда время вышло"
            checked: root.notch.timerSound
            onToggled: (value) => root.notch.timerSound = value
        }
        SettingToggle {
            title: "Запускать при входе"
            subtitle: "Isle стартует вместе с macOS"
            checked: root.notch.launchAtLogin
            onToggled: (value) => root.notch.launchAtLogin = value
        }

        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: "Isle " + Qt.application.version + " · C++20 · Qt 6"
                font.pixelSize: 11
                color: Theme.textTertiary
            }
            Rectangle {
                implicitWidth: quitRow.implicitWidth + 20
                implicitHeight: 28
                radius: 14
                color: quitMouse.containsMouse ? Theme.tint(Theme.danger, 0.3) : Theme.tint(Theme.danger, 0.18)
                Row {
                    id: quitRow
                    anchors.centerIn: parent
                    spacing: 6
                    Icon { name: "power"; size: 12; color: Theme.danger; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Выйти"; font.pixelSize: 12; font.weight: Font.DemiBold; color: Theme.danger }
                }
                MouseArea {
                    id: quitMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.notch.quit()
                }
            }
        }
    }
}

import QtQuick
import "qrc:/qml" as App

Rectangle {
    id: badgeRoot
    property int status: 1

    width: 80
    height: 24
    radius: 12
    color: App.Theme.surface
    border.width: 1
    border.color: App.Theme.border

    Row {
        anchors.centerIn: parent
        spacing: 4
        Rectangle {
            width: 8
            height: 8
            radius: 4
            color: App.Theme.success
        }
        Text {
            text: "在线"
            font.family: App.Theme.fontFamily
            font.pixelSize: 10
            color: App.Theme.success
        }
    }
}

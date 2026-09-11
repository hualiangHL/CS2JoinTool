import QtQuick
import QtQuick.Controls
import "qrc:/qml" as App

Rectangle {
    id: inputRoot
    property string text: ""
    property string placeholderText: ""

    width: 280
    height: 44
    radius: App.Theme.radiusMd
    color: App.Theme.surface
    border.width: 1
    border.color: App.Theme.border

    TextField {
        id: textField
        anchors.fill: parent
        anchors.margins: App.Theme.paddingMd
        text: inputRoot.text
        placeholderText: inputRoot.placeholderText
        font.family: App.Theme.fontFamily
        font.pixelSize: App.Theme.fontMd
        color: App.Theme.textPrimary
        background: Rectangle { color: "transparent" }
    }
}
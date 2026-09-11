import QtQuick
import "qrc:/qml" as App

Rectangle {
    id: tooltipRoot
    property string text: ""
    property int timeout: 2000
    property bool visible: false

    width: contentText.implicitWidth + App.Theme.paddingMd * 2
    height: 32
    radius: App.Theme.radiusSm
    color: App.Theme.textPrimary
    opacity: visible ? 1 : 0
    z: 9999

    Behavior on opacity { NumberAnimation { duration: 200 } }

    Text {
        id: contentText
        anchors.centerIn: parent
        text: tooltipRoot.text
        font.family: App.Theme.fontFamily
        font.pixelSize: App.Theme.fontSm
        color: App.Theme.bg
    }

    Timer {
        id: hideTimer
        interval: tooltipRoot.timeout
        onTriggered: tooltipRoot.visible = false
    }

    function show(msg, x, y) {
        tooltipRoot.text = msg
        tooltipRoot.x = x
        tooltipRoot.y = y
        tooltipRoot.visible = true
        hideTimer.restart()
    }
}
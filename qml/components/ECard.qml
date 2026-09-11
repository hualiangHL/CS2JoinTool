import QtQuick
import "qrc:/qml" as App

Rectangle {
    id: cardRoot
    property bool hoverable: false
    property bool elevated: false
    signal clicked()

    radius: App.Theme.radiusLg
    color: App.Theme.card
    border.width: 1
    border.color: App.Theme.border

    Behavior on color { ColorAnimation { duration: App.Theme.durationFast } }
    Behavior on border.color { ColorAnimation { duration: App.Theme.durationFast } }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: cardRoot.hoverable
        cursorShape: cardRoot.hoverable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (cardRoot.hoverable) cardRoot.clicked()
    }
}
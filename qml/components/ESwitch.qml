import QtQuick
import "qrc:/qml" as App

Item {
    id: switchRoot
    property bool checked: false
    property string text: ""
    signal toggled(bool checked)

    width: switchRow.implicitWidth
    height: 28

    Row {
        id: switchRow
        spacing: App.Theme.spacingMd
        anchors.verticalCenter: parent.verticalCenter

        
        Rectangle {
            width: 48
            height: 28
            radius: 14
            color: switchRoot.checked ? App.Theme.primary : "transparent"
            border.width: switchRoot.checked ? 0 : 1
            border.color: switchRoot.checked ? "transparent" : "#30FFFFFF"
            Behavior on color { ColorAnimation { duration: App.Theme.durationNormal } }

            
            Rectangle {
                id: thumb
                width: 22
                height: 22
                radius: 11
                color: "#FFFFFF"
                anchors.verticalCenter: parent.verticalCenter
                x: switchRoot.checked ? parent.width - width - 3 : 3

                Behavior on x {
                    SpringAnimation {
                        spring: 3
                        damping: 0.6
                        epsilon: 0.01
                    }
                }

            }
        }

        Text {
            text: switchRoot.text
            font.family: App.Theme.fontFamily
            font.pixelSize: App.Theme.fontMd
            color: App.Theme.textPrimary
            anchors.verticalCenter: parent.verticalCenter
            visible: switchRoot.text !== ""
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            switchRoot.checked = !switchRoot.checked
            switchRoot.toggled(switchRoot.checked)
        }
    }
}


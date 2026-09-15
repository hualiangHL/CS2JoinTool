import QtQuick
import "qrc:/qml" as App

Rectangle {
    id: drawerRoot
    property var navItems: []
    property int currentIndex: 0
    signal itemClicked(int index)

    width: App.Theme.navWidth
    height: parent.height
    color: App.Theme.surface

    Column {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            width: parent.width
            height: 72
            color: "transparent"

            Row {
                anchors.centerIn: parent
                spacing: App.Theme.spacingMd

                Rectangle {
                    width: 36
                    height: 36
                    radius: 10
                    color: App.Theme.primary

                    Text {
                        anchors.centerIn: parent
                        text: "Z"
                        font.family: App.Theme.fontFamily
                        font.pixelSize: 18
                        font.bold: true
                        color: "#FFFFFF"
                    }
                }

                Column {
                    spacing: 2
                    Text {
                        text: "CS2挤服工具"
                        font.family: App.Theme.fontFamily
                        font.pixelSize: App.Theme.fontMd
                        font.bold: true
                        color: App.Theme.textPrimary
                    }
                    Text {
                        text: "v4 EvolveUI"
                        font.family: App.Theme.fontFamily
                        font.pixelSize: App.Theme.fontXs
                        color: App.Theme.textSecondary
                    }
                }
            }
        }

        Rectangle {
            width: parent.width - App.Theme.paddingLg * 2
            height: 1
            color: App.Theme.border
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Column {
            width: parent.width
            spacing: 2
            anchors.top: parent.top
            anchors.topMargin: App.Theme.spacingMd
            anchors.left: parent.left
            anchors.leftMargin: App.Theme.spacingSm
            anchors.right: parent.right
            anchors.rightMargin: App.Theme.spacingSm

            Repeater {
                model: drawerRoot.navItems

                Rectangle {
                    id: navItem
                    width: parent.width
                    height: 44
                    radius: App.Theme.radiusMd
                    color: drawerRoot.currentIndex === index ? App.Theme.primaryLight : (mouseArea.containsMouse ? App.Theme.surfaceHover : "transparent")

                    Behavior on color { ColorAnimation { duration: App.Theme.durationFast } }

                    Row {
                        anchors.centerIn: parent
                        spacing: App.Theme.spacingMd
                        anchors.left: parent.left
                        anchors.leftMargin: App.Theme.paddingMd

                        Text {
                            text: modelData.icon
                            font.pixelSize: 16
                            color: drawerRoot.currentIndex === index ? App.Theme.primary : App.Theme.textSecondary
                        }

                        Text {
                            text: modelData.name
                            font.family: App.Theme.fontFamily
                            font.pixelSize: App.Theme.fontMd
                            font.bold: drawerRoot.currentIndex === index
                            color: drawerRoot.currentIndex === index ? App.Theme.primary : App.Theme.textPrimary
                        }
                    }

                    Rectangle {
                        width: 3
                        height: 20
                        radius: 1.5
                        color: App.Theme.primary
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        visible: drawerRoot.currentIndex === index
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: drawerRoot.itemClicked(index)
                    }
                }
            }
        }

        Item {
            width: 1
            height: parent.height - 72 - 1 - 200 - 60 - 20
        }

        Rectangle {
            width: parent.width
            height: 60
            color: "transparent"

            Column {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: "CS2 Zombie Escape"
                    font.family: App.Theme.fontFamily
                    font.pixelSize: App.Theme.fontXs
                    color: App.Theme.textDisabled
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                    text: "© 2026 EvolveUI Edition"
                    font.family: App.Theme.fontFamily
                    font.pixelSize: App.Theme.fontXs
                    color: App.Theme.textDisabled
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}

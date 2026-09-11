import QtQuick
import QtQuick.Controls
import "qrc:/qml" as App

Rectangle {
    id: cardRoot
    property string serverName: "服务器名称"
    property string map: "de_map"
    property string players: "0/32"
    property string ip: "0.0.0.0:27015"
    property int status: 0
    signal connectClicked()
    signal refreshClicked()

    width: 400
    height: 90
    radius: App.Theme.radiusMd
    color: App.Theme.surface
    border.width: 1
    border.color: App.Theme.border

    Column {
        anchors.fill: parent
        anchors.margins: App.Theme.paddingMd
        spacing: App.Theme.spacingSm

        Row {
            width: parent.width
            spacing: App.Theme.spacingSm

            Rectangle {
                width: 8
                height: 8
                radius: 4
                color: cardRoot.status === 1 ? App.Theme.success : (cardRoot.status === 2 ? App.Theme.error : App.Theme.warning)
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: cardRoot.serverName
                font.family: App.Theme.fontFamily
                font.pixelSize: App.Theme.fontMd
                font.bold: true
                color: App.Theme.textPrimary
            }

            Text {
                text: cardRoot.players
                font.family: App.Theme.fontFamily
                font.pixelSize: App.Theme.fontSm
                color: App.Theme.primary
                font.bold: true
            }
        }

        Row {
            width: parent.width
            spacing: App.Theme.spacingMd

            Text {
                text: "地图: " + cardRoot.map
                font.family: App.Theme.fontFamily
                font.pixelSize: App.Theme.fontSm
                color: App.Theme.textSecondary
            }

            Text {
                text: cardRoot.ip
                font.family: App.Theme.fontFamily
                font.pixelSize: App.Theme.fontSm
                color: App.Theme.textDisabled
            }
        }

        Row {
            width: parent.width
            spacing: App.Theme.spacingSm

            Button {
                text: "连接"
                onClicked: cardRoot.connectClicked()
            }

            Button {
                text: "刷新"
                onClicked: cardRoot.refreshClicked()
            }
        }
    }
}
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "qrc:/qml" as App

Item {
    id: aboutPage
    width: parent.width
    height: parent.height
    property bool pageActive: false
    property bool showCard1: false
    property bool showCard2: false

    onPageActiveChanged: {
        if (!pageActive) { showCard1 = false; showCard2 = false }
    }

    Timer { interval: 200; repeat: false; running: pageActive; onTriggered: showCard1 = true }
    Timer { interval: 400; repeat: false; running: pageActive; onTriggered: showCard2 = true }

    Column {
        id: aboutHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 16
        spacing: 8

        Image {
            width: 56; height: 56
            source: "qrc:/assets/app_icon_128.png"
            sourceSize: Qt.size(128, 128)
            fillMode: Image.PreserveAspectFit
            mipmap: true
            smooth: true
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Text {
            text: "cs2挤服工具V4_1"
            font.bold: true; color: App.Theme.textPrimary; font.pixelSize: 18
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Text {
            text: "EvolveUI Edition"
            color: App.Theme.textSecondary; font.pixelSize: 12
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    ScrollView {
        anchors.top: aboutHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 12
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.bottomMargin: 16
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        Column {
            id: aboutColumn
            width: aboutPage.width - 32
            spacing: 16

            
            Rectangle {
                id: staggerChild0
                width: parent.width
                height: featureCol.height + 32
                radius: 12
                color: "#b01E1B2E"
                border.width: 1; border.color: App.Theme.border

                Column {
                    id: featureCol
                    width: parent.width - 32
                    anchors.centerIn: parent
                    spacing: 10

                    Text { text: "工具信息"; font.bold: true; color: App.Theme.textPrimary; font.pixelSize: 15 }
                    Text { text: "• 画凉的业余时间做的挤服工具，那你问为什么要做我只能说在学校太无聊了"; color: App.Theme.textSecondary; font.pixelSize: 12; wrapMode: Text.WordWrap; width: parent.width }
                    Text { text: "• 严禁使用挤服工具功能将人数调低恶意攻击服务器"; color: "#FF4444"; font.pixelSize: 12; font.bold: true; wrapMode: Text.WordWrap; width: parent.width }
                    Text { text: "• 如果有任何bug请联系我"; color: App.Theme.textSecondary; font.pixelSize: 12; wrapMode: Text.WordWrap; width: parent.width }
                    Text { text: "• A2S_INFO协议实时查询服务器状态"; color: App.Theme.textSecondary; font.pixelSize: 12; wrapMode: Text.WordWrap; width: parent.width }
                    Text { text: "• 地图信息来源 https://list.darkrp.cn:9000/ServerList/Cs2MapList"; color: App.Theme.textSecondary; font.pixelSize: 12; wrapMode: Text.WordWrap; width: parent.width }
                    Text { text: "• 获取预览图用 workshop ID 调用 Steam API 拿到 preview_url 并显示"; color: App.Theme.textSecondary; font.pixelSize: 12; wrapMode: Text.WordWrap; width: parent.width }
                    Text { text: "• v1 v2 v3 v4"; color: App.Theme.textSecondary; font.pixelSize: 12; wrapMode: Text.WordWrap; width: parent.width }
                }
            }

            
            Rectangle {
                id: staggerChild1
                opacity: showCard1 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                width: parent.width
                height: techCol.height + 32
                radius: 12
                color: "#b01E1B2E"
                border.width: 1; border.color: App.Theme.border

                Column {
                    id: techCol
                    width: parent.width - 32
                    anchors.centerIn: parent
                    spacing: 8

                    Text { text: "技术信息"; font.bold: true; color: App.Theme.textPrimary; font.pixelSize: 15 }

                    Grid {
                        columns: 2
                        spacing: 6
                        columnSpacing: 20
                        width: parent.width
                        Text { text: "框架:"; color: App.Theme.textSecondary; font.pixelSize: 12 }
                        Text { text: "Qt 6.11.1 (QML)"; color: App.Theme.textPrimary; font.pixelSize: 12 }
                        Text { text: "编译器:"; color: App.Theme.textSecondary; font.pixelSize: 12 }
                        Text { text: "MinGW 13.1.0"; color: App.Theme.textPrimary; font.pixelSize: 12 }
                        Text { text: "构建系统:"; color: App.Theme.textSecondary; font.pixelSize: 12 }
                        Text { text: "CMake 3.30"; color: App.Theme.textPrimary; font.pixelSize: 12 }
                        Text { text: "查询协议:"; color: App.Theme.textSecondary; font.pixelSize: 12 }
                        Text { text: "A2S_INFO (UDP)"; color: App.Theme.textPrimary; font.pixelSize: 12 }
                        Text { text: "UI参考:"; color: App.Theme.textSecondary; font.pixelSize: 12 }
                        Text { text: "EvolveUI (MIT)"; color: App.Theme.textPrimary; font.pixelSize: 12 }
                    }
                }
            }

            
            Rectangle {
                id: staggerChild2
                opacity: showCard2 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                width: parent.width
                height: thanksCol.height + 32
                radius: 12
                color: "#b01E1B2E"
                border.width: 1; border.color: App.Theme.border

                Column {
                    id: thanksCol
                    width: parent.width - 32
                    anchors.centerIn: parent
                    spacing: 8

                    Text { text: "开源致谢"; font.bold: true; color: App.Theme.textPrimary; font.pixelSize: 15 }
                    Text { text: "EvolveUI - sudoevolve/EvolveUI (MIT License)"; color: App.Theme.textSecondary; font.pixelSize: 12; wrapMode: Text.WordWrap; width: parent.width }
                    Text { text: "Qt Framework - The Qt Company (LGPL/GPL)"; color: App.Theme.textSecondary; font.pixelSize: 12; wrapMode: Text.WordWrap; width: parent.width }
                }
            }

            Item {
                width: parent.width
                height: 20
                Row {
                    anchors.centerIn: parent
                    spacing: 48

                    Text {
                        id: githubLink
                        text: "https://github.com/hualiangHL/CS2JoinTool"
                        color: githubMouse.containsMouse ? App.Theme.primary : "#60A0FF"
                        font.pixelSize: 11
                        font.underline: githubMouse.containsMouse
                        elide: Text.ElideMiddle
                        width: 320
                        Behavior on color { ColorAnimation { duration: 120 } }
                        MouseArea {
                            id: githubMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.openUrlExternally("https://github.com/hualiangHL/CS2JoinTool")
                        }
                    }

                    Text {
                        id: steamLink
                        text: "https://steamcommunity.com/id/hualian_HL/"
                        color: steamMouse.containsMouse ? App.Theme.primary : "#60A0FF"
                        font.pixelSize: 11
                        font.underline: steamMouse.containsMouse
                        elide: Text.ElideMiddle
                        width: 320
                        horizontalAlignment: Text.AlignRight
                        Behavior on color { ColorAnimation { duration: 120 } }
                        MouseArea {
                            id: steamMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.openUrlExternally("steam://openurl/https://steamcommunity.com/id/hualian_HL/")
                        }
                    }
                }
            }

            Text {
                width: parent.width
                text: "© 2026 CS2挤服工具. 仅供学习交流使用。"
                color: App.Theme.textDisabled
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}

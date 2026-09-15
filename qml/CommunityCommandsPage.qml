import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import "qrc:/qml" as App
import "../components" as Components

Rectangle {
    id: commandsPage
    property bool pageActive: false
    color: "transparent"

    property bool showCard1: false
    property bool detailCopyFeedback: false
    onPageActiveChanged: { if (!pageActive) showCard1 = false }
    Timer { interval: 200; repeat: false; running: pageActive; onTriggered: showCard1 = true }

    Timer {
        id: detailCopyTimer
        interval: 1500
        onTriggered: detailCopyFeedback = false
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        Text {
            Layout.fillWidth: true
            text: "社区指令"
            font.family: App.Theme.fontFamily
            color: App.Theme.textPrimary
            font.pixelSize: 22
            font.bold: true
        }
        Text {
            Layout.fillWidth: true
            text: "CS2 社区常用指令参考 · 单击选中生成绑键 · 双击查看详情"
            color: "#FF9BA1B5"
            font.pixelSize: 12
        }

        Components.CommunityCommands {
            id: cmdComp
            Layout.fillWidth: true
            Layout.fillHeight: true
            fillMode: true
            expanded: false
        }
    }

    
    Rectangle {
        id: detailMask
        anchors.fill: parent
        color: cmdComp.detailVisible ? "#90000000" : "#00000000"
        visible: false
        Behavior on color { ColorAnimation { duration: 280; easing.type: Easing.OutCubic } }
        z: 100

        Timer {
            id: detailHideTimer
            interval: 280
            running: !cmdComp.detailVisible && detailMask.visible
            onTriggered: detailMask.visible = false
        }

        Connections {
            target: cmdComp
            function onDetailVisibleChanged() {
                if (cmdComp.detailVisible) detailMask.visible = true
            }
        }

        MouseArea { anchors.fill: parent; onClicked: cmdComp.detailVisible = false }

        Rectangle {
            id: detailPanel
            width: 520
            height: 280
            radius: 12
            color: "#FF1E1B2E"
            border.width: 1
            border.color: "#40A78BFA"
            anchors.centerIn: parent
            opacity: cmdComp.detailVisible ? 1.0 : 0.0
            scale: cmdComp.detailVisible ? 1.0 : 0.90
            Behavior on opacity { NumberAnimation { duration: cmdComp.detailVisible ? 300 : 220; easing.type: cmdComp.detailVisible ? Easing.OutCubic : Easing.InCubic } }
            Behavior on scale { NumberAnimation { duration: cmdComp.detailVisible ? 320 : 220; easing.type: cmdComp.detailVisible ? Easing.OutBack : Easing.InCubic } }

            
            Rectangle {
                id: detailCloseBtn
                width: 28; height: 28; radius: 14
                anchors.top: parent.top; anchors.topMargin: 12
                anchors.right: parent.right; anchors.rightMargin: 12
                color: detailCloseMouse.containsMouse ? "#40ff6b6b" : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
                MouseArea { id: detailCloseMouse; anchors.fill: parent; hoverEnabled: true; onClicked: cmdComp.detailVisible = false }
                Text { anchors.centerIn: parent; text: "✕"; color: "#FFFFFF"; font.pixelSize: 14 }
            }

            
            Text {
                id: detailName
                anchors.left: parent.left; anchors.leftMargin: 20
                anchors.top: parent.top; anchors.topMargin: 20
                anchors.right: detailCloseBtn.left; anchors.rightMargin: 12
                text: cmdComp.detailCmd ? cmdComp.detailCmd.name : ""
                color: "#FFFFFF"
                font.pixelSize: 18
                font.bold: true
                elide: Text.ElideRight
            }

            
            Rectangle {
                id: detailCatTag
                anchors.left: parent.left; anchors.leftMargin: 20
                anchors.top: detailName.bottom; anchors.topMargin: 10
                width: detailCatText.implicitWidth + 16
                height: 22
                radius: 4
                color: "#40A78BFA"
                Text {
                    id: detailCatText
                    anchors.centerIn: parent
                    text: cmdComp.detailCmd ? cmdComp.detailCmd.cat : ""
                    color: "#A78BFA"
                    font.pixelSize: 11
                    font.bold: true
                }
            }

            
            Rectangle {
                id: detailDivider
                anchors.left: parent.left; anchors.leftMargin: 20
                anchors.right: parent.right; anchors.rightMargin: 20
                anchors.top: detailCatTag.bottom; anchors.topMargin: 14
                height: 1
                color: "#20A78BFA"
            }

            
            Rectangle {
                id: detailCmdBox
                anchors.left: parent.left; anchors.leftMargin: 20
                anchors.right: parent.right; anchors.rightMargin: 20
                anchors.top: detailDivider.bottom; anchors.topMargin: 14
                anchors.bottom: detailHint.top; anchors.bottomMargin: 12
                radius: 8
                color: detailCmdMouse.containsMouse ? "#60000000" : "#40000000"
                border.width: 1
                border.color: detailCmdMouse.containsMouse ? "#60A78BFA" : "#20A78BFA"
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                clip: true
                Flickable {
                    id: detailFlickable
                    anchors.fill: parent
                    anchors.margins: 12
                    contentWidth: width
                    contentHeight: detailCmdFullText.implicitHeight
                    clip: true
                    Text {
                        id: detailCmdFullText
                        text: cmdComp.detailCmd ? cmdComp.formatDetailCmd(cmdComp.detailCmd) : ""
                        color: "#7AC8A0"
                        font.pixelSize: 13
                        font.family: "Consolas"
                        wrapMode: Text.Wrap
                        width: parent.width
                    }
                }
                MouseArea {
                    id: detailCmdMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (cmdComp.detailCmd) {
                            var txt = cmdComp.formatDetailCmd(cmdComp.detailCmd)
                            appController.copyToClipboard(txt)
                            detailCopyFeedback = true
                            detailCopyTimer.restart()
                        }
                    }
                }
            }

            
            Text {
                id: detailHint
                anchors.bottom: parent.bottom; anchors.bottomMargin: 14
                anchors.horizontalCenter: parent.horizontalCenter
                text: detailCopyFeedback ? "✓ 已复制到剪贴板" : "点击指令复制 · 点击空白处或 ✕ 关闭"
                color: detailCopyFeedback ? "#34D399" : "#607080"
                font.pixelSize: 11
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }
    }
}

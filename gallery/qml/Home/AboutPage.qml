import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import HuskarUI.Basic

import '../Controls'

HusWindow {
    id: root
    width: 730
    height: 590
    minimumWidth: 420
    minimumHeight: 520
    captionBar.showMinimizeButton: false
    captionBar.showMaximizeButton: false
    captionBar.winTitle: Lang.tr('关于','About')
    captionBar.winIconDelegate: Item {
        Image {
            width: 16
            height: 16
            anchors.centerIn: parent
            source: 'qrc:/Gallery/images/app_icon.png'
            smooth: true
            mipmap: true
            asynchronous: true
        }
    }
    captionBar.closeCallback: () => aboutLoader.visible = false;


    Rectangle {
        id: memeLayer
        anchors.fill: parent
        z: 999
        visible: false
        color: HusThemeFunctions.alpha('#000000', 0.72)
        Behavior on opacity { NumberAnimation { duration: 150 } }

        MouseArea {
            anchors.fill: parent
            onClicked: memeLayer.visible = false
        }

        Image {
            anchors.centerIn: parent
            width: Math.min(parent.width - 60, 560)
            height: width * 0.603
            source: 'qrc:/Gallery/images/meme_squeeze.png'
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
        }

        HusText {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 24
            color: HusThemeFunctions.alpha(HusTheme.Primary.colorTextBase, 0.55)
            font.pixelSize: 11
            text: Lang.tr('点击任意处关闭','Click anywhere to close')
        }
    }

    Item {
        anchors.fill: parent

        Rectangle {
            id: backRect
            anchors.fill: parent
            radius: 6
            color: HusTheme.Primary.colorBgBase
            border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorTextBase, 0.2)
        }

        Item {
            anchors.fill: parent

            GradientFlowEffect {
                anchors.fill: parent
                opacity: 0.5
            }
        }

        Column {
            id: headerCol
            width: parent.width
            anchors.top: parent.top
            anchors.topMargin: captionBar.height
            spacing: 10

            Item {
                width: 56
                height: 56
                anchors.horizontalCenter: parent.horizontalCenter

                Image {
                    width: parent.width
                    height: parent.height
                    anchors.centerIn: parent
                    source: 'qrc:/Gallery/images/app_icon.png'
                    mipmap: true
                    smooth: true
                }


                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: memeLayer.visible = true
                }
            }

            HusText {
                anchors.horizontalCenter: parent.horizontalCenter
                font {
                    family: HusTheme.Primary.fontPrimaryFamily
                    pixelSize: 18
                    bold: true
                }
                text: Lang.tr('CS2挤服工具rc','CS2JoinTool rc')
            }

            HusText {
                anchors.horizontalCenter: parent.horizontalCenter
                color: HusTheme.Primary.colorTextSecondary
                font.pixelSize: 12
                text: qsTr('HuskarUI Edition')
            }
        }

        ScrollView {
            anchors.top: headerCol.bottom
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
                width: root.width - 32
                spacing: 14


                Rectangle {
                    width: parent.width
                    height: infoCol.height + 28
                    radius: 12
                    color: HusTheme.isDark ? '#B01E1B2E' : '#CCE0F7FA'
                    border.width: 1
                    border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.6)

                    Column {
                        id: infoCol
                        width: parent.width - 32
                        anchors.centerIn: parent
                        spacing: 9

                        HusText {
                            text: Lang.tr('工具信息','Tool Info')
                            font.bold: true
                            font.pixelSize: 15
                        }
                        HusText {
                            width: parent.width
                            text: Lang.tr('• 画凉的业余时间做的挤服工具，那你问为什么要做我只能说在学校太无聊了','A squeeze tool made by 画凉 in spare time; why? Just too bored at school.')
                            color: HusTheme.Primary.colorTextSecondary
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                        HusText {
                            width: parent.width
                            text: Lang.tr('• 严禁使用挤服工具功能将人数调低恶意攻击服务器','Do not abuse the squeeze tool (e.g. lowering player counts) to attack servers.')
                            color: '#FF4444'
                            font.bold: true
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                        HusText {
                            width: parent.width
                            text: Lang.tr('• 如果有任何bug请联系我','Contact me if you find any bugs.')
                            color: HusTheme.Primary.colorTextSecondary
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                        HusText {
                            width: parent.width
                            text: Lang.tr('• A2S_INFO协议实时查询服务器状态','A2S_INFO protocol queries server status in real time.')
                            color: HusTheme.Primary.colorTextSecondary
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                        HusText {
                            width: parent.width
                            text: Lang.tr('• 地图信息来源 https://list.darkrp.cn:9000/ServerList/Cs2MapList','Map list source: https://list.darkrp.cn:9000/ServerList/Cs2MapList')
                            color: HusTheme.Primary.colorTextSecondary
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                        HusText {
                            width: parent.width
                            text: Lang.tr('• 获取预览图用 workshop ID 调用 Steam API 拿到 preview_url 并显示','Preview images fetched via Steam API by workshop ID (preview_url).')
                            color: HusTheme.Primary.colorTextSecondary
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                    }
                }


                Rectangle {
                    width: parent.width
                    height: techCol.height + 28
                    radius: 12
                    color: HusTheme.isDark ? '#B01E1B2E' : '#CCE0F7FA'
                    border.width: 1
                    border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.6)

                    Column {
                        id: techCol
                        width: parent.width - 32
                        anchors.centerIn: parent
                        spacing: 8

                        HusText {
                            text: Lang.tr('技术信息','Tech Info')
                            font.bold: true
                            font.pixelSize: 15
                        }

                        Grid {
                            columns: 2
                            spacing: 6
                            columnSpacing: 24
                            width: parent.width
                            HusText { text: Lang.tr('框架:','Framework:'); color: HusTheme.Primary.colorTextSecondary; font.pixelSize: 12 }
                            HusText { text: qsTr('Qt 6.8.3 (QML)'); font.pixelSize: 12 }
                            HusText { text: Lang.tr('编译器:','Compiler:'); color: HusTheme.Primary.colorTextSecondary; font.pixelSize: 12 }
                            HusText { text: qsTr('MinGW-w64'); font.pixelSize: 12 }
                            HusText { text: Lang.tr('构建系统:','Build System:'); color: HusTheme.Primary.colorTextSecondary; font.pixelSize: 12 }
                            HusText { text: qsTr('CMake'); font.pixelSize: 12 }
                            HusText { text: Lang.tr('查询协议:','Query Protocol:'); color: HusTheme.Primary.colorTextSecondary; font.pixelSize: 12 }
                            HusText { text: qsTr('A2S_INFO (UDP)'); font.pixelSize: 12 }
                            HusText { text: Lang.tr('UI框架:','UI Framework:'); color: HusTheme.Primary.colorTextSecondary; font.pixelSize: 12 }
                            HusText { text: qsTr('HuskarUI (MIT)'); font.pixelSize: 12 }
                        }
                    }
                }


                Rectangle {
                    width: parent.width
                    height: thanksCol.height + 28
                    radius: 12
                    color: HusTheme.isDark ? '#B01E1B2E' : '#CCE0F7FA'
                    border.width: 1
                    border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.6)

                    Column {
                        id: thanksCol
                        width: parent.width - 32
                        anchors.centerIn: parent
                        spacing: 8

                        HusText {
                            text: Lang.tr('开源致谢','Open Source Credits')
                            font.bold: true
                            font.pixelSize: 15
                        }
                        HusText {
                            width: parent.width
                            text: qsTr('HuskarUI - mengps/HuskarUI (MIT License)')
                            color: HusTheme.Primary.colorTextSecondary
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                        HusText {
                            width: parent.width
                            text: qsTr('Qt Framework - The Qt Company (LGPL/GPL)')
                            color: HusTheme.Primary.colorTextSecondary
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 22
                    Row {
                        anchors.centerIn: parent
                        spacing: 40
                        HusText {
                            text: qsTr('https://github.com/hualiangHL/CS2JoinTool')
                            color: '#60A0FF'
                            font.pixelSize: 11
                            font.underline: true
                            elide: Text.ElideMiddle
                            width: 320
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Qt.openUrlExternally('https://github.com/hualiangHL/CS2JoinTool')
                            }
                        }
                        HusText {
                            text: qsTr('https://steamcommunity.com/id/hualian_HL/')
                            color: '#60A0FF'
                            font.pixelSize: 11
                            font.underline: true
                            elide: Text.ElideMiddle
                            width: 320
                            horizontalAlignment: Text.AlignRight
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Qt.openUrlExternally('steam://openurl/https://steamcommunity.com/id/hualian_HL/')
                            }
                        }
                    }
                }

                HusText {
                    width: parent.width
                    text: Lang.tr('© 2026 CS2挤服工具. 仅供学习交流使用。','© 2026 CS2JoinTool. For learning and communication only.')
                    color: HusTheme.Primary.colorTextQuaternary
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}

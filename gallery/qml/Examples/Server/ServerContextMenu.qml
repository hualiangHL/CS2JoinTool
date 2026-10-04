import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import HuskarUI.Basic
import Gallery


Item {
    id: root
    visible: false
    z: 250

    property string targetIp: ''
    property string targetName: ''
    property string targetMap: ''
    property bool targetOnline: false
    property real targetX: 0
    property real targetY: 0
    property bool closing: false

    signal joinClicked()
    signal playersClicked()

    MapTranslator {
        id: mapTrans
        Component.onCompleted: setEnglish(Lang.isEn())
    }

    function show(ip, name, mapText, online, x, y) {
        targetIp = ip;
        targetName = name;
        targetMap = mapText;
        targetOnline = online;
        var bw = menuBody.width;
        var bh = menuBody.height;
        var px = x;
        var py = y;
        if (px + bw > root.width - 8)
            px = root.width - bw - 8;
        if (py + bh > root.height - 8)
            py = y - bh - 4;
        targetX = Math.max(8, px);
        targetY = Math.max(8, py);
        closeAnim.stop();
        closing = false;

        menuBody.x = targetX;
        menuBody.y = targetY + 6;
        menuBody.opacity = 0;
        menuBody.scale = 0.96;
        visible = true;
        openAnim.restart();
    }

    function hide() {
        if (!visible || closing)
            return;
        closing = true;

        closeAnim.restart();
    }


    function forceHide() {
        openAnim.stop();
        closeAnim.stop();
        closing = false;
        visible = false;
    }


    ParallelAnimation {
        id: openAnim
        NumberAnimation {
            target: menuBody
            property: 'opacity'
            from: 0
            to: 1
            duration: 160
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: menuBody
            property: 'y'
            to: root.targetY
            duration: 160
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: menuBody
            property: 'scale'
            from: 0.96
            to: 1
            duration: 160
            easing.type: Easing.OutBack
        }
    }


    ParallelAnimation {
        id: closeAnim
        NumberAnimation {
            target: menuBody
            property: 'opacity'
            to: 0
            duration: 120
            easing.type: Easing.InCubic
        }
        NumberAnimation {
            target: menuBody
            property: 'y'
            to: root.targetY + 6
            duration: 120
            easing.type: Easing.InCubic
        }
        NumberAnimation {
            target: menuBody
            property: 'scale'
            to: 0.96
            duration: 120
            easing.type: Easing.InCubic
        }
        onFinished: {
            root.visible = false
            root.closing = false
        }
    }


    MouseArea {
        anchors.fill: parent
        visible: root.visible
        onClicked: root.hide()
    }

    Rectangle {
        id: menuBody
        width: 148
        height: 4 * 36
        radius: 8
        color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.95)
        border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.6)
        border.width: 1

        Column {
            anchors.fill: parent

            Repeater {
                model: [Lang.tr('加入服务器','Join Server'), Lang.tr('复制IP地址','Copy IP'), Lang.tr('复制地图名','Copy Map Name'), Lang.tr('查看玩家列表','View Player List')]

                delegate: Rectangle {
                    id: itemBody
                    required property int index
                    required property string modelData
                    width: parent.width
                    height: 36
                    color: itemHover.containsMouse
                           ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.12)
                           : 'transparent'
                    radius: 4

                    readonly property bool itemEnabled:
                        index !== 0 || root.targetOnline

                    HusText {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: itemBody.modelData
                        color: itemBody.itemEnabled ? HusTheme.Primary.colorTextBase
                                                    : HusTheme.Primary.colorTextDisabled
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: itemHover
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (!itemBody.itemEnabled)
                                return;
                            if (index === 0)
                                root.joinClicked();
                            else if (index === 1)
                                mapTrans.copyText(root.targetIp);
                            else if (index === 2)
                                mapTrans.copyText(root.targetMap);
                            else if (index === 3)
                                root.playersClicked();
                            root.hide();
                        }
                    }
                }
            }
        }
    }
}

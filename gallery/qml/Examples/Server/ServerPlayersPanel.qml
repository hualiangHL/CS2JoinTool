import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import HuskarUI.Basic
import Gallery


Item {
    id: root
    visible: false
    z: 300

    property var targetServer: null
    property bool closing: false
    property string playerListError: ''
    property string targetIpText: ''

    property bool useUB: false
    property bool isUBServer: false
    property var ubPlayerData: null

    PlayerQueryEngine {
        id: playerQuery
    }

    UBServerManager {
        id: ubManager
    }


    function filterUBPlayers(clients, team) {
        const result = [];
        if (!clients)
            return result;
        for (let i = 0; i < clients.length; ++i) {
            const c = clients[i];
            if (!c)
                continue;
            if (team === -1)
                result.push(c);
            else if (team === 0 && (c.team === 0 || c.team === 1))
                result.push(c);
            else if (c.team === team)
                result.push(c);
        }
        return result;
    }

    function open(ip, port, name) {
        targetIpText = ip + ':' + port;
        playerListError = '';
        closing = false;
        isUBServer = false;
        ubPlayerData = null;
        playerQuery.clearPlayers();
        visible = true;
        if (root.useUB) {
            const ubSrv = ubManager.findServer(ip, port);
            isUBServer = ubSrv && Object.keys(ubSrv).length > 0;
            ubPlayerData = isUBServer ? ubSrv : null;
        }
        if (!isUBServer && ip.length > 0)
            playerQuery.queryPlayers(ip, port);
    }

    function close() {
        if (!visible || closing)
            return;
        closing = true;
        closeTimer.restart();
    }


    function forceHide() {
        closeTimer.stop();
        closing = false;
        visible = false;
    }

    Timer {
        id: closeTimer
        interval: 200
        onTriggered: {
            root.visible = false;
            root.closing = false;
        }
    }

    Connections {
        target: playerQuery
        function onQueryError(err) {
            if (root.visible)
                root.playerListError = err;
        }
    }


    Rectangle {
        id: plMask
        anchors.fill: parent
        color: root.visible && !root.closing ? '#80000000' : '#00000000'
        Behavior on color {
            ColorAnimation {
                duration: root.closing ? 220 : 250
                easing.type: root.closing ? Easing.InCubic : Easing.OutCubic
            }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }


    Rectangle {
        id: plPanel
        width: Math.min(700, root.width - 80)
        height: Math.min(500, root.height - 80)
        radius: 14

        color: galleryWindow.specialEffect === HusWindow.Win_DwmBlur
               ? HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.72)
               : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.97)
        border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.25)
        border.width: 1
        anchors.centerIn: parent
        opacity: root.visible && !root.closing ? 1.0 : 0.0
        scale: root.visible && !root.closing ? 1.0 : 0.92
        Behavior on opacity {
            NumberAnimation {
                duration: root.closing ? 220 : 260
                easing.type: root.closing ? Easing.InCubic : Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: root.closing ? 220 : 280
                easing.type: root.closing ? Easing.InCubic : Easing.OutBack
            }
        }


        Rectangle {
            id: plClose
            width: 30
            height: 30
            radius: 8
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 12
            color: plCloseMouse.containsMouse
                   ? HusThemeFunctions.alpha(HusTheme.Primary.colorError, 0.4)
                   : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.6)
            z: 10
            MouseArea {
                id: plCloseMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.close()
            }
            Text {
                anchors.centerIn: parent
                text: '✕'
                color: HusTheme.Primary.colorTextBase
                font.pixelSize: 14
                font.bold: true
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 10


            Text {
                text: root.targetIpText.length > 0 ? Lang.tr('玩家列表 - %1','Player List - %1').arg(root.targetIpText) : Lang.tr('玩家列表','Player List')
                color: HusTheme.Primary.colorTextBase
                font.pixelSize: 16
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }


            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: root.isUBServer
                          ? Lang.tr('UB实时数据 · 共 %1 名玩家','UB live · %1 players total').arg(root.ubPlayerData ? root.ubPlayerData.players : 0)
                          : (playerQuery.querying ? Lang.tr('查询中...','Querying...')
                                                  : (root.playerListError.length > 0 ? Lang.tr('查询失败','Query Failed') : Lang.tr('共 %1 名玩家','%1 players total').arg(playerQuery.players.length)))
                    color: root.isUBServer ? HusTheme.Primary.colorPrimary
                           : (playerQuery.querying ? HusTheme.Primary.colorWarning
                                                   : (root.playerListError.length > 0 ? HusTheme.Primary.colorError
                                                                                     : HusTheme.Primary.colorSuccess))
                    font.pixelSize: 12
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.targetIpText
                    color: HusTheme.Primary.colorTextSecondary
                    font.pixelSize: 11
                    font.family: 'Consolas'
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5)
            }


            Item {
                visible: root.isUBServer && root.ubPlayerData
                         && (root.ubPlayerData.tScore >= 0 || root.ubPlayerData.ctScore >= 0)
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Rectangle {
                        width: 60; height: 28; radius: 6
                        color: '#2060A5FA'
                        border.width: 1; border.color: '#4060A5FA'
                        Text {
                            anchors.centerIn: parent
                            text: root.ubPlayerData && root.ubPlayerData.ctScore >= 0 ? root.ubPlayerData.ctScore : '--'
                            color: '#1565C0'
                            font.pixelSize: 15
                            font.bold: true
                        }
                    }
                    Text {
                        text: 'VS'
                        color: HusTheme.Primary.colorTextSecondary
                        font.pixelSize: 12
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle {
                        width: 60; height: 28; radius: 6
                        color: '#20F87171'
                        border.width: 1; border.color: '#40F87171'
                        Text {
                            anchors.centerIn: parent
                            text: root.ubPlayerData && root.ubPlayerData.tScore >= 0 ? root.ubPlayerData.tScore : '--'
                            color: '#D84315'
                            font.pixelSize: 15
                            font.bold: true
                        }
                    }
                }
            }


            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 8
                color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.5)
                border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.3)
                border.width: 1
                clip: true

                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 2
                    clip: true
                    ScrollBar.vertical.policy: ScrollBar.AlwaysOn
                    ScrollBar.vertical.width: 5

                    ColumnLayout {
                        width: parent.width - 14
                        spacing: 4


                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 80
                            color: 'transparent'
                            visible: !root.isUBServer && playerQuery.querying && root.playerListError.length === 0
                            Text {
                                anchors.centerIn: parent
                                text: Lang.tr('正在查询玩家列表...','Querying player list...')
                                color: HusTheme.Primary.colorTextSecondary
                                font.pixelSize: 13
                            }
                        }


                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 100
                            color: 'transparent'
                            visible: !root.isUBServer && !playerQuery.querying && root.playerListError.length > 0
                            Column {
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.playerListError
                                    color: HusTheme.Primary.colorError
                                    font.pixelSize: 13
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: Lang.tr('服务器可能离线或不支持玩家查询','Server may be offline or player query unsupported.')
                                    color: HusTheme.Primary.colorTextSecondary
                                    font.pixelSize: 11
                                }
                            }
                        }


                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 100
                            color: 'transparent'
                            visible: !root.isUBServer && !playerQuery.querying && root.playerListError.length === 0
                                     && playerQuery.players.length === 0
                            Text {
                                anchors.centerIn: parent
                                text: Lang.tr('服务器为空，没有玩家','No players on server')
                                color: HusTheme.Primary.colorTextSecondary
                                font.pixelSize: 13
                            }
                        }


                        Repeater {
                            model: playerQuery.players
                            visible: !root.isUBServer && !playerQuery.querying && root.playerListError.length === 0
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                radius: 6
                                color: plItemMouse.containsMouse
                                       ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.12)
                                       : 'transparent'

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 10

                                    Text {
                                        text: (index + 1) + '.'
                                        color: HusTheme.Primary.colorTextSecondary
                                        font.pixelSize: 12
                                        Layout.preferredWidth: 24
                                    }
                                    Text {
                                        text: modelData.name.length > 0 ? modelData.name : Lang.tr('未命名玩家','Unnamed Player')
                                        color: HusTheme.Primary.colorTextBase
                                        font.pixelSize: 13
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: modelData.score + Lang.tr(' 分',' pts')
                                        color: HusTheme.Primary.colorWarning
                                        font.pixelSize: 11
                                        Layout.preferredWidth: 56
                                        horizontalAlignment: Text.AlignRight
                                    }
                                    Text {
                                        text: {
                                            var sec = Math.floor(modelData.duration)
                                            var h = Math.floor(sec / 3600)
                                            var m = Math.floor((sec % 3600) / 60)
                                            var s = sec % 60
                                            if (h > 0) return h + 'h' + m + 'm'
                                            if (m > 0) return m + 'm' + s + 's'
                                            return s + 's'
                                        }
                                        color: HusTheme.Primary.colorTextSecondary
                                        font.pixelSize: 11
                                        Layout.preferredWidth: 56
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                                MouseArea {
                                    id: plItemMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }
                            }
                        }


                        Column {
                            width: parent.width
                            spacing: 14
                            visible: root.isUBServer


                            Column {
                                id: ctCol
                                width: parent.width
                                spacing: 6
                                visible: root.filterUBPlayers(root.ubPlayerData ? root.ubPlayerData.clients : [], 3).length > 0
                                Row {
                                    spacing: 6
                                    Rectangle { width: 3; height: 14; radius: 1.5; color: '#1E88E5' }
                                    Text { text: Lang.tr('CT阵营','CT Team'); color: '#1E88E5'; font.pixelSize: 13; font.bold: true }
                                    Text { text: '(' + root.filterUBPlayers(root.ubPlayerData ? root.ubPlayerData.clients : [], 3).length + ')'; color: HusTheme.Primary.colorTextSecondary; font.pixelSize: 12 }
                                }
                                Flow {
                                    width: parent.width
                                    spacing: 6
                                    layoutDirection: Qt.LeftToRight
                                    Repeater {
                                        model: root.filterUBPlayers(root.ubPlayerData ? root.ubPlayerData.clients : [], 3)
                                        delegate: Rectangle {
                                            id: ctCapsule
                                            height: 26
                                            radius: 13
                                            TextMetrics {
                                                id: ctMetrics
                                                text: modelData.name
                                                font.pixelSize: 12
                                            }
                                            width: Math.min(140, ctMetrics.advanceWidth + 26)
                                            color: {
                                                if (modelData.commander > 0) return ctCapsuleMouse.containsMouse ? '#35FFD700' : '#20FFD700'
                                                return ctCapsuleMouse.containsMouse ? '#2560A5FA' : '#1560A5FA'
                                            }
                                            border.width: 1
                                            border.color: {
                                                if (modelData.commander > 0) return ctCapsuleMouse.containsMouse ? '#80FFD700' : '#50FFD700'
                                                return ctCapsuleMouse.containsMouse ? '#6060A5FA' : '#3060A5FA'
                                            }
                                            Row {
                                                anchors.centerIn: parent
                                                spacing: 3
                                                width: parent.width - 16
                                                Text {
                                                    id: ctName
                                                    text: modelData.name.length > 0 ? modelData.name : Lang.tr('未命名','Unnamed')
                                                    color: modelData.commander > 0 ? '#C79100'
                                                           : (HusTheme.isDark ? '#FFFFFF' : '#1A237E')
                                                    font.pixelSize: 12
                                                    elide: Text.ElideRight
                                                    maximumLineCount: 1
                                                    width: parent.width
                                                }
                                            }
                                            MouseArea {
                                                id: ctCapsuleMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                            }
                                        }
                                    }
                                }
                            }


                            Column {
                                id: tCol
                                width: parent.width
                                spacing: 6
                                visible: root.filterUBPlayers(root.ubPlayerData ? root.ubPlayerData.clients : [], 2).length > 0
                                Row {
                                    spacing: 6
                                    Rectangle { width: 3; height: 14; radius: 1.5; color: '#F57C00' }
                                    Text { text: Lang.tr('T阵营','T Team'); color: '#F57C00'; font.pixelSize: 13; font.bold: true }
                                    Text { text: '(' + root.filterUBPlayers(root.ubPlayerData ? root.ubPlayerData.clients : [], 2).length + ')'; color: HusTheme.Primary.colorTextSecondary; font.pixelSize: 12 }
                                }
                                Flow {
                                    width: parent.width
                                    spacing: 6
                                    layoutDirection: Qt.LeftToRight
                                    Repeater {
                                        model: root.filterUBPlayers(root.ubPlayerData ? root.ubPlayerData.clients : [], 2)
                                        delegate: Rectangle {
                                            id: tCapsule
                                            height: 26
                                            radius: 13
                                            TextMetrics {
                                                id: tMetrics
                                                text: modelData.name
                                                font.pixelSize: 12
                                            }
                                            width: Math.min(140, tMetrics.advanceWidth + 26)
                                            color: {
                                                if (modelData.commander > 0) return tCapsuleMouse.containsMouse ? '#35FFD700' : '#20FFD700'
                                                return tCapsuleMouse.containsMouse ? '#25FB923C' : '#15FB923C'
                                            }
                                            border.width: 1
                                            border.color: {
                                                if (modelData.commander > 0) return tCapsuleMouse.containsMouse ? '#80FFD700' : '#50FFD700'
                                                return tCapsuleMouse.containsMouse ? '#60FB923C' : '#30FB923C'
                                            }
                                            Row {
                                                anchors.centerIn: parent
                                                spacing: 3
                                                width: parent.width - 16
                                                Text {
                                                    id: tName
                                                    text: modelData.name.length > 0 ? modelData.name : Lang.tr('未命名','Unnamed')
                                                    color: modelData.commander > 0 ? '#C79100'
                                                           : (HusTheme.isDark ? '#FFFFFF' : '#3E2723')
                                                    font.pixelSize: 12
                                                    elide: Text.ElideRight
                                                    maximumLineCount: 1
                                                    width: parent.width
                                                }
                                            }
                                            MouseArea {
                                                id: tCapsuleMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                            }
                                        }
                                    }
                                }
                            }


                            Column {
                                id: obsCol
                                width: parent.width
                                spacing: 6
                                visible: root.filterUBPlayers(root.ubPlayerData ? root.ubPlayerData.clients : [], 0).length > 0
                                Row {
                                    spacing: 6
                                    Rectangle { width: 3; height: 14; radius: 1.5; color: '#7B6FAF' }
                                    Text { text: Lang.tr('观察者','Spectator'); color: '#7B6FAF'; font.pixelSize: 13; font.bold: true }
                                    Text { text: '(' + root.filterUBPlayers(root.ubPlayerData ? root.ubPlayerData.clients : [], 0).length + ')'; color: HusTheme.Primary.colorTextSecondary; font.pixelSize: 12 }
                                }
                                Flow {
                                    width: parent.width
                                    spacing: 6
                                    layoutDirection: Qt.LeftToRight
                                    Repeater {
                                        model: root.filterUBPlayers(root.ubPlayerData ? root.ubPlayerData.clients : [], 0)
                                        delegate: Rectangle {
                                            id: obsCapsule
                                            height: 26
                                            radius: 13
                                            TextMetrics {
                                                id: obsMetrics
                                                text: modelData.name
                                                font.pixelSize: 12
                                            }
                                            width: Math.min(140, obsMetrics.advanceWidth + 26)
                                            color: {
                                                if (modelData.commander > 0) return obsCapsuleMouse.containsMouse ? '#35FFD700' : '#20FFD700'
                                                return obsCapsuleMouse.containsMouse ? '#258B7DB8' : '#158B7DB8'
                                            }
                                            border.width: 1
                                            border.color: {
                                                if (modelData.commander > 0) return obsCapsuleMouse.containsMouse ? '#80FFD700' : '#50FFD700'
                                                return obsCapsuleMouse.containsMouse ? '#608B7DB8' : '#308B7DB8'
                                            }
                                            Row {
                                                anchors.centerIn: parent
                                                spacing: 3
                                                width: parent.width - 16
                                                Text {
                                                    id: obsName
                                                    text: modelData.name.length > 0 ? modelData.name : Lang.tr('未命名','Unnamed')
                                                    color: modelData.commander > 0 ? '#C79100'
                                                           : (HusTheme.isDark ? '#FFFFFF' : '#4A3B6E')
                                                    font.pixelSize: 12
                                                    elide: Text.ElideRight
                                                    maximumLineCount: 1
                                                    width: parent.width
                                                }
                                            }
                                            MouseArea {
                                                id: obsCapsuleMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                            }
                                        }
                                    }
                                }
                            }

                        }
                    }
                }
            }


            Text {
                anchors.centerIn: parent
                z: 5
                visible: root.isUBServer && root.ubPlayerData
                         && (!root.ubPlayerData.clients || root.ubPlayerData.clients.length === 0)
                text: Lang.tr('暂无玩家数据','No player data')
                color: HusTheme.Primary.colorTextSecondary
                font.pixelSize: 13
            }
        }
    }
}

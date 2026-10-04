import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import HuskarUI.Basic
import Gallery

Item {
    id: root

    function catDisplay(name) {
        if (!Lang.isEn()) return name;
        const m = {
            '挂机大厅': 'Idle Hall',
            '休闲大厅': 'Casual Hall',
            '休闲大厅-挂机': 'Casual Hall - Idle',
            '僵尸逃跑-装备': 'Zombie Escape - Gear',
            '僵尸逃跑-普通': 'Zombie Escape - Normal',
            '模型预览': 'Model Preview',
            '滑翔竞速': 'Surf Race',
            '滑翔竞速-SURF': 'Surf Race - SURF',
            '滑翔-SURF': 'Surf - SURF',
            '练枪': 'Aim Train',
            '对抗': 'Versus',
            '挂机': 'Idle',
            'CSP-感染爆乱': 'CSP - Infection Chaos',
            'cs僵尸逃跑-csgo': 'CS ZE - CSGO',
            'cs起源-Zombie Escape': 'CS:S - Zombie Escape',
            'xcq-小彩旗服': 'XCQ Server',
            'x社区-upkk': 'X Community - UPKK',
            '躲猫猫-娱乐': 'Hide & Seek - Fun',
            '幻想乡大厅-挂机': 'Gensokyo Hall - Idle',
            '僵尸感染-csol生化3': 'Zombie Infection - CSOL Bio 3',
            '僵尸逃跑-PVE': 'Zombie Escape - PVE',
            '僵尸逃跑-符卡': 'Zombie Escape - Cards',
            '僵尸逃跑-国际': 'Zombie Escape - International',
            '僵尸逃跑-活动专用': 'Zombie Escape - Event',
            '僵尸逃跑-闪灵': 'Zombie Escape - Flash Spirit',
            '僵尸逃跑-神之可乐': 'Zombie Escape - God Cola',
            '连跳-BHRF': 'Bunnyhop - BHRF',
            '零次元社-zero': 'Zero Dimension - ZERO',
            '萌萌魔界人-六月服': 'Moe Demons - June Server',
            '女装混战-对抗': 'Crossdress DM - Versus',
            '攀岩-KZ': 'Climbing - KZ',
            '攀岩竞速-KZ': 'Climb Race - KZ',
            '闲聊大厅-挂机': 'Chat Hall - Idle',
            '星社区-挂机': 'Star Community - Idle',
            '娱乐闯关-MG': 'Fun Course - MG',
            '娱乐对抗-MG': 'Fun Versus - MG',
            '娱乐对抗-休闲': 'Fun Versus - Casual',
            '娱乐混战-对抗': 'Fun DM - Versus',
            '自定义': 'Custom',
            '异常芙芙-训练跑图服': 'Yichang Fufu - Training Run',
            '开水-跑图服': 'Kaishui - Map Run',
            '开水-训练服': 'Kaishui - Training'
        };
        return m[name] || name;
    }
    InternationalServerQueryEngine {
        id: serverQuery
    }

    MapTranslator {
        id: mapTrans
        Component.onCompleted: setEnglish(Lang.isEn())
    }



    property string communityKey: 'international'
    property int subTick: 0

    Connections {
        target: SubscriptionManagerObj
        function onSubscribedMapsChanged() { root.subTick++ }
    }

    Connections {
        target: serverQuery
        function onServersUpdated() {
            SubscriptionManagerObj.checkAll(serverQuery.groups, 'international')
        }
    }


    property bool cardMode: root.parent.parent.serverCardMode


    function diffColor(d) {
        switch (d) {
        case '简单': case 'Easy': return '#43A047';
        case '普通': case 'Normal': return '#F9A825';
        case '困难': case 'Hard': return '#EF5350';
        case '极难': case 'Extreme': return '#C62828';
        case '史诗': case 'Epic': return '#AB47BC';
        case '梦魇': case 'Nightmare': return '#6A1B9A';
        case '绝境': case 'Deadly': return '#E040FB';
        }
        return '#757575';
    }


    function diffText(map) {
        if (!map || String(map).indexOf('ze_') !== 0) return '';
        const d = mapTrans.difficulty(map);
        if (!d || d.length === 0) return Lang.tr('暂无','None');
        const en = {'简单':'Easy','普通':'Normal','困难':'Hard','极难':'Extreme','史诗':'Epic','梦魇':'Nightmare','绝境':'Deadly'};
        return Lang.isEn() ? (en[d] || d) : d;
    }


    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            serverQuery.refresh(); BaServerTime.recalibrate();
            refreshCountdown = 60;
        }
    }


    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (refreshCountdown > 0)
                refreshCountdown--;
        }
    }


    property int runtimeTick: 0
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: runtimeTick++
    }

    Connections {
        target: BaServerTime
        function onDataUpdated() { runtimeTick++ }
    }


    function fmtUptime(md) {
        runtimeTick
        if (!md || md.checking || !md.online) return '--'
        var hp = String(md.ip).split(':')
        if (hp.length !== 2) return '--'

        if (!BaServerTime.isConnected() || Date.now() - BaServerTime.lastPushMs() > 15000)
            return Lang.tr('未读取到时间','--:--')
        var ts = BaServerTime.getMapTime(hp[0], parseInt(hp[1]))
        if (ts <= 0) return Lang.tr('未读取到时间','--:--')
        var s = Math.floor((Date.now() + BaServerTime.offsetMs()) / 1000) - Math.floor(ts / 1000)
        if (s < 0) s = 0
        if (s < 3600) {
            var m = Math.floor(s / 60)
            var ss = s % 60
            return (m < 10 ? '0' : '') + m + ':' + (ss < 10 ? '0' : '') + ss
        }
        if (s < 86400)
            return Math.floor(s / 3600) + 'h ' + Math.floor((s % 3600) / 60) + 'm'
        return Math.floor(s / 86400) + 'd ' + Math.floor((s % 86400) / 3600) + 'h'
    }

    Component.onCompleted: {
        refreshCountdown = 60;
        serverQuery.refresh(); BaServerTime.recalibrate();
    }


    Rectangle {
        anchors.fill: parent
        color: 'transparent'
        radius: 10
        border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.35)
        border.width: 1
    }


    Item {
        id: filterMenu
        visible: false
        z: 100
        width: 176
        height: filterHeader.height + filterCol.height + 8
        opacity: 0
        scale: 0.92
        transformOrigin: Item.TopRight
        property bool animClosing: false

        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        Timer {
            id: menuHideTimer
            interval: 150
            repeat: false
            onTriggered: {
                filterMenu.visible = false;
                filterMenu.animClosing = false;
            }
        }


        function reposition() {
            const p = filterBtn.mapToItem(root, 0, filterBtn.height);
            x = Math.round(p.x + filterBtn.width - width);
            y = Math.round(p.y + 4);
        }

        function open() {
            if (!visible) {
                animClosing = false
                visible = true
                reposition()
                opacity = 1
                scale = 1
            }
        }

        function close() {
            if (visible && !animClosing) {
                animClosing = true
                opacity = 0
                scale = 0.92
                menuHideTimer.start()
            }
        }

        function toggle() {
            if (visible) close()
            else open()
        }

        onVisibleChanged: {
            if (visible)
                reposition();
        }

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: HusTheme.Primary.colorBgContainer
            border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.6)
            border.width: 1
        }


        Rectangle {
            id: filterHeader
            width: parent.width
            height: 26
            radius: 8
            color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.7)
            z: 1

            Rectangle {
                width: parent.width
                height: 1
                anchors.bottom: parent.bottom
                color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5)
            }

            HusText {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: Lang.tr('筛选列表','Filter List')
                color: HusTheme.Primary.colorTextSecondary
                font.pixelSize: 11
            }
        }

        Column {
            id: filterCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: filterHeader.bottom
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            anchors.topMargin: 4
            spacing: 2


            Repeater {
                model: {
                    const names = [Lang.tr('全部','All')];
                    const gs = serverQuery.groups;
                    for (let i = 0; i < gs.length; ++i)
                        names.push(gs[i].name);
                    names;
                }

                delegate: Rectangle {
                    required property var modelData
                    width: parent.width
                    height: 24
                    radius: 5
                    color: modelData === filterGroup
                           ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.15)
                           : (ma.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.6) : 'transparent')

                    HusText {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: catDisplay(modelData)
                        color: modelData === filterGroup ? HusTheme.Primary.colorPrimary : HusTheme.Primary.colorTextBase
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            filterGroup = (modelData === Lang.tr('全部','All')) ? '' : modelData;
                            filterMenu.close();
                        }
                    }
                }
            }


            Rectangle {
                width: parent.width
                height: 1
                color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.4)
            }

            HusCheckBox {
                width: parent.width
                height: 26
                text: Lang.tr('隐藏离线','Hide Offline')
                font.pixelSize: 12
                checked: !showOffline
                onToggled: root.parent.parent.hideOffline = !checked
            }

            HusCheckBox {
                width: parent.width
                height: 26
                text: Lang.tr('按人数排序','Sort by Players')
                font.pixelSize: 12
                checked: sortByPlayers
                onToggled: root.parent.parent.sortByPlayers = checked
            }

            HusCheckBox {
                width: parent.width
                height: 26
                text: Lang.tr('按订阅优先排序','Subscribed First')
                font.pixelSize: 12
                checked: sortBySubs
                onToggled: root.parent.parent.sortBySubs = checked
            }
        }
    }


    Column {
        id: headerCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 8
        z: 2

        RowLayout {
            width: parent.width
            spacing: 8

            HusText {
                Layout.fillWidth: true
                text: Lang.tr('国际服','International')
                color: HusTheme.Primary.colorTextBase
                elide: Text.ElideRight
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }

            HusText {
                text: Lang.tr('国际服 · 服务器列表 · 实时','International · Server List · Live')
                color: HusTheme.Primary.colorTextSecondary
                font.pixelSize: 11
            }

            HusText {
                text: Lang.tr('自动刷新 %1s','Auto-refresh %1s').arg(refreshCountdown)
                color: HusTheme.Primary.colorTextSecondary
                font.pixelSize: 11
            }
        }


        Item {
            width: parent.width
            height: 30


            HusInput {
                anchors.left: parent.left
                anchors.right: btnRow.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                iconSource: HusIcon.SearchOutlined
                iconPosition: HusInput.Position_Left
                placeholderText: Lang.tr('搜索服务器名/地图/地区...','Search server / map / region...')

                background: Rectangle {
                    color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.55)
                    radius: 6
                    border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.4)
                    border.width: 1
                }                font.pixelSize: 12
                onTextEdited: searchText = text
            }


            Row {
                id: btnRow
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8


            Rectangle {
                id: filterBtn
                width: 30
                height: 30
                radius: 6
                color: fm.containsMouse || fm.pressed
                       ? HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.6)
                       : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.35)
                border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5)
                border.width: 1

                HusIconText {
                    anchors.centerIn: parent
                    iconSource: HusIcon.FilterOutlined
                    iconSize: 12
                    colorIcon: HusTheme.Primary.colorTextBase
                }

                MouseArea {
                    id: fm
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: filterMenu.toggle()
                }
            }



            Rectangle {
                id: cardModeBtn
                width: cardModeLabel.implicitWidth + 44
                height: 30
                radius: 6
                color: root.cardMode
                       ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.18)
                       : (cm.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.6)
                                           : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.35))
                border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5)
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    HusIconText {
                        iconSource: HusIcon.AppstoreOutlined
                        iconSize: 12
                        colorIcon: root.cardMode ? HusTheme.Primary.colorPrimary : HusTheme.Primary.colorTextBase
                    }

                    HusText {
                            id: cardModeLabel
                        text: root.cardMode ? Lang.tr('列表模式','List Mode') : Lang.tr('卡片模式','Card Mode')
                        color: root.cardMode ? HusTheme.Primary.colorPrimary : HusTheme.Primary.colorTextBase
                        font.pixelSize: 12
                    }
                }

                MouseArea {
                    id: cm
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.parent.parent.serverCardMode = !root.cardMode
                }
            }



            Rectangle {
                id: hideOfflineBtn
                width: offlineLabel.implicitWidth + 24
                height: 30
                radius: 6
                color: showOffline
                       ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.18)
                       : (hm.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.6)
                                           : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.35))
                border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5)
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    HusText {
                            id: offlineLabel
                        text: Lang.tr('显示离线','Show Offline')
                        color: showOffline ? HusTheme.Primary.colorPrimary : HusTheme.Primary.colorTextBase
                        font.pixelSize: 12
                    }
                }

                MouseArea {
                    id: hm
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.parent.parent.hideOffline = !root.parent.parent.hideOffline
                }
            }



            Rectangle {
                id: refreshBtn
                width: refreshLabel.implicitWidth + 44
                height: 30
                radius: 6
                color: rm.containsMouse || rm.pressed
                       ? HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.6)
                       : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.35)
                border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5)
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    HusIconText {
                        id: refreshIcon
                        iconSource: HusIcon.ReloadOutlined

                        iconSize: 12
                        colorIcon: HusTheme.Primary.colorTextBase

                        RotationAnimation on rotation {
                            id: refreshSpin
                            from: 0
                            to: 360
                            duration: 500
                            running: false
                        }
                    }

                    HusText {
                            id: refreshLabel
                        text: Lang.tr('刷新','Refresh')
                        color: HusTheme.Primary.colorTextBase
                        font.pixelSize: 12
                    }
                }

                MouseArea {
                    id: rm
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        refreshIcon.rotation = 0
                        refreshSpin.start()
                        serverQuery.refresh(); BaServerTime.recalibrate()
                        refreshCountdown = 60
                    }
                }
            }
            }
        }


        Rectangle {
            width: parent.width
            height: 1
            color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.8)
        }
    }


    Flickable {
        id: listFlick
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: headerCol.bottom
        anchors.bottom: parent.bottom
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 8
        anchors.bottomMargin: 4
        clip: true
        contentHeight: listCol.height + 60
        boundsBehavior: Flickable.DragAndOvershootBounds
        ScrollBar.vertical: HusScrollBar {}

        Column {
            id: listCol
            width: parent.width - 16
            spacing: 10

            Repeater {
                id: listRepeater
                model: {

                    let gs = serverQuery.groups.map(g => {
                        let _online = 0, _players = 0;
                        for (const s of g.servers) {
                            if (s.online) {
                                ++_online;
                                _players += parseInt(String(s.players).split('/')[0]) || 0;
                            }
                        }
                        return { name: g.name, servers: g.servers, _total: g.servers.length, _online: _online, _players: _players };
                    });
                    if (filterGroup !== '')
                        gs = gs.filter(g => g.name === filterGroup);
                    if (!showOffline)
                        gs = gs.map(g => ({ name: g.name, servers: g.servers.filter(s => s.online || s.checking), _total: g._total, _online: g._online, _players: g._players }));
                    if (searchText.length > 0) {
                        const q = searchText.toLowerCase();
                        gs = gs.map(g => ({ name: g.name, servers: g.servers.filter(s =>
                            (s.name + s.map + s.ip).toLowerCase().indexOf(q) >= 0), _total: g._total, _online: g._online, _players: g._players }));
                    }

                    gs = gs.map(g => ({ name: g.name, servers: g.servers.slice().sort((a, b) => {
                        const ra = a.online ? 2 : (a.checking ? 1 : 0);
                        const rb = b.online ? 2 : (b.checking ? 1 : 0);
                        if (ra !== rb) return rb - ra;
                        if (sortBySubs) {
                            const sa = SubscriptionManagerObj.isSubscribed(a.map, root.communityKey) ? 1 : 0;
                            const sb = SubscriptionManagerObj.isSubscribed(b.map, root.communityKey) ? 1 : 0;
                            if (sa !== sb) return sb - sa;
                        }
                        if (sortByPlayers && ra === 2) {
                            const pa = parseInt(String(a.players).split('/')[0]) || 0;
                            const pb = parseInt(String(b.players).split(' / ')[0]) || 0;
                            return pb - pa;
                        }
                        return 0;
                    }), _total: g._total, _online: g._online, _players: g._players }));
                    gs;
                }

                delegate: Column {
                    id: groupColumn
                    width: parent.width
                    spacing: 4

                    readonly property int onlineCount: modelData._online
                    readonly property int offCount: modelData._total - modelData._online
                    readonly property int playerCount: modelData._players

                    Row {
                        width: parent.width
                        spacing: 8

                        Rectangle {
                            width: 3
                            height: 14
                            radius: 2
                            anchors.verticalCenter: parent.verticalCenter
                            color: HusTheme.Primary.colorPrimary
                        }

                        HusText {
                            text: catDisplay(modelData.name)
                            anchors.verticalCenter: parent.verticalCenter
                            color: HusTheme.Primary.colorTextBase
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }

                        HusText {
                            text: Lang.tr('%1离线 %2在线 列表%3人','%1 offline · %2 online · %3 in list')
                                .arg(groupColumn.offCount)
                                .arg(groupColumn.onlineCount)
                                .arg(groupColumn.playerCount)
                            anchors.verticalCenter: parent.verticalCenter
                            color: HusTheme.Primary.colorTextSecondary
                            font.pixelSize: 11
                        }
                    }


                    Flow {
                        width: parent.width
                        spacing: 12
                        visible: root.cardMode
                        Repeater {
                            model: root.cardMode ? modelData.servers : null
                            delegate: Item {
                                property var srvModel: modelData
                                width: Math.floor((listCol.width - 36) / 4)
                                height: 150
                                ServerCard {
                                    width: parent.width
                                    height: parent.height
                                    srv: srvModel
                                    groupName: srvModel.name
                                    onOpenSqueeze: (ip, name) => root.openSqueeze(ip, name)
                                    onContextMenu: (ip, name, mapText, online, gx, gy) => { var p = root.mapFromGlobal(gx, gy); ctxMenu.show(ip, name, mapText, online, p.x, p.y) }
                                    onJoin: (ip, name, map) => {
                                        squeezePanel.joinServer(
                                            String(ip).split(':')[0],
                                            parseInt(String(ip).split(':')[1], 10),
                                            name)
                                        JoinHistoryManager.record(map, name, ip)
                                        serverMessage.success(Lang.tr('连接请求已发送 %1\n%2','Join request sent %1\n%2').arg(name).arg(ip))
                                    }
                                }
                            }
                        }
                    }


                    Column {
                        width: parent.width
                        spacing: 4
                        visible: !root.cardMode

                        Repeater {
     model: !root.cardMode ? modelData.servers : null

                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                width: parent.width
                                height: 44
                                radius: 6
                                color: rowMa.containsMouse
                                       ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.16)
                                       : (index % 2 === 0 ? HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.45)
                                                          : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.35))
                                Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                border.color: rowMa.containsMouse
                                              ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.95)
                                              : HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5)
                                Behavior on border.color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                border.width: rowMa.containsMouse ? 2 : 1
                                Behavior on border.width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }


                                MouseArea {
                                    id: rowMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onDoubleClicked: {
                                        if (modelData.online)
                                            root.openSqueeze(modelData.ip, modelData.name);
                                    }
                                    onPressed: (mouse) => {
                                        if (mouse.button === Qt.RightButton) {
                                            var gp = mapToGlobal(mouse.x, mouse.y);
                                            var p = root.mapFromGlobal(gp.x, gp.y);
                                            ctxMenu.show(modelData.ip, modelData.name, mapTrans.formatMap(modelData.map),
                                                         modelData.online, p.x, p.y);
                                        }
                                    }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 8
                                    spacing: 10

                                    Column {
                                        Layout.preferredWidth: 360
                                        spacing: 2

                                        HusText {
                                            width: parent.width
                                            text: modelData.checking ? Lang.tr('检测中...','Checking...')
                                                  : (modelData.online ? modelData.name : Lang.tr('离线','Offline'))
                                            color: modelData.online ? HusTheme.Primary.colorTextBase
                                                                    : HusTheme.Primary.colorTextSecondary
                                            elide: Text.ElideRight
                                            font.pixelSize: 13
                                            font.weight: modelData.online ? Font.DemiBold : Font.Normal
                                        }

                                        HusText {
                                            width: parent.width
                                            text: modelData.ip
                                            color: HusTheme.Primary.colorTextSecondary
                                            elide: Text.ElideRight
                                            font.pixelSize: 10
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        HusText {
                                            Layout.fillWidth: true
                                            text: modelData.checking ? '--' : mapTrans.formatMap(modelData.map)
                                            color: HusTheme.Primary.colorTextBase
                                            elide: Text.ElideRight
                                            font.pixelSize: 12
                                        }

                                        HusText {
                                            Layout.preferredWidth: Math.max(36, implicitWidth + 8)
                                            visible: !modelData.checking && root.subTick >= 0
                                                     && SubscriptionManagerObj.isSubscribed(modelData.map, root.communityKey)
                                            text: Lang.tr('√订阅','✓ Subscribed')
                                            color: '#C62828'
                                            horizontalAlignment: Text.AlignHCenter
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                        }





                                        HusText {
                                            Layout.preferredWidth: 84
                                            text: modelData.checking ? '--' : root.fmtUptime(modelData)
                                            color: HusTheme.Primary.colorTextSecondary
                                            horizontalAlignment: Text.AlignHCenter
                                            font.pixelSize: 11
                                            font.family: 'Consolas'
                                        }

                                        HusText {
                                            Layout.preferredWidth: Lang.isEn() ? 64 : 36
                                            text: (!modelData.checking && modelData.map.indexOf('ze_') === 0)
                                                  ? root.diffText(modelData.map)
                                                  : ''
                                            color: root.diffColor(mapTrans.difficulty(modelData.map))
                                            horizontalAlignment: Text.AlignHCenter
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                        }
                                    }

                                    HusText {
                                        Layout.preferredWidth: 116
                                        text: modelData.checking ? Lang.tr('检测中','Checking')
                                              : (modelData.online ? (Lang.isEn() ? String(modelData.players).replace(/玩家/g, '') : modelData.players) : '--')
                                        color: {
                                            if (!modelData.online)
                                                return modelData.checking ? HusTheme.Primary.colorTextSecondary : HusTheme.Primary.colorTextSecondary;
                                            const parts = String(modelData.players).split('/');
                                            if (parts.length >= 2) {
                                                const max = parseInt(parts[parts.length - 1], 10) || 0;
                                                let cur = 0;
                                                const pm = String(parts[0]).match(/\d+/);
                                                if (pm) cur += parseInt(pm[0], 10);
                                                if (parts.length >= 3) {
                                                    const bm = String(parts[1]).match(/\d+/);
                                                    if (bm) cur += parseInt(bm[0], 10);
                                                }
                                                if (max >= 60 && cur >= max)
                                                    return '#C62828';
                                                if (cur >= 60)
                                                    return '#F57F17';
                                            }
                                            return HusTheme.Primary.colorPrimary;
                                        }
                                        elide: Text.ElideRight
                                        horizontalAlignment: Text.AlignRight
                                        font.pixelSize: 13
                                        font.weight: modelData.online ? Font.DemiBold : Font.Normal
                                    }

                                    HusButton {
                                        Layout.preferredWidth: 64
                                        Layout.preferredHeight: 26
                                        type: HusButton.Type_Primary
                                        radiusBg.all: 6
                                        text: Lang.tr('加入','Join')
                                        enabled: modelData.online
                                        font.pixelSize: 12
                                        onClicked: {
                                            if (!modelData.online)
                                                return;
                                            var parts = String(modelData.ip).split(':');
                                            if (parts.length !== 2)
                                                return;
                                            squeezePanel.joinServer(parts[0], parseInt(parts[1], 10), modelData.name);
                                            JoinHistoryManager.record(modelData.map, modelData.name, modelData.ip);
                                            serverMessage.success(Lang.tr('连接请求已发送 %1\n%2','Join request sent %1\n%2').arg(modelData.name).arg(modelData.ip));
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }


    HusText {
        visible: listRepeater.count === 0
        anchors.centerIn: listFlick
        text: Lang.tr('没有匹配的服务器','No matching servers')
        color: HusTheme.Primary.colorTextSecondary
        font.pixelSize: 13
    }


    property string filterGroup: ''
    property bool showOffline: root.parent.parent.hideOffline
    property string searchText: ''
    property bool sortByPlayers: root.parent.parent.sortByPlayers
    property bool sortBySubs: root.parent.parent.sortBySubs
    property int refreshCountdown: 60


    function serverHasIp(ip, port) {
        const groups = serverQuery.groups || []
        for (let gi = 0; gi < groups.length; gi++) {
            const servers = groups[gi].servers || []
            for (let si = 0; si < servers.length; si++) {
                const parts = String(servers[si].ip || '').split(':')
                if (parts[0] === ip && parseInt(parts[1], 10) === port)
                    return true
            }
        }
        return false
    }


    function openSqueeze(ipPort, name) {
        const parts = String(ipPort).split(':');
        if (parts.length !== 2)
            return;

        if (SqueezeEngineObj.running) {
            const curIp = String(SqueezeEngineObj.serverIp || '')
            const curPort = SqueezeEngineObj.serverPort
            if (curIp !== parts[0] || curPort !== parseInt(parts[1], 10)) {
                serverMessage.warning(Lang.tr('正在挤其他服务器，请取消后再继续选择','Already squeezing another server. Cancel it first.'), 2500)
                return;
            }
        }
        squeezePanel.open(parts[0], parseInt(parts[1], 10), name);
    }

    SqueezePanel {
        id: squeezePanel
        anchors.fill: parent
    }

    ServerContextMenu {
        id: ctxMenu
        anchors.fill: parent
        onJoinClicked: {
            var parts = String(ctxMenu.targetIp).split(':');
            if (parts.length !== 2)
                return;
            squeezePanel.joinServer(parts[0], parseInt(parts[1], 10), ctxMenu.targetName);
            JoinHistoryManager.record(ctxMenu.targetMap, ctxMenu.targetName, ctxMenu.targetIp);
            serverMessage.success(Lang.tr('连接请求已发送 %1\n%2','Join request sent %1\n%2').arg(ctxMenu.targetName).arg(ctxMenu.targetIp));
        }
        onPlayersClicked: {
            var parts = String(ctxMenu.targetIp).split(':');
            if (parts.length !== 2)
                return;
            playersPanel.open(parts[0], parts[1], ctxMenu.targetName);
        }
    }

    ServerPlayersPanel {
        id: playersPanel
        anchors.fill: parent
    }

    HusMessage {
        id: serverMessage
        z: 999
        width: 380
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 8
    }


    Connections {
        target: SqueezeEngineObj
        function onConnectSent() {
            if (SqueezeEngineObj.suppressConnectToast)
                return
            serverMessage.success(Lang.tr('挤服成功，正在进入服务器...','Squeeze succeeded, joining server...'), 3000)
        }
    }


    onOpacityChanged: {
        if (opacity < 1) {
            if (squeezePanel.visible) squeezePanel.forceHide()
            if (filterMenu.visible) filterMenu.close()
            if (ctxMenu.visible) ctxMenu.forceHide()
            if (playersPanel.visible) playersPanel.forceHide()
        }
    }
    onVisibleChanged: {
        if (!visible) {
            if (squeezePanel.visible) squeezePanel.forceHide()
            if (filterMenu.visible) filterMenu.close()
            if (ctxMenu.visible) ctxMenu.forceHide()
            if (playersPanel.visible) playersPanel.forceHide()
        }
    }



    function closeFloatingPanels() {
        if (squeezePanel.visible) squeezePanel.forceHide()
        if (filterMenu.visible) filterMenu.close()
        if (ctxMenu.visible) ctxMenu.forceHide()
        if (playersPanel.visible) playersPanel.forceHide()
    }
}

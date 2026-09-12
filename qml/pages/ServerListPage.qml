import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "qrc:/qml" as App

Item {
    id: serverListPage
    property bool pageActive: false
    property bool showCard1: false
    property bool showCard2: false
    width: parent.width
    height: parent.height

    onPageActiveChanged: {
        if (!pageActive) {
            showCard1 = false; showCard2 = false
            if (sortDropdownOpen) { sortDropdownOpen = false; sortDropdownAnim.to = 0; sortDropdownAnim.start() }
            if (panelProtoDropdownOpen) { panelProtoDropdownOpen = false; panelProtoDropdownAnim.to = 0; panelProtoDropdownAnim.start() }
        } else {
            runtimeTick++
        }
    }
    Timer { interval: 180; repeat: false; running: pageActive; onTriggered: showCard1 = true }
    Timer { interval: 360; repeat: false; running: pageActive; onTriggered: showCard2 = true }

    // 折叠状态：默认全部折叠，expandedGroups存储已展开的分类
    property int collapseVersion: 0
    property var expandedGroups: ({})

    // 挤服面板
    property bool joinPanelVisible: false
    property int selectedServerIndex: -1
    property var selectedServer: ({})
    property string workshopPreviewUrl: ""
    property string currentPreviewMap: ""
    property int runtimeTick: 0
    Timer { interval: 500; repeat: true; running: true; onTriggered: runtimeTick++ }

    // 从Steam创意工坊获取地图预览图
    function loadWorkshopMapPreview(mapName) {
        workshopPreviewUrl = ""
        currentPreviewMap = mapName
        if (!mapName) return
        // 1. 先查本地map_db和已扫描地图
        var wsid = workshopManager.findWorkshopId(mapName)
        if (wsid) {
            fetchPreviewById(wsid, mapName)
            return
        }
        // 2. 本地没有，从Steam社区搜索页面提取workshop ID
        var xhr = new XMLHttpRequest()
        var searchUrl = "https://steamcommunity.com/workshop/browse/?appid=730&searchtext=" + encodeURIComponent(mapName) + "&browsesort=textmatch&actualsearch=1"
        xhr.open("GET", searchUrl, true)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                if (currentPreviewMap !== mapName) return  // 已切换地图，丢弃旧结果
                try {
                    var html = xhr.responseText
                    var idMatch = html.match(/filedetails\/\?id=(\d+)/)
                    if (idMatch && idMatch[1]) {
                        console.log("[MapPreview] search found workshop id:", idMatch[1], "for:", mapName)
                        fetchPreviewById(idMatch[1], mapName)
                    } else {
                        console.log("[MapPreview] no workshop id in search for:", mapName)
                    }
                } catch(e) { console.log("[MapPreview] search parse error:", e) }
            }
        }
        xhr.send()
    }

    // 通过workshop ID获取预览图URL
    function fetchPreviewById(wsid, mapName) {
        var xhr = new XMLHttpRequest()
        xhr.open("POST", "https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/", true)
        xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                if (currentPreviewMap !== mapName) return  // 已切换地图，丢弃旧结果
                try {
                    var data = JSON.parse(xhr.responseText)
                    if (data.response && data.response.publishedfiledetails && data.response.publishedfiledetails.length > 0) {
                        var url = data.response.publishedfiledetails[0].preview_url
                        if (url && url.length > 0) {
                            workshopPreviewUrl = url
                            console.log("[MapPreview] got preview for:", mapName, url)
                        }
                    }
                } catch(e) { console.log("[MapPreview] detail parse error:", e) }
            }
        }
        xhr.send("itemcount=1&publishedfileids[0]=" + wsid)
    }

    // 监听currentMap变化，自动加载创意工坊预览图
    Connections {
        target: appController
        function onCurrentMapChanged() {
            if (joinPanelVisible && appController.currentMap) {
                loadWorkshopMapPreview(appController.currentMap)
            }
        }
    }

    function openJoinPanel(idx) {
        selectedServerIndex = idx
        selectedServer = serverManager.model.get(idx)
        if (selectedServer && selectedServer.ip) {
            appController.serverIp = selectedServer.ip
            appController.serverPort = selectedServer.port
        }
        // 每次打开挤服面板，间隔重置为设置页的默认间隔
        appController.interval = appController.defaultJoinInterval
        panelIntervalSlider.value = appController.interval
        thresholdInput.text = appController.joinThreshold
        // 每次打开挤服面板，自动应用设置页的默认连接协议
        appController.connectProtocol = appController.defaultConnectProtocol
        joinPanelVisible = true
        // 打开面板时自动实时查询服务器状态
        appController.queryServer()
        // 如果已有地图名，立即加载创意工坊预览图
        if (appController.currentMap) loadWorkshopMapPreview(appController.currentMap)
    }

    function toggleGroup(name) {
        if (expandedGroups[name]) {
            delete expandedGroups[name]
        } else {
            expandedGroups[name] = true
        }
        collapseVersion++
    }

    // 分类右键菜单
    property string menuCommunity: ""
    property bool communityMenuVisible: false
    property bool communityMenuClosing: false
    property bool communityPosAnim: false
    property point menuPos: Qt.point(0, 0)

    function showCommunityMenu(community, x, y) {
        communityPosAnim = false
        menuCommunity = community
        menuPos = Qt.point(x, y)
        communityMenuClosing = false
        communityMenuVisible = true
        communityPosTimer.restart()
    }

    Timer { id: communityPosTimer; interval: 2; onTriggered: communityPosAnim = true }

    function closeCommunityMenu() {
        if (!communityMenuVisible || communityMenuClosing) return
        communityMenuClosing = true
        communityCloseTimer.restart()
    }

    Timer {
        id: communityCloseTimer
        interval: 180
        onTriggered: {
            communityMenuVisible = false
            communityMenuClosing = false
        }
    }

    function moveCommunity(dir) {
        if (dir === "up") serverManager.moveCommunityUp(menuCommunity)
        else if (dir === "down") serverManager.moveCommunityDown(menuCommunity)
        closeCommunityMenu()
    }

    // 服务器右键菜单
    property int menuServerIndex: -1
    property bool serverMenuVisible: false
    property bool serverMenuClosing: false
    property bool serverPosAnim: false
    property point serverMenuPos: Qt.point(0, 0)
    property var menuServer: null

    signal requestHomePage()

    function showServerMenu(idx, x, y) {
        serverPosAnim = false
        menuServerIndex = idx
        menuServer = serverManager.model.get(idx)
        serverMenuPos = Qt.point(x, y)
        serverMenuClosing = false
        serverMenuVisible = true
        serverPosTimer.restart()
    }

    Timer { id: serverPosTimer; interval: 2; onTriggered: serverPosAnim = true }

    function closeServerMenu() {
        if (!serverMenuVisible || serverMenuClosing) return
        serverMenuClosing = true
        serverCloseTimer.restart()
    }

    Timer {
        id: serverCloseTimer
        interval: 180
        onTriggered: {
            serverMenuVisible = false
            serverMenuClosing = false
        }
    }

    function serverMenuAction(action) {
        if (!menuServer) { closeServerMenu(); return }
        if (action === "join") {
            serverManager.joinServer(menuServerIndex)
        } else if (action === "copy") {
            serverManager.copyAddress(menuServerIndex)
        } else if (action === "home") {
            serverListPage.openJoinPanel(menuServerIndex)
        } else if (action === "achievement") {
            serverListPage.showMapAchievement(menuServer.map)
        } else if (action === "players") {
            serverListPage.showPlayerList(menuServer)
        }
        closeServerMenu()
    }

    // 地图成就面板
    property bool achievementVisible: false
    property bool achievementClosing: false
    property string achievementMapName: ""
    property var achievementData: null

    function showMapAchievement(mapName) {
        achievementMapName = mapName
        achievementData = null
        // 从冷却数据中查找匹配地图
        var maps = cooldownManager.filteredMaps
        for (var i = 0; i < maps.length; i++) {
            if (maps[i].enName === mapName || maps[i].displayName.indexOf(mapName) >= 0) {
                achievementData = maps[i]
                break
            }
        }
        achievementClosing = false
        achievementVisible = true
    }

    function closeAchievement() {
        if (!achievementVisible || achievementClosing) return
        achievementClosing = true
        achievementCloseTimer.restart()
    }

    Timer {
        id: achievementCloseTimer
        interval: 250
        onTriggered: {
            achievementVisible = false
            achievementClosing = false
        }
    }

    // 地图翻译由 C++ 层 (serverManager.mapTranslate) 提供

    function mapTranslate(mapName) {
        if (!mapName) return ""
        return serverManager.mapTranslate(mapName)
    }

    Component.onCompleted: {
        expandedGroups = ({})
        collapseVersion++
        if (!serverManager.refreshing) serverManager.refreshAll()
    }

    Column {
        id: mainCol
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // 标题栏
        RowLayout {
            width: mainCol.width
            spacing: 10
            Text { text: "服务器列表 (" + serverManager.model.count() + ")"; font.family: App.Theme.fontFamily; font.bold: true; color: App.Theme.textPrimary; font.pixelSize: 22 }
            Item { Layout.fillWidth: true }
        }

        // 搜索筛选（所有控件统一36px高度，深色风格）
        RowLayout {
            id: staggerChild1
            opacity: showCard1 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
            width: mainCol.width
            spacing: 8

            // 搜索框
            TextField {
                Layout.fillWidth: true
                implicitHeight: 36
                placeholderText: "搜索服务器名称/IP/地图..."
                text: serverManager.searchText
                onTextChanged: serverManager.searchText = text
                background: Rectangle { color: "#601E1B2E"; radius: 8; border.width: 2; border.color: "#A78BFA" }
                font.pixelSize: 13; color: "#FFFFFF"; selectionColor: "#40A78BFA"; selectedTextColor: "#FFFFFF"
                leftPadding: 10; rightPadding: 10; topPadding: 0; bottomPadding: 0
                placeholderTextColor: "#607080"
            }

            // 排序下拉框（完全自定义，无ComboBox作用域问题）
            Rectangle {
                id: sortDropBtn
                Layout.preferredWidth: 120
                implicitHeight: 36
                radius: 8
                color: sortDropMouse.containsMouse ? "#d0252040" : "#b01E1B2E"
                border.width: 1; border.color: sortDropMouse.containsMouse ? App.Theme.primary : App.Theme.border
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                readonly property var items: ["默认排序", "玩家数降序", "玩家数升序"]
                property int currentIndex: serverManager.sortMode

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    text: sortDropBtn.items[sortDropBtn.currentIndex]
                    color: App.Theme.textPrimary
                    font.pixelSize: 13
                }

                Canvas {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    width: 10; height: 6
                    onPaint: {
                        var ctx = getContext("2d"); ctx.reset()
                        ctx.fillStyle = App.Theme.textSecondary
                        ctx.beginPath()
                        ctx.moveTo(0, 0); ctx.lineTo(10, 0); ctx.lineTo(5, 6)
                        ctx.closePath(); ctx.fill()
                    }
                }

                MouseArea {
                    id: sortDropMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: serverListPage.toggleSortDropdown()
                }

            }

            // 隐藏离线（自定义CheckBox）
            Rectangle {
                Layout.preferredWidth: 96
                implicitHeight: 36
                radius: 8
                color: chkMouse.containsMouse ? "#d0252040" : "#b01E1B2E"
                border.width: 1; border.color: App.Theme.border
                Behavior on color { ColorAnimation { duration: 150 } }

                MouseArea { id: chkMouse; anchors.fill: parent; hoverEnabled: true; onClicked: serverManager.hideOffline = !serverManager.hideOffline }

                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Rectangle {
                        width: 16; height: 16; radius: 4
                        color: serverManager.hideOffline ? App.Theme.primary : "transparent"
                        border.width: 2; border.color: serverManager.hideOffline ? App.Theme.primary : App.Theme.textSecondary
                        Text { anchors.centerIn: parent; text: "✓"; color: "white"; font.pixelSize: 12; visible: serverManager.hideOffline }
                    }
                    Text { text: "隐藏离线"; color: App.Theme.textPrimary; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                }
            }

            // 刷新全部按钮（自定义风格）
            Rectangle {
                Layout.preferredWidth: 96
                implicitHeight: 36
                radius: 8
                color: refreshMouse.containsMouse ? "#d0252040" : "#b01E1B2E"
                border.width: 1; border.color: refreshMouse.containsMouse ? App.Theme.primary : App.Theme.border
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                opacity: serverManager.refreshing ? 0.5 : 1.0

                MouseArea { id: refreshMouse; anchors.fill: parent; hoverEnabled: true; enabled: !serverManager.refreshing; onClicked: serverManager.refreshAll() }

                Text {
                    anchors.centerIn: parent
                    text: serverManager.refreshing ? "刷新中..." : ("刷新" + serverManager.refreshCountdown)
                    color: App.Theme.textPrimary
                    font.pixelSize: 13
                    font.bold: false
                }
            }
        }

        // 可滚动列表
        Flickable {
            id: staggerChild2
            opacity: showCard2 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
            width: mainCol.width
            height: mainCol.height - 120
            clip: true
            boundsBehavior: Flickable.DragAndOvershootBounds
            boundsMovement: Flickable.FollowBoundsBehavior
            maximumFlickVelocity: 2400
            flickDeceleration: 1800
            pixelAligned: true
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AlwaysOn
                width: 11
                contentItem: Rectangle { implicitWidth: 11; radius: 5; color: "#60A78BFA" }
                background: Rectangle { implicitWidth: 11; radius: 5; color: "#201E1B2E" }
            }
            contentWidth: mainCol.width - 20
            contentHeight: listCol.height

            Column {
                id: listCol
                width: mainCol.width - 20
                spacing: 4

                Repeater {
                    model: serverManager.model

                    Column {
                        id: itemCol
                        width: listCol.width
                        readonly property var _defaultSrv: ({ serverId: "", displayName: "", displayNameCN: "", gameName: "", ip: "", port: 0, region: "", category: "", community: "", currentPlayers: 0, maxPlayers: 0, map: "", mapDifficulty: "", status: 0, playersPercent: 0 })
                        property var srv: {
                            serverManager.modelVersion
                            var d = serverManager.model.get(index)
                            return (d && d.id) ? d : itemCol._defaultSrv
                        }
                        property bool isFirstInGroup: {
                            if (index === 0) return true
                            var prev = serverManager.model.get(index - 1)
                            if (!prev || !prev.id) return false
                            return prev.community !== itemCol.srv.community
                        }
                        property bool groupExpanded: {
                            collapseVersion
                            return expandedGroups[itemCol.srv.community] === true
                        }

                        // 分类标题
                        Rectangle {
                            width: itemCol.width
                            height: itemCol.isFirstInGroup ? 42 : 0
                            radius: 8
                            color: titleMouse.containsMouse ? "#d0252040" : "#c01E1B2E"
                            border.width: itemCol.isFirstInGroup ? 1 : 0
                            border.color: "#25A78BFA"
                            visible: itemCol.isFirstInGroup
                            Behavior on color { ColorAnimation { duration: 150 } }

                            MouseArea {
                                id: titleMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: {
                                    if (mouse.button === Qt.RightButton) {
                                        var pos = parent.mapToItem(serverListPage, mouse.x, mouse.y)
                                        serverListPage.showCommunityMenu(itemCol.srv.community, pos.x, pos.y)
                                    } else {
                                        serverListPage.toggleGroup(itemCol.srv.community)
                                    }
                                }
                            }

                            RowLayout {
                                anchors.fill: parent; anchors.margins: 12; spacing: 10
                                Canvas {
                                    width: 16; height: 16
                                    rotation: itemCol.groupExpanded ? 90 : 0
                                    Behavior on rotation { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.reset()
                                        ctx.strokeStyle = App.Theme.primary
                                        ctx.lineWidth = 2
                                        ctx.lineCap = "round"
                                        ctx.lineJoin = "round"
                                        ctx.beginPath()
                                        ctx.moveTo(5, 4)
                                        ctx.lineTo(11, 8)
                                        ctx.lineTo(5, 12)
                                        ctx.stroke()
                                    }
                                }
                                Text { text: itemCol.srv.community; font.bold: true; color: App.Theme.textPrimary; font.pixelSize: 15 }
                                Item { Layout.fillWidth: true }
                            }
                        }

                        // 服务器卡片（名称+IP+人数+连接按钮）
                        Rectangle {
                            width: itemCol.width - 20
                            anchors.left: parent.left; anchors.leftMargin: 20
                            height: itemCol.groupExpanded ? 76 : 0
                            radius: 8
                            color: cardMouse.containsMouse ? "#c0252040" : "#a01E1B2E"
                            border.width: 1; border.color: cardMouse.containsMouse ? App.Theme.primary : "#20A78BFA"
                            opacity: itemCol.groupExpanded ? 1.0 : 0.0
                            visible: height > 0.5
                            clip: true
                            Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            MouseArea {
                                id: cardMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                preventStealing: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onDoubleClicked: serverListPage.openJoinPanel(index)
                                onPressed: {
                                    if (mouse.button === Qt.RightButton) {
                                        mouse.accepted = true
                                        var pos = parent.mapToItem(serverListPage, mouse.x, mouse.y)
                                        serverListPage.showServerMenu(index, pos.x, pos.y)
                                    }
                                }
                                onClicked: {
                                    if (mouse.button === Qt.RightButton) mouse.accepted = true
                                }
                            }

                            // ===== 纯 anchors 绝对定位，杜绝任何偏移 =====

                            // 左侧：游戏名称+IP（固定400px宽，确保长名称完整显示）
                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                width: 360
                                spacing: 3
                                Text {
                                    width: parent.width
                                    text: itemCol.srv.status === 1 ? (itemCol.srv.gameName ? itemCol.srv.gameName : itemCol.srv.displayName) : "服务器离线"
                                    font.bold: true
                                    color: itemCol.srv.status === 1 ? App.Theme.textPrimary : "#808898"
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: itemCol.srv.ip + ":" + itemCol.srv.port
                                    color: App.Theme.textSecondary
                                    font.pixelSize: 11
                                }
                            }

                            // 中间：地图名称（居中，固定宽度确保位置统一）
                            Row {
                                id: mapRow
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.horizontalCenterOffset: 30
                                anchors.verticalCenter: parent.verticalCenter
                                Column {
                                    width: 120
                                    spacing: 1
                                    Text {
                                        width: parent.width
                                        text: itemCol.srv.status === 1 ? serverListPage.mapTranslate(itemCol.srv.map) : ""
                                        color: App.Theme.textPrimary
                                        font.bold: true
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                    Text {
                                        width: parent.width
                                        text: itemCol.srv.status === 1 ? itemCol.srv.map : ""
                                        color: App.Theme.textSecondary
                                        font.pixelSize: 9
                                        elide: Text.ElideRight
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                            }

                            // 游玩时间（锚定玩家数左边，固定间距，不随窗口大小变化）
                            Column {
                                anchors.right: playerCountText.left
                                anchors.rightMargin: 24
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                visible: itemCol.srv.status === 1 && itemCol.srv.mapChangedAt > 0
                                Text {
                                    text: "服务器运行时间"
                                    color: "#FFB0B4C4"
                                    font.pixelSize: 10
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                Text {
                                    text: {
                                        runtimeTick
                                        var elapsed = Math.floor(Date.now() / 1000) - itemCol.srv.mapChangedAt
                                        if (elapsed < 0) elapsed = 0
                                        var m = Math.floor(elapsed / 60)
                                        var s = elapsed % 60
                                        return "「" + (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s + "」"
                                    }
                                    color: App.Theme.primary
                                    font.pixelSize: 12
                                    font.family: "Consolas"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }

                            // 播放图标按钮（贴卡片最右边，固定32x32）
                            Rectangle {
                                id: playBtn
                                width: 32; height: 32; radius: 9
                                anchors.right: parent.right
                                anchors.rightMargin: 28
                                anchors.verticalCenter: parent.verticalCenter
                                color: "#601E1B2E"
                                border.width: 1.5; border.color: playMouse.containsMouse ? App.Theme.primary : App.Theme.border
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                MouseArea { id: playMouse; anchors.fill: parent; hoverEnabled: true; onClicked: serverManager.joinServer(index) }

                                Canvas {
                                    anchors.centerIn: parent; width: 12; height: 14
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.reset()
                                        ctx.fillStyle = playMouse.containsMouse ? App.Theme.primary : "#a0e8d8"
                                        ctx.beginPath()
                                        ctx.moveTo(1, 1); ctx.lineTo(11, 7); ctx.lineTo(1, 13)
                                        ctx.closePath(); ctx.fill()
                                    }
                                }
                            }

                            // 状态/玩家数（右边缘永远距播放按钮8px，固定60px宽，文字右对齐）
                            Text {
                                id: playerCountText
                                anchors.right: playBtn.left
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: 90
                                horizontalAlignment: Text.AlignRight
                                text: itemCol.srv.status === 0 ? "检测中" : (itemCol.srv.status === 2 ? "离线" : (itemCol.srv.bots > 0 ? (itemCol.srv.currentPlayers - itemCol.srv.bots) + "/" + itemCol.srv.bots + "bot/" + itemCol.srv.maxPlayers : itemCol.srv.currentPlayers + "/" + itemCol.srv.maxPlayers))
                                color: itemCol.srv.status === 0 ? "#e0c060" : (itemCol.srv.status === 2 ? "#808898" : App.Theme.primary)
                                font.bold: true
                                font.pixelSize: 14
                            }
                        }
                    }
                }
            }
        }
    }

    // ===== 挤服面板（居中模态，非独立窗口）=====
    Rectangle {
        id: joinPanelMask
        anchors.fill: parent
        color: "#90000000"
        opacity: joinPanelVisible ? 1.0 : 0.0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 200 } }
        z: 100

        MouseArea { anchors.fill: parent; onClicked: joinPanelVisible = false }

        Rectangle {
            id: joinPanel
            anchors.centerIn: parent
            width: Math.min(540, parent.width - 32)
            height: Math.min(600, parent.height - 32)
            radius: 14
            color: "#e81E1B2E"
            border.width: 1; border.color: "#FF2D3245"
            scale: joinPanelVisible ? 1.0 : 0.88
            opacity: joinPanelVisible ? 1.0 : 0.0
            visible: joinPanelMask.visible
            clip: true
            Behavior on scale { NumberAnimation { duration: joinPanelVisible ? 280 : 150; easing.type: joinPanelVisible ? Easing.OutBack : Easing.InCubic } }
            Behavior on opacity { NumberAnimation { duration: joinPanelVisible ? 220 : 120 } }

            // 拦截面板内所有鼠标事件，防止冒泡到遮罩导致面板关闭
            MouseArea { anchors.fill: parent; propagateComposedEvents: false }

            // 顶部标题栏
            Rectangle {
                id: panelHeader
                width: parent.width
                height: 72
                color: "#c0121525"

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.right: panelPlayerBadge.left
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: "挤服"
                        color: App.Theme.primary
                        font.pixelSize: 11
                        font.bold: true
                    }
                    Text {
                        text: appController.currentServerName || selectedServer.displayName || "未知服务器"
                        color: App.Theme.textPrimary
                        font.pixelSize: 15
                        font.bold: true
                        width: parent.width
                        elide: Text.ElideRight
                    }
                    Text {
                        text: (appController.serverStatus === 1 ? (appController.currentMap || selectedServer.map) : "—") + "  ·  " + (selectedServer.ip || "") + ":" + (selectedServer.port || 0)
                        color: App.Theme.textSecondary
                        font.pixelSize: 11
                        width: parent.width
                        elide: Text.ElideRight
                    }
                }

                // 人数徽章
                Rectangle {
                    id: panelPlayerBadge
                    anchors.right: parent.right
                    anchors.rightMargin: 52
                    anchors.verticalCenter: parent.verticalCenter
                    width: 90; height: 28; radius: 14
                    color: appController.serverStatus === 1 ? "#30A78BFA" : "#30252040"
                    border.width: 1; border.color: appController.serverStatus === 1 ? App.Theme.primary : "#FF2D3245"

                    Text {
                        anchors.centerIn: parent
                        text: appController.serverStatus === 0 ? "检测中" : (appController.serverStatus === 2 ? "离线" : appController.currentPlayers + "/" + appController.maxPlayers)
                        color: appController.serverStatus === 1 ? App.Theme.primary : App.Theme.textSecondary
                        font.pixelSize: 12; font.bold: true
                    }
                }

                // 关闭按钮
                Rectangle {
                    id: panelCloseBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28; height: 28; radius: 8
                    color: closeMouse.containsMouse ? "#40e74c3c" : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Canvas {
                        anchors.centerIn: parent; width: 12; height: 12
                        onPaint: {
                            var ctx = getContext("2d"); ctx.reset()
                            ctx.strokeStyle = closeMouse.containsMouse ? "#e74c3c" : App.Theme.textSecondary
                            ctx.lineWidth = 2; ctx.lineCap = "round"
                            ctx.beginPath(); ctx.moveTo(2,2); ctx.lineTo(10,10); ctx.moveTo(10,2); ctx.lineTo(2,10); ctx.stroke()
                        }
                    }
                    MouseArea { id: closeMouse; anchors.fill: parent; hoverEnabled: true; onClicked: joinPanelVisible = false }
                }
            }

            // 地图预览图（Steam创意工坊）
            Rectangle {
                id: mapPreviewArea
                width: parent.width
                height: 150
                anchors.top: panelHeader.bottom
                color: "#FF0d1018"
                clip: true

                Image {
                    id: mapImg
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    source: joinPanelVisible ? workshopPreviewUrl : ""
                    asynchronous: true
                    onStatusChanged: {
                        if (status === Image.Ready) mapPlaceholder.visible = false
                        else if (status === Image.Error) mapPlaceholder.visible = true
                    }
                }

                // 无预览图占位
                Rectangle {
                    id: mapPlaceholder
                    anchors.fill: parent
                    color: "#FF0d1018"
                    visible: true
                    Column {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "暂无创意工坊预览图"
                            color: "#FF6B7288"
                            font.pixelSize: 13
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: appController.currentMap || ""
                            color: "#FF4A5068"
                            font.pixelSize: 11
                            font.family: "Consolas"
                        }
                    }
                }

                // 底部渐变遮罩
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 60
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 1.0; color: "#cc1E1B2E" }
                    }
                }

                // 地图名称叠加
                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 10
                    spacing: 2

                    Text {
                        width: parent.width
                        text: appController.serverStatus === 1 ? serverListPage.mapTranslate(appController.currentMap) : "—"
                        color: "#ffffff"
                        font.pixelSize: 16
                        font.bold: true
                        style: Text.Outline; styleColor: "#80000000"
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: appController.serverStatus === 1 ? appController.currentMap : ""
                        color: "#c0ffffff"
                        font.pixelSize: 11
                        style: Text.Outline; styleColor: "#80000000"
                        elide: Text.ElideRight
                    }
                }
            }

            // 内容区域
            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 222
                anchors.margins: 22
                spacing: 16

                // 服务器状态行
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 18
                    spacing: 8

                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: appController.serverStatus === 1 ? App.Theme.primary : (appController.serverStatus === 0 ? "#e0c060" : "#808898")
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Text {
                        text: appController.serverStatus === 1 ? "在线" : (appController.serverStatus === 0 ? "检测中" : "离线")
                        color: appController.serverStatus === 1 ? App.Theme.primary : (appController.serverStatus === 0 ? "#e0c060" : "#808898")
                        font.pixelSize: 12; font.bold: true
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "地图: " + (appController.serverStatus === 1 ? appController.currentMap : "—")
                        color: App.Theme.textSecondary; font.pixelSize: 11
                        Layout.alignment: Qt.AlignVCenter
                        elide: Text.ElideRight
                        Layout.maximumWidth: 280
                    }
                }

                // 分隔线
                Rectangle { Layout.fillWidth: true; height: 1; color: "#201E1B2E" }

                // 进入人数阈值
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text { text: "人数低于时进入"; color: App.Theme.textPrimary; font.pixelSize: 13; font.bold: true; Layout.alignment: Qt.AlignVCenter }
                    Text { text: "[无法低于20人或高于63人]"; color: "#607080"; font.pixelSize: 11; Layout.alignment: Qt.AlignVCenter }
                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 80; height: 32; radius: 8
                        color: thresholdInput.activeFocus ? "#d0252040" : "#b01E1B2E"
                        border.width: 1; border.color: thresholdInput.activeFocus ? App.Theme.primary : "#FF2D3245"
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        TextField {
                            id: thresholdInput
                            anchors.fill: parent
                            anchors.leftMargin: 10; anchors.rightMargin: 10
                            text: appController.joinThreshold
                            color: App.Theme.primary
                            font.pixelSize: 13; font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            validator: IntValidator { bottom: 20; top: 63 }
                            selectByMouse: true
                            background: Rectangle { color: "transparent" }

                            onTextChanged: {
                                var v = parseInt(text)
                                if (!isNaN(v)) {
                                    appController.joinThreshold = Math.max(20, Math.min(63, v))
                                }
                            }
                            onAccepted: text = appController.joinThreshold.toString()
                            onEditingFinished: text = appController.joinThreshold.toString()
                        }
                    }

                    Text { text: "人"; color: App.Theme.textSecondary; font.pixelSize: 12 }
                }

                // 分隔线
                Rectangle { Layout.fillWidth: true; height: 1; color: "#201E1B2E" }

                // 挤服间隔
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "挤服间隔"; color: App.Theme.textPrimary; font.pixelSize: 13; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Text { text: appController.interval.toFixed(2) + " ms"; color: App.Theme.primary; font.pixelSize: 13; font.bold: true }
                    }

                    Slider {
                        id: panelIntervalSlider
                        Layout.fillWidth: true
                        from: appController.proMode ? 0.01 : 50
                        to: 500
                        value: appController.interval
                        onValueChanged: appController.interval = value
                        implicitHeight: 24
                        background: Rectangle {
                            x: 0; y: parent.height / 2 - height / 2
                            width: parent.width; height: 4; radius: 2
                            color: "#40252040"
                            Rectangle {
                                width: panelIntervalSlider.visualPosition * (panelIntervalSlider.width - 16) + 8
                                height: parent.height; radius: 2
                                color: App.Theme.primary
                            }
                        }
                        handle: Rectangle {
                            width: 16; height: 16; radius: 8
                            color: "white"
                            border.width: 2; border.color: App.Theme.primary
                            x: panelIntervalSlider.visualPosition * (panelIntervalSlider.width - width)
                            y: panelIntervalSlider.height / 2 - height / 2
                        }
                    }
                }

                // 连接协议
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text { text: "连接协议"; color: App.Theme.textPrimary; font.pixelSize: 13; font.bold: true }

                    Rectangle {
                        id: panelProtoDrop
                        Layout.fillWidth: true
                        implicitHeight: 34
                        radius: 8
                        color: panelProtoMouse.containsMouse ? "#d0252040" : "#b01E1B2E"
                        border.width: 1; border.color: panelProtoMouse.containsMouse ? App.Theme.primary : "#FF2D3245"
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        readonly property var items: ["steam://connect「服务器浏览器协议」", "steam://run/730//+connect「游戏启动协议」"]

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left; anchors.leftMargin: 12
                            anchors.right: parent.right; anchors.rightMargin: 28
                            text: panelProtoDrop.items[appController.connectProtocol]
                            color: App.Theme.textPrimary; font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                        Canvas {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right; anchors.rightMargin: 12
                            width: 10; height: 6
                            onPaint: {
                                var ctx = getContext("2d"); ctx.reset()
                                ctx.fillStyle = App.Theme.textSecondary
                                ctx.beginPath(); ctx.moveTo(0,0); ctx.lineTo(10,0); ctx.lineTo(5,6); ctx.closePath(); ctx.fill()
                            }
                        }
                        MouseArea { id: panelProtoMouse; anchors.fill: parent; hoverEnabled: true; onClicked: serverListPage.togglePanelProtoDropdown() }

                    }
                }

                Item { Layout.fillHeight: true }

                // 按钮行
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 40
                        radius: 10
                        color: cancelBtnMouse.containsMouse ? "#e03A2E4F" : "#c0252040"
                        border.width: 1; border.color: cancelBtnMouse.containsMouse ? "#FF6B5E7A" : "#60A78BFA"
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        MouseArea { id: cancelBtnMouse; anchors.fill: parent; hoverEnabled: true; onClicked: joinPanelVisible = false }
                        Text { anchors.centerIn: parent; text: "取消"; color: cancelBtnMouse.containsMouse ? "#FFFFFF" : "#E0D8F0"; font.pixelSize: 13; font.bold: true }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 40
                        radius: 10
                        color: startBtnMouse.containsMouse ? "#e0A78BFA" : "#c0A78BFA"
                        border.width: 1; border.color: startBtnMouse.containsMouse ? "#ffffff" : App.Theme.primary
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        MouseArea { id: startBtnMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { appController.startAutoJoin(); joinPanelVisible = false } }
                        Text { anchors.centerIn: parent; text: "开始挤服"; color: "#0a0a14"; font.pixelSize: 13; font.bold: true }
                    }
                }
            }
        }
    }

    // ===== 分类右键菜单 =====
    Rectangle {
        id: communityMenu
        width: 120
        height: colMenu.children.length * 36 + 8
        radius: 8
        color: "#FF1E1B2E"
        border.width: 1; border.color: "#40A78BFA"
        x: Math.min(menuPos.x, serverListPage.width - width - 10)
        y: Math.min(menuPos.y, serverListPage.height - height - 10)
        visible: communityMenuVisible
        opacity: communityMenuVisible && !communityMenuClosing ? 1.0 : 0.0
        scale: communityMenuVisible && !communityMenuClosing ? 1.0 : 0.88
        Behavior on x { enabled: communityPosAnim; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on y { enabled: communityPosAnim; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: communityMenuClosing ? 160 : 150; easing.type: communityMenuClosing ? Easing.InCubic : Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: communityMenuClosing ? 160 : 180; easing.type: communityMenuClosing ? Easing.InCubic : Easing.OutCubic } }
        z: 500

        Column {
            id: colMenu
            anchors.fill: parent
            anchors.margins: 4
            spacing: 0

            Rectangle {
                width: parent.width; height: 36; radius: 6
                color: upMouse.containsMouse ? "#30A78BFA" : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
                MouseArea { id: upMouse; anchors.fill: parent; hoverEnabled: true; onClicked: serverListPage.moveCommunity("up") }
                Text { anchors.centerIn: parent; text: "上移"; color: "#FFFFFF"; font.pixelSize: 13 }
            }

            Rectangle {
                width: parent.width; height: 36; radius: 6
                color: downMouse.containsMouse ? "#30A78BFA" : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
                MouseArea { id: downMouse; anchors.fill: parent; hoverEnabled: true; onClicked: serverListPage.moveCommunity("down") }
                Text { anchors.centerIn: parent; text: "下移"; color: "#FFFFFF"; font.pixelSize: 13 }
            }
        }
    }

    // 点击菜单外关闭
    MouseArea {
        anchors.fill: parent
        visible: communityMenuVisible
        z: 499
        onClicked: closeCommunityMenu()
    }

    // ===== 服务器右键菜单 =====
    Rectangle {
        id: serverMenu
        width: 140
        height: srvCol.children.length * 36 + 8
        radius: 8
        color: "#FF1E1B2E"
        border.width: 1; border.color: "#40A78BFA"
        x: Math.min(serverMenuPos.x, serverListPage.width - width - 10)
        y: Math.min(serverMenuPos.y, serverListPage.height - height - 10)
        visible: serverMenuVisible
        opacity: serverMenuVisible && !serverMenuClosing ? 1.0 : 0.0
        scale: serverMenuVisible && !serverMenuClosing ? 1.0 : 0.88
        Behavior on x { enabled: serverPosAnim; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on y { enabled: serverPosAnim; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: serverMenuClosing ? 160 : 150; easing.type: serverMenuClosing ? Easing.InCubic : Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: serverMenuClosing ? 160 : 180; easing.type: serverMenuClosing ? Easing.InCubic : Easing.OutCubic } }
        z: 500

        Column {
            id: srvCol
            x: 4; y: 4
            width: parent.width - 8
            spacing: 0

            Rectangle {
                width: parent.width; height: 36; radius: 6
                color: m1.containsMouse ? "#25A78BFA" : "transparent"
                Behavior on color { ColorAnimation { duration: 80 } }
                Text {
                    anchors.left: parent.left; anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: "加入服务器"; color: "#FFFFFF"; font.pixelSize: 12
                }
                MouseArea { id: m1; anchors.fill: parent; hoverEnabled: true; onClicked: serverListPage.serverMenuAction("join") }
            }
            Rectangle {
                width: parent.width; height: 36; radius: 6
                color: m2.containsMouse ? "#25A78BFA" : "transparent"
                Behavior on color { ColorAnimation { duration: 80 } }
                Text {
                    anchors.left: parent.left; anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: "复制IP"; color: "#FFFFFF"; font.pixelSize: 12
                }
                MouseArea { id: m2; anchors.fill: parent; hoverEnabled: true; onClicked: serverListPage.serverMenuAction("copy") }
            }
            Rectangle {
                width: parent.width; height: 36; radius: 6
                color: m3.containsMouse ? "#25A78BFA" : "transparent"
                Behavior on color { ColorAnimation { duration: 80 } }
                Text {
                    anchors.left: parent.left; anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: "启动挤服页面"; color: "#FFFFFF"; font.pixelSize: 12
                }
                MouseArea { id: m3; anchors.fill: parent; hoverEnabled: true; onClicked: serverListPage.serverMenuAction("home") }
            }
            Rectangle {
                width: parent.width; height: 36; radius: 6
                color: m4.containsMouse ? "#25A78BFA" : "transparent"
                Behavior on color { ColorAnimation { duration: 80 } }
                Text {
                    anchors.left: parent.left; anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: "查看地图成就"; color: "#FFFFFF"; font.pixelSize: 12
                }
                MouseArea { id: m4; anchors.fill: parent; hoverEnabled: true; onClicked: serverListPage.serverMenuAction("achievement") }
            }
            Rectangle {
                width: parent.width; height: 36; radius: 6
                color: m5.containsMouse ? "#25A78BFA" : "transparent"
                Behavior on color { ColorAnimation { duration: 80 } }
                Text {
                    anchors.left: parent.left; anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: "查看玩家列表"; color: "#FFFFFF"; font.pixelSize: 12
                }
                MouseArea { id: m5; anchors.fill: parent; hoverEnabled: true; onClicked: serverListPage.serverMenuAction("players") }
            }
        }
    }

    // 服务器菜单外点击关闭
    MouseArea {
        anchors.fill: parent
        visible: serverMenuVisible
        z: 499
        onClicked: closeServerMenu()
    }

    // ===== 地图成就面板 =====
    Rectangle {
        id: achMask
        anchors.fill: parent
        color: achievementVisible && !achievementClosing ? "#90000000" : "#00000000"
        visible: achievementVisible
        Behavior on color { ColorAnimation { duration: achievementClosing ? 220 : 250; easing.type: achievementClosing ? Easing.InCubic : Easing.OutCubic } }
        z: 600
        MouseArea { anchors.fill: parent; onClicked: closeAchievement() }

        Rectangle {
            id: achPanel
            width: 420; height: 300
            radius: 12
            color: "#FF1E1B2E"
            border.width: 1; border.color: "#40A78BFA"
            anchors.centerIn: parent
            opacity: achievementVisible && !achievementClosing ? 1.0 : 0.0
            scale: achievementVisible && !achievementClosing ? 1.0 : 0.9
            Behavior on opacity { NumberAnimation { duration: achievementClosing ? 220 : 250; easing.type: achievementClosing ? Easing.InCubic : Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: achievementClosing ? 220 : 280; easing.type: achievementClosing ? Easing.InCubic : Easing.OutBack } }

            Rectangle {
                id: achClose
                width: 30; height: 30; radius: 8
                anchors.top: parent.top; anchors.topMargin: 10
                anchors.right: parent.right; anchors.rightMargin: 10
                color: achCloseMouse.containsMouse ? "#40ff6b6b" : "#20FFFFFF"
                Behavior on color { ColorAnimation { duration: 150 } }
                z: 10
                MouseArea { id: achCloseMouse; anchors.fill: parent; hoverEnabled: true; onClicked: closeAchievement() }
                Text { anchors.centerIn: parent; text: "✕"; color: "#FFFFFF"; font.pixelSize: 15; font.bold: true }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 12

                Text { text: "地图成就"; color: "#A78BFA"; font.pixelSize: 18; font.bold: true }

                Rectangle { width: parent.width; height: 1; color: "#20A78BFA" }

                Text {
                    text: achievementMapName
                    color: "#FFFFFF"; font.pixelSize: 15; font.bold: true
                    font.family: "Consolas"; elide: Text.ElideRight; width: parent.width
                }
                Text {
                    text: "中文名: " + (achievementData ? achievementData.cnName : serverManager.mapTranslate(achievementMapName))
                    color: "#C8C0E0"; font.pixelSize: 13
                }
                Text {
                    text: "成就: " + (achievementData ? achievementData.achievement : "[提示先去地图冷却加载一遍api]")
                    color: achievementData ? "#FFFFFF" : "#8B7DB8"; font.pixelSize: 13
                }
                Text {
                    text: "难度: " + (achievementData ? (appController.difficultyTierMode ? appController.difficultyToTier(achievementData.difficulty) : achievementData.difficulty) : "[提示先去地图冷却加载一遍api]")
                    color: "#FFFFFF"; font.pixelSize: 13
                }
                Text {
                    text: "冷却: " + (achievementData ? (achievementData.isCooling ? achievementData.cooldown + " (截止 " + achievementData.cooldownEnd + ")" : "随时可玩") : "[提示先去地图冷却加载一遍api]")
                    color: achievementData && achievementData.isCooling ? "#ff6b6b" : "#4ADE80"
                    font.pixelSize: 13
                }
                Text {
                    text: "状态: " + (achievementData ? (achievementData.isCooling ? "冷却中" : "可以预定") : "[提示先去地图冷却加载一遍api]")
                    color: achievementData && achievementData.isCooling ? "#ff6b6b" : "#4ADE80"
                    font.pixelSize: 13; font.bold: true
                }
            }
        }
    }

    // 按团队筛选UB玩家，team=-1显示全部，team=3=CT，team=2=T，team=0/1=观察者
    function filterUBPlayers(clients, team) {
        var result = []
        if (!clients) return result
        for (var i = 0; i < clients.length; i++) {
            var c = clients[i]
            if (!c) continue
            if (team === -1) {
                result.push(c)
            } else if (team === 0 && (c.team === 0 || c.team === 1)) {
                result.push(c)
            } else if (c.team === team) {
                result.push(c)
            }
        }
        return result
    }

    // 玩家列表面板
    property bool playerListVisible: false
    property bool playerListClosing: false
    property var playerListServer: null
    property string playerListError: ""
    property bool isUBServer: false
    property var ubPlayerData: null

    function showPlayerList(server) {
        playerListServer = server
        playerListError = ""
        playerListClosing = false
        // 重置旧数据，防止切换服务器时残留
        isUBServer = false
        ubPlayerData = null
        playerQuery.clearPlayers()
        playerListVisible = true
        // 检测是否是UB服务器
        var ubSrv = ubManager.findServer(server.ip, server.port)
        isUBServer = ubSrv && Object.keys(ubSrv).length > 0
        ubPlayerData = isUBServer ? ubSrv : null
        if (!isUBServer && server && server.ip) {
            playerQuery.queryPlayers(server.ip, server.port)
        }
    }

    function closePlayerList() {
        if (!playerListVisible || playerListClosing) return
        playerListClosing = true
        playerListCloseTimer.restart()
    }

    Timer {
        id: playerListCloseTimer
        interval: 200
        onTriggered: {
            playerListVisible = false
            playerListClosing = false
        }
    }

    Connections {
        target: playerQuery
        function onQueryError(err) {
            if (playerListVisible) playerListError = err
        }
    }

    // ===== 玩家列表面板 =====
    Rectangle {
        id: plMask
        anchors.fill: parent
        color: playerListVisible && !playerListClosing ? "#90000000" : "#00000000"
        visible: playerListVisible
        Behavior on color { ColorAnimation { duration: playerListClosing ? 220 : 250; easing.type: playerListClosing ? Easing.InCubic : Easing.OutCubic } }
        z: 610
        MouseArea { anchors.fill: parent; onClicked: closePlayerList() }

        Rectangle {
            id: plPanel
            width: Math.min(750, serverListPage.width - 80)
            height: Math.min(480, serverListPage.height - 80)
            radius: 14
            color: "#FF1E1B2E"
            border.width: 1; border.color: "#40A78BFA"
            anchors.centerIn: parent
            opacity: playerListVisible && !playerListClosing ? 1.0 : 0.0
            scale: playerListVisible && !playerListClosing ? 1.0 : 0.92
            Behavior on opacity { NumberAnimation { duration: playerListClosing ? 220 : 260; easing.type: playerListClosing ? Easing.InCubic : Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: playerListClosing ? 220 : 280; easing.type: playerListClosing ? Easing.InCubic : Easing.OutBack } }

            Rectangle {
                id: plClose
                width: 30; height: 30; radius: 8
                anchors.top: parent.top; anchors.topMargin: 12
                anchors.right: parent.right; anchors.rightMargin: 12
                color: plCloseMouse.containsMouse ? "#40ff6b6b" : "#20FFFFFF"
                Behavior on color { ColorAnimation { duration: 150 } }
                z: 10
                MouseArea { id: plCloseMouse; anchors.fill: parent; hoverEnabled: true; onClicked: closePlayerList() }
                Text { anchors.centerIn: parent; text: "✕"; color: "#FFFFFF"; font.pixelSize: 15; font.bold: true }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 10

                Text {
                    text: playerListServer ? (playerListServer.gameName ? playerListServer.gameName : (playerListServer.displayNameCN || playerListServer.name)) : "玩家列表"
                    color: "#A78BFA"; font.pixelSize: 17; font.bold: true
                    elide: Text.ElideRight; Layout.fillWidth: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Text {
                        text: isUBServer ? ("UB实时数据 · 共 " + (ubPlayerData ? ubPlayerData.players : 0) + " 名玩家") : (playerQuery.querying ? "查询中..." : (playerListError ? "查询失败" : ("共 " + playerQuery.players.length + " 名玩家")))
                        color: isUBServer ? "#A78BFA" : (playerQuery.querying ? "#FFD700" : (playerListError ? "#ff6b6b" : "#4ADE80"))
                        font.pixelSize: 12
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: playerListServer ? (playerListServer.ip + ":" + playerListServer.port) : ""
                        color: "#8B7DB8"; font.pixelSize: 11; font.family: "Consolas"
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#20A78BFA" }

                // 玩家列表
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 8
                    color: "#3012101F"
                    border.width: 1; border.color: "#15A78BFA"
                    clip: true

                    ScrollView {
                        id: playerScrollView
                        anchors.fill: parent
                        anchors.margins: 2
                        clip: true
                        ScrollBar.vertical.policy: ScrollBar.AlwaysOn
                        ScrollBar.vertical.width: 5

                        ColumnLayout {
                            width: playerScrollView.width - 12
                            spacing: 4

                            // 查询中
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 80
                                color: "transparent"
                                visible: !isUBServer && playerQuery.querying && !playerListError
                                Text {
                                    anchors.centerIn: parent
                                    text: "正在查询玩家列表..."
                                    color: "#B8A9D9"; font.pixelSize: 13
                                }
                            }

                            // 错误
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 100
                                color: "transparent"
                                visible: !isUBServer && !playerQuery.querying && playerListError !== ""
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: playerListError
                                        color: "#ff6b6b"; font.pixelSize: 13
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "服务器可能离线或不支持玩家查询"
                                        color: "#8B7DB8"; font.pixelSize: 11
                                    }
                                }
                            }

                            // 空列表
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 100
                                color: "transparent"
                                visible: !isUBServer && !playerQuery.querying && playerListError === "" && playerQuery.players.length === 0
                                Text {
                                    anchors.centerIn: parent
                                    text: "服务器为空，没有玩家"
                                    color: "#8B7DB8"; font.pixelSize: 13
                                }
                            }

                            // 玩家项（非UB服务器用A2S_PLAYER普通列表）
                            Repeater {
                                model: playerQuery.players
                                visible: !isUBServer && !playerQuery.querying && playerListError === ""
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 40
                                    radius: 6
                                    color: plItemMouse.containsMouse ? "#18A78BFA" : "transparent"
                                    Behavior on color { ColorAnimation { duration: 80 } }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12; anchors.rightMargin: 12
                                        spacing: 10

                                        Text {
                                            text: (index + 1) + "."
                                            color: "#6B6B8D"; font.pixelSize: 12
                                            Layout.preferredWidth: 24
                                        }
                                        Text {
                                            text: modelData.name || "未命名玩家"
                                            color: "#FFFFFF"; font.pixelSize: 13
                                            elide: Text.ElideRight; Layout.fillWidth: true
                                        }
                                        Text {
                                            text: modelData.score + " 分"
                                            color: "#FFD700"; font.pixelSize: 11
                                            Layout.preferredWidth: 50
                                            horizontalAlignment: Text.AlignRight
                                        }
                                        Text {
                                            text: {
                                                var sec = Math.floor(modelData.duration)
                                                var h = Math.floor(sec / 3600)
                                                var m = Math.floor((sec % 3600) / 60)
                                                var s = sec % 60
                                                if (h > 0) return h + "h" + m + "m"
                                                if (m > 0) return m + "m" + s + "s"
                                                return s + "s"
                                            }
                                            color: "#8B7DB8"; font.pixelSize: 11
                                            Layout.preferredWidth: 50
                                            horizontalAlignment: Text.AlignRight
                                        }
                                    }
                                    MouseArea { id: plItemMouse; anchors.fill: parent; hoverEnabled: true }
                                }
                            }

                            // ===== UB服务器玩家列表（MoeUB风格胶囊标签） =====
                            Column {
                                Layout.fillWidth: true
                                spacing: 14
                                visible: isUBServer

                                // 调试信息（受设置开关控制）
                                Text {
                                    visible: appController.debugPlayerList
                                    text: {
                                        if (!ubPlayerData) return "调试: ubPlayerData=null"
                                        var keys = Object.keys(ubPlayerData).join(",")
                                        var host = ubPlayerData.host || "无host"
                                        var port = ubPlayerData.port || "无port"
                                        var players = ubPlayerData.players
                                        var clientsLen = ubPlayerData.clients ? ubPlayerData.clients.length : "无clients字段"
                                        return "调试: keys=[" + keys + "] host=" + host + " port=" + port + " players=" + players + " clients=" + clientsLen +
                                               " 查找用: " + playerListServer.ip + ":" + playerListServer.port
                                    }
                                    color: "#FFD700"; font.pixelSize: 9
                                    wrapMode: Text.Wrap
                                    Layout.fillWidth: true
                                }

                                // CT阵营
                                Column {
                                    id: ctCol
                                    width: parent.width
                                    spacing: 6
                                    visible: serverListPage.filterUBPlayers(ubPlayerData ? ubPlayerData.clients : [], 3).length > 0

                                    Row {
                                        spacing: 6
                                        Rectangle { width: 3; height: 14; radius: 1.5; color: "#60A5FA" }
                                        Text { text: "CT阵营"; color: "#60A5FA"; font.pixelSize: 13; font.bold: true }
                                        Text { text: "(" + serverListPage.filterUBPlayers(ubPlayerData ? ubPlayerData.clients : [], 3).length + ")"; color: "#6B6B8D"; font.pixelSize: 12 }
                                    }

                                    Flow {
                                        id: ctFlow
                                        width: 700
                                        spacing: 6
                                        layoutDirection: Qt.LeftToRight
                                        Repeater {
                                            model: serverListPage.filterUBPlayers(ubPlayerData ? ubPlayerData.clients : [], 3)
                                            delegate: Rectangle {
                                                height: 26; radius: 13
                                                width: Math.min(140, ctName.implicitWidth + 20)
                                                color: {
                                                    if (modelData.commander > 0) return plCtMouse.containsMouse ? "#35FFD700" : "#20FFD700"
                                                    return plCtMouse.containsMouse ? "#2560A5FA" : "#1560A5FA"
                                                }
                                                border.width: 1
                                                border.color: {
                                                    if (modelData.commander > 0) return plCtMouse.containsMouse ? "#80FFD700" : "#50FFD700"
                                                    return plCtMouse.containsMouse ? "#6060A5FA" : "#3060A5FA"
                                                }
                                                Behavior on color { ColorAnimation { duration: 100 } }
                                                Row {
                                                    anchors.centerIn: parent
                                                    spacing: 3
                                                    Text {
                                                        id: ctName
                                                        text: modelData.name || "未命名"
                                                        color: modelData.commander > 0 ? "#FFD700" : "#FFFFFF"
                                                        font.pixelSize: 12
                                                        elide: Text.ElideRight; maximumLineCount: 1
                                                    }
                                                }
                                                MouseArea { id: plCtMouse; anchors.fill: parent; hoverEnabled: true }
                                            }
                                        }
                                    }
                                }

                                // 僵尸
                                // T阵营
                                Column {
                                    id: tCol
                                    width: parent.width
                                    spacing: 6
                                    visible: serverListPage.filterUBPlayers(ubPlayerData ? ubPlayerData.clients : [], 2).length > 0

                                    Row {
                                        spacing: 6
                                        Rectangle { width: 3; height: 14; radius: 1.5; color: "#FB923C" }
                                        Text { text: "T阵营"; color: "#FB923C"; font.pixelSize: 13; font.bold: true }
                                        Text { text: "(" + serverListPage.filterUBPlayers(ubPlayerData ? ubPlayerData.clients : [], 2).length + ")"; color: "#6B6B8D"; font.pixelSize: 12 }
                                    }

                                    Flow {
                                        id: tFlow
                                        width: 700
                                        spacing: 6
                                        layoutDirection: Qt.LeftToRight
                                        Repeater {
                                            model: serverListPage.filterUBPlayers(ubPlayerData ? ubPlayerData.clients : [], 2)
                                            delegate: Rectangle {
                                                height: 26; radius: 13
                                                width: Math.min(140, tName.implicitWidth + 20)
                                                color: {
                                                    if (modelData.commander > 0) return plT2Mouse.containsMouse ? "#35FFD700" : "#20FFD700"
                                                    return plT2Mouse.containsMouse ? "#25FB923C" : "#15FB923C"
                                                }
                                                border.width: 1
                                                border.color: {
                                                    if (modelData.commander > 0) return plT2Mouse.containsMouse ? "#80FFD700" : "#50FFD700"
                                                    return plT2Mouse.containsMouse ? "#60FB923C" : "#30FB923C"
                                                }
                                                Behavior on color { ColorAnimation { duration: 100 } }
                                                Row {
                                                    anchors.centerIn: parent
                                                    spacing: 3
                                                    Text {
                                                        id: tName
                                                        text: modelData.name || "未命名"
                                                        color: modelData.commander > 0 ? "#FFD700" : "#FFFFFF"
                                                        font.pixelSize: 12
                                                        elide: Text.ElideRight; maximumLineCount: 1
                                                    }
                                                }
                                                MouseArea { id: plT2Mouse; anchors.fill: parent; hoverEnabled: true }
                                            }
                                        }
                                    }
                                }

                                // 观察者
                                Column {
                                    id: obsCol
                                    width: parent.width
                                    spacing: 6
                                    visible: serverListPage.filterUBPlayers(ubPlayerData ? ubPlayerData.clients : [], 0).length > 0

                                    Row {
                                        spacing: 6
                                        Rectangle { width: 3; height: 14; radius: 1.5; color: "#8B7DB8" }
                                        Text { text: "观察者"; color: "#8B7DB8"; font.pixelSize: 13; font.bold: true }
                                        Text { text: "(" + serverListPage.filterUBPlayers(ubPlayerData ? ubPlayerData.clients : [], 0).length + ")"; color: "#6B6B8D"; font.pixelSize: 12 }
                                    }

                                    Flow {
                                        id: obsFlow
                                        width: 700
                                        spacing: 6
                                        layoutDirection: Qt.LeftToRight
                                        Repeater {
                                            model: serverListPage.filterUBPlayers(ubPlayerData ? ubPlayerData.clients : [], 0)
                                            delegate: Rectangle {
                                                height: 26; radius: 13
                                                width: Math.min(140, obsName.implicitWidth + 20)
                                                color: {
                                                    if (modelData.commander > 0) return plObsMouse.containsMouse ? "#35FFD700" : "#20FFD700"
                                                    return plObsMouse.containsMouse ? "#258B7DB8" : "#158B7DB8"
                                                }
                                                border.width: 1
                                                border.color: {
                                                    if (modelData.commander > 0) return plObsMouse.containsMouse ? "#80FFD700" : "#50FFD700"
                                                    return plObsMouse.containsMouse ? "#608B7DB8" : "#308B7DB8"
                                                }
                                                Behavior on color { ColorAnimation { duration: 100 } }
                                                Row {
                                                    anchors.centerIn: parent
                                                    spacing: 3
                                                    Text {
                                                        id: obsName
                                                        text: modelData.name || "未命名"
                                                        color: modelData.commander > 0 ? "#FFD700" : "#FFFFFF"
                                                        font.pixelSize: 12
                                                        elide: Text.ElideRight; maximumLineCount: 1
                                                    }
                                                }
                                                MouseArea { id: plObsMouse; anchors.fill: parent; hoverEnabled: true }
                                            }
                                        }
                                    }
                                }

                                // UB空状态
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 80
                                    color: "transparent"
                                    visible: ubPlayerData && (!ubPlayerData.clients || ubPlayerData.clients.length === 0)
                                    Text {
                                        anchors.centerIn: parent
                                        text: "暂无玩家数据"
                                        color: "#6B6B8D"; font.pixelSize: 13
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "点击空白处关闭"
                    color: "#5A5078"; font.pixelSize: 11
                }
            }
        }
    }

    // ===== 自定义下拉列表（纯Rectangle，非独立窗口） =====
    property bool sortDropdownOpen: false
    property real sortDropdownMask: 0
    property bool panelProtoDropdownOpen: false
    property real panelProtoDropdownMask: 0

    function toggleSortDropdown() {
        sortDropdownOpen = !sortDropdownOpen
        if (sortDropdownOpen) {
            var pos = sortDropBtn.mapToItem(serverListPage, 0, sortDropBtn.height - 2)
            sortDropdown.x = pos.x; sortDropdown.y = pos.y; sortDropdown.width = sortDropBtn.width
            sortDropdownMask = 0; sortDropdownAnim.to = 112; sortDropdownAnim.start()
        } else {
            sortDropdownAnim.to = 0; sortDropdownAnim.start()
        }
    }

    function togglePanelProtoDropdown() {
        panelProtoDropdownOpen = !panelProtoDropdownOpen
        if (panelProtoDropdownOpen) {
            var pos = panelProtoDrop.mapToItem(serverListPage, 0, panelProtoDrop.height - 2)
            panelProtoDropdown.x = pos.x; panelProtoDropdown.y = pos.y; panelProtoDropdown.width = panelProtoDrop.width
            panelProtoDropdownMask = 0; panelProtoDropdownAnim.to = 76; panelProtoDropdownAnim.start()
        } else {
            panelProtoDropdownAnim.to = 0; panelProtoDropdownAnim.start()
        }
    }

    MouseArea {
        anchors.fill: parent; z: 101
        visible: sortDropdownOpen || panelProtoDropdownOpen
        onClicked: {
            if (sortDropdownOpen) serverListPage.toggleSortDropdown()
            if (panelProtoDropdownOpen) serverListPage.togglePanelProtoDropdown()
        }
    }

    // 排序下拉
    Rectangle {
        id: sortDropdown
        visible: sortDropdownOpen || sortDropdownMask > 0.5
        z: 102; height: 112; radius: 8
        color: "#f01E1B2E"; border.width: 1; border.color: App.Theme.border; clip: true
        opacity: sortDropdownOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Item {
            width: parent.width; height: serverListPage.sortDropdownMask; clip: true
            Column {
                width: parent.width; spacing: 2; anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 6
                Repeater {
                    model: sortDropBtn.items
                    Rectangle {
                        width: parent.width; height: 32; radius: 6
                        color: index === sortDropBtn.currentIndex ? "#35A78BFA" : (sortItemMouse2.containsMouse ? "#28252040" : "transparent")
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text { anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 10; text: modelData; color: index === sortDropBtn.currentIndex ? App.Theme.primary : App.Theme.textPrimary; font.pixelSize: 13 }
                        MouseArea { id: sortItemMouse2; anchors.fill: parent; hoverEnabled: true; onClicked: { serverManager.sortMode = index; serverListPage.toggleSortDropdown() } }
                    }
                }
            }
        }
    }

    // 挤服面板连接协议下拉
    Rectangle {
        id: panelProtoDropdown
        visible: panelProtoDropdownOpen || panelProtoDropdownMask > 0.5
        z: 102; height: 76; radius: 8
        color: "#f01E1B2E"; border.width: 1; border.color: "#FF2D3245"; clip: true
        opacity: panelProtoDropdownOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Item {
            width: parent.width; height: serverListPage.panelProtoDropdownMask; clip: true
            Column {
                width: parent.width; spacing: 2; anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 6
                Repeater {
                    model: panelProtoDrop.items
                    Rectangle {
                        width: parent.width; height: 30; radius: 6
                        color: index === appController.connectProtocol ? "#35A78BFA" : (panelProtoItemMouse2.containsMouse ? "#28252040" : "transparent")
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text { anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 10; anchors.right: parent.right; anchors.rightMargin: 8; text: modelData; color: index === appController.connectProtocol ? App.Theme.primary : App.Theme.textPrimary; font.pixelSize: 12; elide: Text.ElideRight }
                        MouseArea { id: panelProtoItemMouse2; anchors.fill: parent; hoverEnabled: true; onClicked: { appController.connectProtocol = index; serverListPage.togglePanelProtoDropdown() } }
                    }
                }
            }
        }
    }

    NumberAnimation { id: sortDropdownAnim; target: serverListPage; property: "sortDropdownMask"; duration: 200; easing.type: Easing.OutCubic }
    NumberAnimation { id: panelProtoDropdownAnim; target: serverListPage; property: "panelProtoDropdownMask"; duration: 200; easing.type: Easing.OutCubic }
}

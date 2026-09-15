import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "qrc:/qml" as App

Item {
    id: serverListPage
    property bool pageActive: false
    property bool showCard1: false
    property bool showCard2: false
    property bool cardViewMode: false
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

    Timer {
        interval: 100
        repeat: false
        running: true
        onTriggered: {
            cardViewMode = appController.cardViewMode
            serverManager.filterOptions = appController.serverListFilterOptions
        }
    }

    
    property int collapseVersion: 0
    property var expandedGroups: ({})
    property var cardExpandedGroups: ({})
    property int cardCollapseVersion: 0

    function toggleCardGroup(name) {
        if (cardExpandedGroups[name]) {
            delete cardExpandedGroups[name]
        } else {
            cardExpandedGroups[name] = true
        }
        cardCollapseVersion++
    }

    
    property bool joinPanelVisible: false
    property int selectedServerIndex: -1
    property var selectedServer: ({})
    property string workshopPreviewUrl: ""
    property string currentPreviewMap: ""
    property var mapPreviewCache: ({})
    property var canvasImageCache: ({})
    property var previewQueue: []
    property bool previewLoading: false
    property int runtimeTick: 0
    Timer { interval: 500; repeat: true; running: true; onTriggered: runtimeTick++ }

    function enqueuePreview(mapName) {
        if (!mapName || mapPreviewCache[mapName]) return
        if (previewQueue.indexOf(mapName) >= 0) return
        previewQueue.push(mapName)
        previewQueue = previewQueue
        processPreviewQueue()
    }

    function processPreviewQueue() {
        if (previewLoading || previewQueue.length === 0) return
        previewLoading = true
        var mapName = previewQueue.shift()
        previewQueue = previewQueue
        if (mapPreviewCache[mapName]) {
            previewLoading = false
            processPreviewQueue()
            return
        }
        var cache = mapPreviewCache
        cache[mapName] = "loading"
        mapPreviewCache = cache
        var wsid = workshopManager.findWorkshopId(mapName)
        if (wsid) {
            fetchCardPreviewById(wsid, mapName)
            return
        }
        var xhr = new XMLHttpRequest()
        var searchUrl = "https://steamcommunity.com/workshop/browse/?appid=730&searchtext=" + encodeURIComponent(mapName) + "&browsesort=textmatch&actualsearch=1"
        xhr.open("GET", searchUrl, true)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var html = xhr.responseText
                        var idMatch = html.match(/filedetails\/\?id=(\d+)/)
                        if (idMatch && idMatch[1]) {
                            fetchCardPreviewById(idMatch[1], mapName)
                            return
                        }
                    } catch(e) {}
                }
                var c = mapPreviewCache
                delete c[mapName]
                mapPreviewCache = c
                previewLoading = false
                processPreviewQueue()
            }
        }
        xhr.send()
    }

    function fetchCardPreviewById(wsid, mapName) {
        var xhr = new XMLHttpRequest()
        xhr.open("POST", "https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/", true)
        xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText)
                        if (data.response && data.response.publishedfiledetails && data.response.publishedfiledetails.length > 0) {
                            var url = data.response.publishedfiledetails[0].preview_url
                            if (url && url.length > 0) {
                                var c = mapPreviewCache
                                c[mapName] = url
                                mapPreviewCache = c
                            }
                        }
                    } catch(e) {}
                }
                previewLoading = false
                processPreviewQueue()
            }
        }
        xhr.send("itemcount=1&publishedfileids[0]=" + wsid)
    }

    
    Timer {
        id: panelRefreshTimer
        interval: 3000
        repeat: true
        running: joinPanelVisible && appController.autoJoining && selectedServerIndex >= 0
        onTriggered: {
            if (selectedServerIndex < 0 || selectedServerIndex >= serverManager.model.count) return
            var oldMap = selectedServer.map
            selectedServer = serverManager.model.get(selectedServerIndex)
            
            if (selectedServer.map && selectedServer.map !== oldMap && selectedServer.map !== currentPreviewMap) {
                loadWorkshopMapPreview(selectedServer.map)
            }
        }
    }

    
    function loadWorkshopMapPreview(mapName) {
        workshopPreviewUrl = ""
        currentPreviewMap = mapName
        if (!mapName) return
        
        var wsid = workshopManager.findWorkshopId(mapName)
        if (wsid) {
            fetchPreviewById(wsid, mapName)
            return
        }
        
        var xhr = new XMLHttpRequest()
        var searchUrl = "https://steamcommunity.com/workshop/browse/?appid=730&searchtext=" + encodeURIComponent(mapName) + "&browsesort=textmatch&actualsearch=1"
        xhr.open("GET", searchUrl, true)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                if (currentPreviewMap !== mapName) return  
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

    
    function fetchPreviewById(wsid, mapName) {
        var xhr = new XMLHttpRequest()
        xhr.open("POST", "https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/", true)
        xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                if (currentPreviewMap !== mapName) return  
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

    
    Connections {
        target: appController
        function onCurrentMapChanged() {
            if (joinPanelVisible && appController.currentMap && !appController.autoJoining) {
                loadWorkshopMapPreview(appController.currentMap)
            }
        }
    }

    function openJoinPanel(idx) {
        selectedServerIndex = idx
        selectedServer = serverManager.model.get(idx)
        
        if (!appController.autoJoining && selectedServer && selectedServer.ip) {
            appController.serverIp = selectedServer.ip
            appController.serverPort = selectedServer.port
        }
        
        appController.interval = appController.defaultJoinInterval
        panelIntervalSlider.value = appController.interval
        
        appController.activeJoinCoreCount = appController.joinCoreCount
        panelCoreSlider.value = appController.activeJoinCoreCount
        thresholdInput.text = appController.joinThreshold
        
        appController.connectProtocol = appController.defaultConnectProtocol
        joinPanelVisible = true
        
        if (!appController.autoJoining) {
            appController.queryServer()
        }
        
        if (appController.autoJoining) {
            
            loadWorkshopMapPreview(selectedServer.map || "")
        } else {
            
            loadWorkshopMapPreview(appController.currentMap || "")
        }
    }

    function toggleGroup(name) {
        if (expandedGroups[name]) {
            delete expandedGroups[name]
        } else {
            expandedGroups[name] = true
        }
        collapseVersion++
    }

    
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
            serverManager.joinServer(menuServerIndex, appController.defaultConnectProtocol)
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

    
    property bool achievementVisible: false
    property bool achievementClosing: false
    property string achievementMapName: ""
    property var achievementData: null

    function showMapAchievement(mapName) {
        achievementMapName = mapName
        achievementData = null
        
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

        
        RowLayout {
            width: mainCol.width
            spacing: 10
            Text { text: "服务器列表 (" + serverManager.model.count() + ")"; font.family: App.Theme.fontFamily; font.bold: true; color: App.Theme.textPrimary; font.pixelSize: 22 }
            Item { Layout.fillWidth: true }
        }

        
        RowLayout {
            id: staggerChild1
            opacity: showCard1 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
            width: mainCol.width
            spacing: 8

            
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

            
            Rectangle {
                id: viewModeBtn
                Layout.preferredWidth: 88
                implicitHeight: 36
                radius: 8
                color: viewModeMouse.containsMouse ? "#d0252040" : "#b01E1B2E"
                border.width: 1; border.color: "#A78BFA"
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                Text {
                    anchors.centerIn: parent
                    text: cardViewMode ? "列表显示" : "卡片显示"
                    color: "#FFFFFF"
                    font.pixelSize: 12
                    font.bold: true
                }
                MouseArea {
                    id: viewModeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        cardViewMode = !cardViewMode
                        appController.cardViewMode = cardViewMode
                    }
                }
            }

            
            Rectangle {
                id: sortDropBtn
                Layout.preferredWidth: 112
                implicitHeight: 36
                radius: 8
                color: sortDropMouse.containsMouse ? "#d0252040" : "#b01E1B2E"
                border.width: 1; border.color: sortDropdownOpen ? App.Theme.primary : App.Theme.border
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                readonly property var items: ["按人数排序","隐藏 ze 服","隐藏 kz 服","隐藏 surf 服","隐藏混战服","隐藏躲猫猫服","隐藏 0 人服"]

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.right: filterArrow.left
                    anchors.rightMargin: 4
                    text: {
                        var n = serverManager.filterOptions.length
                        if (n === 0) return "选择排序"
                        if (n === 1) return serverManager.filterOptions[0]
                        return "已选" + n + "项"
                    }
                    color: App.Theme.textPrimary
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }

                Canvas {
                    id: filterArrow
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    width: 10; height: 6
                    rotation: sortDropdownOpen ? 0 : 90
                    Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
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

        
        Flickable {
            id: staggerChild2
            visible: !cardViewMode
            opacity: showCard2 && !cardViewMode ? 1 : 0
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
                        readonly property int serverSubType: {
                            var sid = itemCol.srv.id || ""
                            if (sid.indexOf("pve") >= 0) return 2
                            if (sid.indexOf("event") >= 0) return 3
                            if (sid.indexOf("hide") >= 0) return 4
                            if (sid.indexOf("zed_mg") >= 0) return 27
                            if (sid.indexOf("zed_misc") >= 0) return 28
                            if (sid.indexOf("mg") >= 0) return 5
                            if (sid.indexOf("zombie1_ze") >= 0) return 6
                            if (sid.indexOf("zombie1_cs") >= 0) return 29
                            if (sid.indexOf("zed_surf") >= 0) return 7
                            if (sid.indexOf("zed_kz") >= 0) return 8
                            if (sid.indexOf("ub_ze") >= 0) return 10
                            if (sid.indexOf("ub_inf") >= 0) return 11
                            if (sid.indexOf("ub_misc") >= 0) return 12
                            if (sid.indexOf("ub_kz") >= 0) return 13
                            if (sid.indexOf("ub_csgo") >= 0) return 14
                            if (sid.indexOf("fys_ze") >= 0) return 15
                            if (sid.indexOf("fys_fun") >= 0) return 16
                            if (sid.indexOf("upkk_") >= 0) return 17
                            if (sid.indexOf("zero_") >= 0) return 18
                            if (sid.indexOf("exg_afk") >= 0) return 20
                            if (sid.indexOf("zed_afk") >= 0) return 21
                            if (sid.indexOf("ub_afk") >= 0) return 22
                            if (sid.indexOf("fys_afk") >= 0) return 23
                            if (sid.indexOf("star_afk") >= 0) return 24
                            if (sid.indexOf("star_") >= 0) return 19
                            if (sid.indexOf("xcq_paotu") >= 0) return 25
                            if (sid.indexOf("liuyue_paotu") >= 0) return 26
                            var name = itemCol.srv.gameName || itemCol.srv.displayName || ""
                            if (name.indexOf("装备") >= 0) return 0
                            return 1
                        }
                        readonly property string subTypeName: {
                            if (itemCol.serverSubType === 0) return "ZE装备服"
                            if (itemCol.serverSubType === 1) return "ZE普通服"
                            if (itemCol.serverSubType === 2) return "PVE模式"
                            if (itemCol.serverSubType === 3) return "ZE活动服务器"
                            if (itemCol.serverSubType === 4) return "躲猫猫模式"
                            if (itemCol.serverSubType === 5) return "娱乐闯关MG"
                            if (itemCol.serverSubType === 6) return "僵尸逃跑服"
                            if (itemCol.serverSubType === 7) return "滑翔服surf"
                            if (itemCol.serverSubType === 8) return "攀岩服Kz"
                            if (itemCol.serverSubType === 9) return "csgo僵尸逃跑"
                            if (itemCol.serverSubType === 10) return "UB僵尸逃跑"
                            if (itemCol.serverSubType === 11) return "UB僵尸感染模式"
                            if (itemCol.serverSubType === 12) return "女装混战"
                            if (itemCol.serverSubType === 13) return "攀岩滑翔"
                            if (itemCol.serverSubType === 14) return "CSGO僵尸逃跑"
                            if (itemCol.serverSubType === 15) return "FyS僵尸逃跑"
                            if (itemCol.serverSubType === 16) return "娱乐对抗"
                            if (itemCol.serverSubType === 17) return "x社区"
                            if (itemCol.serverSubType === 18) return "零次元社"
                            if (itemCol.serverSubType === 19) return "scp-感染-叛乱"
                            if (itemCol.serverSubType === 20) return "exg挂机服"
                            if (itemCol.serverSubType === 21) return "zed挂机服"
                            if (itemCol.serverSubType === 22) return "ub挂机服"
                            if (itemCol.serverSubType === 23) return "fys挂机服"
                            if (itemCol.serverSubType === 24) return "星社区挂机服"
                            if (itemCol.serverSubType === 25) return "xcq跑图服务器"
                            if (itemCol.serverSubType === 26) return "六月跑图服"
                            if (itemCol.serverSubType === 27) return "娱乐闯关"
                            if (itemCol.serverSubType === 28) return "娱乐混战"
                            if (itemCol.serverSubType === 29) return "csgo服"
                            return "六月跑图服"
                        }
                        readonly property string subTypeColor: {
                            if (itemCol.serverSubType === 0) return "38BDF8"
                            if (itemCol.serverSubType === 1) return "34D399"
                            if (itemCol.serverSubType === 2) return "A78BFA"
                            if (itemCol.serverSubType === 3) return "F0B429"
                            if (itemCol.serverSubType === 4) return "34D399"
                            if (itemCol.serverSubType === 5) return "FB923C"
                            if (itemCol.serverSubType === 6) return "EC4899"
                            if (itemCol.serverSubType === 7) return "22D3EE"
                            if (itemCol.serverSubType === 8) return "4ADE80"
                            if (itemCol.serverSubType === 9) return "F87171"
                            if (itemCol.serverSubType === 10) return "60A5FA"
                            if (itemCol.serverSubType === 11) return "C084FC"
                            if (itemCol.serverSubType === 12) return "F472B6"
                            if (itemCol.serverSubType === 13) return "2DD4BF"
                            if (itemCol.serverSubType === 14) return "FCA5A5"
                            if (itemCol.serverSubType === 15) return "3B82F6"
                            if (itemCol.serverSubType === 16) return "F59E0B"
                            if (itemCol.serverSubType === 17) return "818CF8"
                            if (itemCol.serverSubType === 18) return "34D399"
                            if (itemCol.serverSubType === 19) return "FBBF24"
                            if (itemCol.serverSubType === 20) return "38BDF8"
                            if (itemCol.serverSubType === 21) return "EC4899"
                            if (itemCol.serverSubType === 22) return "C084FC"
                            if (itemCol.serverSubType === 23) return "F59E0B"
                            if (itemCol.serverSubType === 24) return "FBBF24"
                            if (itemCol.serverSubType === 25) return "22D3EE"
                            if (itemCol.serverSubType === 26) return "4ADE80"
                            if (itemCol.serverSubType === 27) return "FB923C"
                            if (itemCol.serverSubType === 28) return "F472B6"
                            if (itemCol.serverSubType === 29) return "60A5FA"
                            return "4ADE80"
                        }
                        readonly property bool isFirstInSubGroup: {
                            serverManager.modelVersion
                            if (index === 0) return true
                            var prev = serverManager.model.get(index - 1)
                            if (!prev || !prev.id) return false
                            if (prev.community !== itemCol.srv.community) return true
                            var prevId = prev.id || ""
                            var prevType = 0
                            if (prevId.indexOf("pve") >= 0) prevType = 2
                            else if (prevId.indexOf("event") >= 0) prevType = 3
                            else if (prevId.indexOf("hide") >= 0) prevType = 4
                            else if (prevId.indexOf("zed_mg") >= 0) prevType = 27
                            else if (prevId.indexOf("zed_misc") >= 0) prevType = 28
                            else if (prevId.indexOf("mg") >= 0) prevType = 5
                            else if (prevId.indexOf("zombie1_ze") >= 0) prevType = 6
                            else if (prevId.indexOf("zombie1_cs") >= 0) prevType = 29
                            else if (prevId.indexOf("zed_surf") >= 0) prevType = 7
                            else if (prevId.indexOf("zed_kz") >= 0) prevType = 8
                            else if (prevId.indexOf("ub_ze") >= 0) prevType = 10
                            else if (prevId.indexOf("ub_inf") >= 0) prevType = 11
                            else if (prevId.indexOf("ub_misc") >= 0) prevType = 12
                            else if (prevId.indexOf("ub_kz") >= 0) prevType = 13
                            else if (prevId.indexOf("ub_csgo") >= 0) prevType = 14
                            else if (prevId.indexOf("fys_ze") >= 0) prevType = 15
                            else if (prevId.indexOf("fys_fun") >= 0) prevType = 16
                            else if (prevId.indexOf("upkk_") >= 0) prevType = 17
                            else if (prevId.indexOf("zero_") >= 0) prevType = 18
                            else if (prevId.indexOf("exg_afk") >= 0) prevType = 20
                            else if (prevId.indexOf("zed_afk") >= 0) prevType = 21
                            else if (prevId.indexOf("ub_afk") >= 0) prevType = 22
                            else if (prevId.indexOf("fys_afk") >= 0) prevType = 23
                            else if (prevId.indexOf("star_afk") >= 0) prevType = 24
                            else if (prevId.indexOf("star_") >= 0) prevType = 19
                            else if (prevId.indexOf("xcq_paotu") >= 0) prevType = 25
                            else if (prevId.indexOf("liuyue_paotu") >= 0) prevType = 26
                            else {
                                var pn = prev.gameName || prev.displayName || ""
                                if (pn.indexOf("装备") >= 0) prevType = 0
                                else prevType = 1
                            }
                            return prevType !== itemCol.serverSubType
                        }
                        readonly property int subGroupCount: {
                            serverManager.modelVersion
                            return serverManager.getSubGroupCount(index)
                        }

                        
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

                        
                        Rectangle {
                            width: itemCol.width - 20
                            anchors.left: parent.left; anchors.leftMargin: 20
                            anchors.topMargin: itemCol.isFirstInSubGroup && itemCol.groupExpanded ? 6 : 0
                            height: (itemCol.isFirstInSubGroup && itemCol.groupExpanded) ? 30 : 0
                            radius: 6
                            color: "#801E1B2E"
                            border.width: opacity > 0.1 ? 1 : 0
                            border.color: "#30" + itemCol.subTypeColor
                            opacity: (itemCol.isFirstInSubGroup && itemCol.groupExpanded) ? 1.0 : 0.0
                            visible: opacity > 0.05
                            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8
                                Canvas {
                                    width: 10; height: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.reset()
                                        ctx.fillStyle = "#" + itemCol.subTypeColor
                                        ctx.beginPath(); ctx.arc(5, 5, 3, 0, Math.PI * 2); ctx.fill()
                                    }
                                }
                                Text {
                                    text: itemCol.subTypeName
                                    font.bold: true
                                    color: "#" + itemCol.subTypeColor
                                    font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Item { Layout.fillWidth: true }
                                Rectangle {
                                    height: 18; radius: 4
                                    color: "#201E1B2E"
                                    border.width: 1
                                    border.color: "#20" + itemCol.subTypeColor
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: countText.width + 16
                                    Text {
                                        id: countText
                                        anchors.centerIn: parent
                                        text: itemCol.subGroupCount + "个服务器"
                                        color: "#B8A9D9"
                                        font.pixelSize: 10
                                    }
                                }
                            }
                        }

                        
                        Rectangle {
                            width: itemCol.width - 20
                            anchors.left: parent.left; anchors.leftMargin: 20
                            height: itemCol.groupExpanded ? 45 : 0
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

                            

                            
                            Column {
                                id: serverNameCol
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                width: 290
                                spacing: 3
                                Text {
                                    width: parent.width
                                    text: itemCol.srv.status === 1 ? (itemCol.srv.gameName ? itemCol.srv.gameName : itemCol.srv.displayName) : "服务器离线"
                                    font.bold: true
                                    color: itemCol.srv.status === 1 ? App.Theme.textPrimary : "#808898"
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: itemCol.srv.ip + ":" + itemCol.srv.port
                                    color: App.Theme.textSecondary
                                    font.pixelSize: 11
                                }
                            }

                            
                            Row {
                                id: mapRow
                                anchors.left: serverNameCol.right
                                anchors.leftMargin: 8
                                anchors.right: runtimeCol.left
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                Column {
                                    width: parent.width
                                    spacing: 1
                                    Text {
                                        width: parent.width
                                        text: {
                                            if (itemCol.srv.status !== 1) return ""
                                            var mapName = itemCol.srv.map || ""
                                            var trans = serverListPage.mapTranslate(mapName)
                                            if (trans && trans !== mapName) return mapName + "「" + trans + "」"
                                            return mapName
                                        }
                                        color: App.Theme.textPrimary
                                        font.bold: true
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                        horizontalAlignment: Text.AlignLeft
                                    }
                                }
                            }

                            
                            Column {
                                id: runtimeCol
                                anchors.right: playerCountText.left
                                anchors.rightMargin: 24
                                anchors.verticalCenter: parent.verticalCenter
                                width: 100
                                spacing: 2
                                visible: itemCol.srv.status === 1
                                Text {
                                    text: "服务器运行时间"
                                    color: "#FFB0B4C4"
                                    font.pixelSize: 10
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                Text {
                                    text: {
                                        if (!itemCol.srv.hasBaTime) return "「未读取到时间」"
                                        runtimeTick
                                        var elapsed = Math.floor(Date.now() / 1000) - itemCol.srv.mapChangedAt
                                        if (elapsed < 0) elapsed = 0
                                        var m = Math.floor(elapsed / 60)
                                        var s = elapsed % 60
                                        return "「" + (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s + "」"
                                    }
                                    color: App.Theme.primary
                                    font.pixelSize: itemCol.srv.hasBaTime ? 12 : 5
                                    font.family: itemCol.srv.hasBaTime ? "Consolas" : ""
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }

                            
                            Rectangle {
                                id: playBtn
                                width: 32; height: 32; radius: 9
                                anchors.right: parent.right
                                anchors.rightMargin: 28
                                anchors.verticalCenter: parent.verticalCenter
                                color: playMouse.containsMouse ? "#40A78BFA" : "#601E1B2E"
                                border.width: 1.5; border.color: playMouse.containsMouse ? App.Theme.primary : App.Theme.border
                                scale: playMouse.containsMouse ? 1.12 : 1.0
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                                MouseArea {
                                    id: playMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onContainsMouseChanged: playCanvas.requestPaint()
                                    onClicked: serverManager.joinServer(index, appController.defaultConnectProtocol)
                                }

                                Canvas {
                                    id: playCanvas
                                    anchors.centerIn: parent; width: 12; height: 14
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.reset()
                                        ctx.fillStyle = playMouse.containsMouse ? "#FFFFFF" : "#a0e8d8"
                                        ctx.beginPath()
                                        ctx.moveTo(1, 1); ctx.lineTo(11, 7); ctx.lineTo(1, 13)
                                        ctx.closePath(); ctx.fill()
                                    }
                                }
                            }

                            
                            Text {
                                id: playerCountText
                                anchors.right: playBtn.left
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: 90
                                horizontalAlignment: Text.AlignRight
                                text: itemCol.srv.status === 0 ? "检测中" : (itemCol.srv.status === 2 ? "离线" : (itemCol.srv.bots > 0 ? (itemCol.srv.currentPlayers - itemCol.srv.bots) + "/" + itemCol.srv.bots + "bot/" + itemCol.srv.maxPlayers : itemCol.srv.currentPlayers + "/" + itemCol.srv.maxPlayers))
                                color: {
                                    if (itemCol.srv.status === 0) return "#e0c060"
                                    if (itemCol.srv.status === 2) return "#808898"
                                    if (itemCol.srv.currentPlayers >= 64) return "#FFE74C3C"
                                    if (itemCol.srv.currentPlayers >= 50) return "#FFF1C40F"
                                    return App.Theme.primary
                                }
                                font.bold: true
                                font.pixelSize: 14
                            }
                        }
                    }
                }
            }
        }

        
        Flickable {
            id: cardViewFlickable
            visible: cardViewMode
            opacity: showCard2 && cardViewMode ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
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
            contentHeight: cardGroupCol.height + 20

            Column {
                id: cardGroupCol
                width: mainCol.width - 20
                spacing: 4

                Repeater {
                    model: serverManager.communityGroups
                    delegate: Item {
                        id: cardCommunityItem
                        width: cardGroupCol.width
                        property string communityName: modelData.name
                        property var subgroups: modelData.subgroups
                        property bool expanded: {
                            cardCollapseVersion
                            return cardExpandedGroups[communityName] === true
                        }
                        height: communityHeader.height + (expanded ? cardSubCol.height + 8 : 0)
                        Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                        Column {
                            id: cardSubCol
                            width: parent.width
                            spacing: 8
                            anchors.top: communityHeader.bottom
                            anchors.topMargin: 8
                            opacity: cardCommunityItem.expanded ? 1.0 : 0.0
                            transform: Translate {
                                y: cardCommunityItem.expanded ? 0 : 12
                                Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            }
                            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                                Repeater {
                                    model: cardCommunityItem.subgroups
                                delegate: Item {
                                    id: cardSubgroupItem
                                    width: cardSubCol.width
                                    property string subName: modelData.name
                                    property string subColor: modelData.color
                                    property var subIndexes: modelData.indexes
                                    height: subHeader.height + cardSubFlow.height + 6

                                    Rectangle {
                                        id: subHeader
                                        width: parent.width - 20
                                        anchors.left: parent.left; anchors.leftMargin: 20
                                        height: 30
                                        radius: 6
                                        color: "#801E1B2E"
                                        border.width: 1; border.color: "#30" + subColor

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
                                            spacing: 8
                                            Canvas {
                                                width: 10; height: 10
                                                onPaint: {
                                                    var ctx = getContext("2d"); ctx.reset()
                                                    ctx.fillStyle = "#" + subColor
                                                    ctx.beginPath(); ctx.arc(5, 5, 3, 0, Math.PI * 2); ctx.fill()
                                                }
                                            }
                                            Text {
                                                text: subName
                                                font.bold: true
                                                color: "#" + subColor
                                                font.pixelSize: 12
                                            }
                                            Item { Layout.fillWidth: true }
                                            Rectangle {
                                                height: 18; radius: 4
                                                color: "#201E1B2E"
                                                border.width: 1
                                                border.color: "#20" + subColor
                                                width: subCountText.width + 16
                                                Text {
                                                    id: subCountText
                                                    anchors.centerIn: parent
                                                    text: subIndexes.length + "个服务器"
                                                    color: "#B8A9D9"
                                                    font.pixelSize: 10
                                                }
                                            }
                                        }
                                    }

                                    Flow {
                                        id: cardSubFlow
                                        width: parent.width - 20
                                        anchors.left: parent.left; anchors.leftMargin: 20
                                        height: implicitHeight
                                        anchors.top: subHeader.bottom
                                        anchors.topMargin: 6
                                        spacing: 8

                                        Repeater {
                                            model: cardSubgroupItem.subIndexes
                                            delegate: Rectangle {
                                                id: serverCard
                                                width: Math.min((cardSubFlow.width - 3 * cardSubFlow.spacing) / 4, 230)
                                                height: 100
                                                radius: 10
                                                color: "#1A1728"
                                                border.width: 1
                                                border.color: cardMouse.containsMouse ? "#C4B5FD" : "#50A78BFA"
                                                Behavior on border.color { ColorAnimation { duration: 150 } }
                                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                                scale: cardMouse.containsMouse ? 1.04 : 1.0
                                                clip: true

                                                property var cardSrv: { serverManager.modelVersion; serverManager.model.get(modelData) }
                                                readonly property bool isOnline: cardSrv.status === 1 || cardSrv.currentPlayers > 0
                                                property string previewUrl: mapPreviewCache[cardSrv.map] || ""

                                                Component.onCompleted: if (cardSrv.map) enqueuePreview(cardSrv.map)
                                                onCardSrvChanged: if (cardSrv.map) enqueuePreview(cardSrv.map)

                                                Canvas {
                                                    id: cardCanvas
                                                    anchors.fill: parent
                                                    property string imgSrc: (serverCard.previewUrl && serverCard.previewUrl !== "loading") ? serverCard.previewUrl : ""
                                                    property bool imgReady: false
                                                    smooth: true

                                                    onImgSrcChanged: {
                                                        if (!imgSrc) { imgReady = false; requestPaint(); return }
                                                        if (serverListPage.canvasImageCache[imgSrc]) {
                                                            imgReady = true
                                                            requestPaint()
                                                        } else {
                                                            imgReady = false
                                                            loadImage(imgSrc)
                                                        }
                                                    }
                                                    onImageLoaded: {
                                                        serverListPage.canvasImageCache[imgSrc] = true
                                                        imgReady = true
                                                        requestPaint()
                                                    }
                                                    onWidthChanged: requestPaint()
                                                    onHeightChanged: requestPaint()

                                                    onPaint: {
                                                        var ctx = getContext("2d")
                                                        ctx.save()
                                                        ctx.clearRect(0, 0, width, height)
                                                        if (!imgReady || !imgSrc) { ctx.restore(); return }
                                                        var r = 10
                                                        var w = width, h = height
                                                        ctx.beginPath()
                                                        ctx.moveTo(r, 0)
                                                        ctx.lineTo(w - r, 0)
                                                        ctx.quadraticCurveTo(w, 0, w, r)
                                                        ctx.lineTo(w, h - r)
                                                        ctx.quadraticCurveTo(w, h, w - r, h)
                                                        ctx.lineTo(r, h)
                                                        ctx.quadraticCurveTo(0, h, 0, h - r)
                                                        ctx.lineTo(0, r)
                                                        ctx.quadraticCurveTo(0, 0, r, 0)
                                                        ctx.closePath()
                                                        ctx.clip()
                                                        ctx.drawImage(imgSrc, 0, 0, w, h)
                                                        ctx.restore()
                                                    }
                                                }

                                                Rectangle {
                                                    anchors.fill: parent
                                                    radius: 10
                                                    gradient: Gradient {
                                                        GradientStop { position: 0.0; color: "#00000000" }
                                                        GradientStop { position: 0.5; color: "#40000000" }
                                                        GradientStop { position: 1.0; color: "#D0000000" }
                                                    }
                                                }

                                                Text {
                                                    anchors.left: parent.left; anchors.leftMargin: 8
                                                    anchors.top: parent.top; anchors.topMargin: 7
                                                    anchors.right: playerCountBadge.left; anchors.rightMargin: 6
                                                    text: cardSrv.displayName || cardSrv.gameName || "未知服务器"
                                                    color: "#FFFFFF"; font.pixelSize: 11; font.bold: true
                                                    elide: Text.ElideRight
                                                    style: Text.Raised; styleColor: "#80000000"
                                                }

                                                Rectangle {
                                                    id: playerCountBadge
                                                    anchors.right: parent.right; anchors.rightMargin: 8
                                                    anchors.top: parent.top; anchors.topMargin: 6
                                                    width: 44; height: 18; radius: 4
                                                    color: "#801A1728"
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: (cardSrv.currentPlayers||0)+"/"+(cardSrv.maxPlayers||0)
                                                        color: {
                                                            if ((cardSrv.currentPlayers||0) >= 64) return "#FFE74C3C"
                                                            if ((cardSrv.currentPlayers||0) >= 50) return "#FFF1C40F"
                                                            return "#C4B5FD"
                                                        }
                                                        font.pixelSize: 9; font.bold: true
                                                    }
                                                }

                                                Column {
                                                    anchors.left: parent.left; anchors.leftMargin: 8
                                                    anchors.right: playBtn.left; anchors.rightMargin: 6
                                                    anchors.bottom: parent.bottom; anchors.bottomMargin: 7
                                                    spacing: 1
                                                    Text {
                                                        text: cardSrv.status === 0 ? "检测中" : (cardSrv.map || "未知地图")
                                                        color: cardSrv.status === 0 ? "#E0C060" : "#E0E8F0"
                                                        font.pixelSize: 10; font.bold: true
                                                        width: parent.width; elide: Text.ElideRight
                                                        style: Text.Raised; styleColor: "#60000000"
                                                    }
                                                    Text {
                                                        text: {
                                                            var m = cardSrv.map || ""
                                                            var t = serverListPage.mapTranslate(m)
                                                            return (t && t !== m) ? t : ""
                                                        }
                                                        color: "#D8E2EC"; font.pixelSize: 10
                                                        width: parent.width; elide: Text.ElideRight
                                                        style: Text.Raised; styleColor: "#50000000"
                                                    }
                                                }

                                                Rectangle {
                                                    id: playBtn
                                                    width: 28; height: 28; radius: 8
                                                    anchors.right: parent.right; anchors.rightMargin: 8
                                                    anchors.bottom: parent.bottom; anchors.bottomMargin: 7
                                                    color: playBtnMouse.containsMouse ? "#40A78BFA" : "#601E1B2E"
                                                    border.width: 1.5; border.color: playBtnMouse.containsMouse ? "#A78BFA" : "#40A78BFA"
                                                    scale: playBtnMouse.containsMouse ? 1.12 : 1.0
                                                    Behavior on color { ColorAnimation { duration: 150 } }
                                                    Behavior on border.color { ColorAnimation { duration: 150 } }
                                                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                                    z: 5

                                                    MouseArea {
                                                        id: playBtnMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        onClicked: serverManager.joinServer(modelData, appController.defaultConnectProtocol)
                                                    }

                                                    Canvas {
                                                        anchors.centerIn: parent; width: 10; height: 12
                                                        onPaint: {
                                                            var ctx = getContext("2d"); ctx.reset()
                                                            ctx.fillStyle = playBtnMouse.containsMouse ? "#FFFFFF" : "#a0e8d8"
                                                            ctx.beginPath()
                                                            ctx.moveTo(1, 1); ctx.lineTo(9, 6); ctx.lineTo(1, 11)
                                                            ctx.closePath(); ctx.fill()
                                                        }
                                                    }
                                                }

                                                Column {
                                                    anchors.centerIn: parent
                                                    spacing: 4
                                                    visible: !serverCard.previewUrl || serverCard.previewUrl === "loading" || cardSrv.status !== 1
                                                    Text {
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        text: {
                                                            if (cardSrv.status === 0) return "检测中"
                                                            if (cardSrv.status === 2) return "离线"
                                                            if (serverCard.previewUrl === "loading") return "正在加载预览图"
                                                            if (!serverCard.previewUrl) return "无预览图"
                                                            return ""
                                                        }
                                                        color: "#8090A0"; font.pixelSize: 10
                                                        style: Text.Raised; styleColor: "#60000000"
                                                    }
                                                }

                                                Rectangle {
                                                    anchors.fill: parent
                                                    radius: 10
                                                    color: "transparent"
                                                    border.width: 1.5
                                                    border.color: cardMouse.containsMouse ? "#E0D0FF" : "#80A78BFA"
                                                    Behavior on border.color { ColorAnimation { duration: 150 } }
                                                }

                                                MouseArea {
                                                    id: cardMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                                    onPressed: {
                                                        if (mouse.button === Qt.RightButton) {
                                                            mouse.accepted = true
                                                            var pos = parent.mapToItem(serverListPage, mouse.x, mouse.y)
                                                            serverListPage.showServerMenu(modelData, pos.x, pos.y)
                                                        }
                                                    }
                                                    onClicked: {
                                                        if (mouse.button === Qt.RightButton) { mouse.accepted = true; return }
                                                        openJoinPanel(modelData)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            id: communityHeader
                            width: parent.width
                            height: 42
                            radius: 8
                            color: commHeaderMouse.containsMouse ? "#d0252040" : "#c01E1B2E"
                            border.width: 1; border.color: "#25A78BFA"
                            Behavior on color { ColorAnimation { duration: 150 } }

                            MouseArea {
                                id: commHeaderMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: serverListPage.toggleCardGroup(communityName)
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 10
                                Canvas {
                                    width: 16; height: 16
                                    rotation: cardCommunityItem.expanded ? 90 : 0
                                    Behavior on rotation { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.reset()
                                        ctx.strokeStyle = App.Theme.primary
                                        ctx.lineWidth = 2; ctx.lineCap = "round"; ctx.lineJoin = "round"
                                        ctx.beginPath()
                                        ctx.moveTo(5, 4); ctx.lineTo(11, 8); ctx.lineTo(5, 12)
                                        ctx.stroke()
                                    }
                                }
                                Text { text: communityName; font.bold: true; color: App.Theme.textPrimary; font.pixelSize: 15 }
                                Item { Layout.fillWidth: true }
                            }
                        }
                    }
                }
            }
        }
    }

    
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
            width: 710
            height: 390
            radius: 14
            color: "#e81E1B2E"
            border.width: 1; border.color: "#FF2D3245"
            scale: joinPanelVisible ? 1.0 : 0.88
            opacity: joinPanelVisible ? 1.0 : 0.0
            visible: joinPanelMask.visible
            clip: true
            Behavior on scale { NumberAnimation { duration: joinPanelVisible ? 280 : 150; easing.type: joinPanelVisible ? Easing.OutBack : Easing.InCubic } }
            Behavior on opacity { NumberAnimation { duration: joinPanelVisible ? 220 : 120 } }

            
            MouseArea { anchors.fill: parent; propagateComposedEvents: false }

            
            Rectangle {
                id: panelHeader
                width: parent.width
                height: 56
                radius: 14
                color: "#c0121525"

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 14
                    color: "#c0121525"
                }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Text {
                        text: "挤服"
                        color: App.Theme.primary
                        font.pixelSize: 12
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle { width: 1; height: 16; color: "#30A78BFA"; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        text: appController.autoJoining ? (selectedServer.displayName || "未知服务器") : (appController.currentServerName || selectedServer.displayName || "未知服务器")
                        color: App.Theme.textPrimary
                        font.pixelSize: 14
                        font.bold: true
                        width: 480
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                
                Rectangle {
                    id: panelPlayerBadge
                    anchors.right: panelCloseBtn.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 76; height: 26; radius: 13
                    color: appController.autoJoining ? "#30A78BFA" : (appController.serverStatus === 1 ? "#30A78BFA" : "#30252040")
                    border.width: 1; border.color: appController.autoJoining ? App.Theme.primary : (appController.serverStatus === 1 ? App.Theme.primary : "#FF2D3245")

                    Text {
                        anchors.centerIn: parent
                        text: appController.autoJoining ? (selectedServer.players + "/" + selectedServer.maxPlayers) : (appController.serverStatus === 0 ? "检测中" : (appController.serverStatus === 2 ? "离线" : appController.currentPlayers + "/" + appController.maxPlayers))
                        color: appController.autoJoining ? App.Theme.primary : (appController.serverStatus === 1 ? App.Theme.primary : App.Theme.textSecondary)
                        font.pixelSize: 11; font.bold: true
                    }
                }

                
                Rectangle {
                    id: panelCloseBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 26; height: 26; radius: 7
                    color: closeMouse.containsMouse ? "#40e74c3c" : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Canvas {
                        anchors.centerIn: parent; width: 11; height: 11
                        onPaint: {
                            var ctx = getContext("2d"); ctx.reset()
                            ctx.strokeStyle = closeMouse.containsMouse ? "#e74c3c" : App.Theme.textSecondary
                            ctx.lineWidth = 2; ctx.lineCap = "round"
                            ctx.beginPath(); ctx.moveTo(2,2); ctx.lineTo(9,9); ctx.moveTo(9,2); ctx.lineTo(2,9); ctx.stroke()
                        }
                    }
                    MouseArea { id: closeMouse; anchors.fill: parent; hoverEnabled: true; onClicked: joinPanelVisible = false }
                }
            }

            
            Item {
                id: panelBody
                anchors.top: panelHeader.bottom
                anchors.bottom: parent.bottom
                width: parent.width

                
                Rectangle {
                    id: mapPreviewArea
                    width: 280
                    height: 158
                    anchors.top: parent.top
                    anchors.topMargin: 14
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    radius: 0
                    color: "#FF0d1018"
                    border.width: 1
                    border.color: App.Theme.primary
                    clip: true

                    Image {
                        id: mapImg
                        anchors.fill: parent
                        anchors.margins: 1
                        fillMode: Image.PreserveAspectCrop
                        source: joinPanelVisible ? workshopPreviewUrl : ""
                        asynchronous: true
                        onStatusChanged: {
                            if (status === Image.Ready) mapPlaceholder.visible = false
                            else if (status === Image.Error) mapPlaceholder.visible = true
                        }
                    }

                    Rectangle {
                        id: mapPlaceholder
                        anchors.fill: parent
                        anchors.margins: 1
                        color: "#FF0d1018"
                        visible: true
                        Column {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "暂无创意工坊预览图"
                                color: "#FF6B7288"
                                font.pixelSize: 12
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: appController.currentMap || ""
                                color: "#FF4A5068"
                                font.pixelSize: 10
                                font.family: "Consolas"
                            }
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 1
                        height: 70
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 1.0; color: "#cc1E1B2E" }
                        }
                    }

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 10
                        spacing: 2

                        Text {
                            width: parent.width
                            text: appController.serverStatus === 1 ? serverListPage.mapTranslate(appController.currentMap) : "—"
                            color: "#ffffff"
                            font.pixelSize: 14
                            font.bold: true
                            style: Text.Outline; styleColor: "#80000000"
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            text: appController.serverStatus === 1 ? appController.currentMap : ""
                            color: "#c0ffffff"
                            font.pixelSize: 10
                            style: Text.Outline; styleColor: "#80000000"
                            elide: Text.ElideRight
                        }
                    }
                }

                
                ColumnLayout {
                    anchors.top: parent.top
                    anchors.topMargin: 14
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 14
                    anchors.left: mapPreviewArea.right
                    anchors.leftMargin: 14
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    spacing: 8

                
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
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

                
                Rectangle { Layout.fillWidth: true; height: 1; color: "#201E1B2E" }

                
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

                
                Rectangle { Layout.fillWidth: true; height: 1; color: "#201E1B2E" }

                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text { text: "挤服核心数"; color: App.Theme.textPrimary; font.pixelSize: 13; font.bold: true; Layout.alignment: Qt.AlignVCenter }
                        Text { text: "[非必要情况不用改动 拉满对服务器压力极大]"; color: "#607080"; font.pixelSize: 11; Layout.alignment: Qt.AlignVCenter }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: appController.activeJoinCoreCount + " / " + appController.cpuCoreCount + " 核"
                            color: appController.activeJoinCoreCount >= 6 ? "#FFE74C3C" : (appController.activeJoinCoreCount === 5 ? "#FFF1C40F" : App.Theme.primary)
                            font.pixelSize: 13; font.bold: true
                        }
                    }

                    Slider {
                        id: panelCoreSlider
                        Layout.fillWidth: true
                        from: 1
                        to: appController.cpuCoreCount
                        stepSize: 1
                        value: appController.activeJoinCoreCount
                        onValueChanged: appController.activeJoinCoreCount = Math.round(value)
                        implicitHeight: 20
                        background: Rectangle {
                            x: 0; y: parent.height / 2 - height / 2
                            width: parent.width; height: 4; radius: 2
                            color: "#40252040"
                            Rectangle {
                                width: panelCoreSlider.visualPosition * (panelCoreSlider.width - 16) + 8
                                height: parent.height; radius: 2
                                color: App.Theme.primary
                            }
                        }
                        handle: Rectangle {
                            width: 16; height: 16; radius: 8
                            color: "white"
                            border.width: 2; border.color: App.Theme.primary
                            x: panelCoreSlider.visualPosition * (panelCoreSlider.width - width)
                            y: panelCoreSlider.height / 2 - height / 2
                        }
                    }
                }

                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

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
                        implicitHeight: 20
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

                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

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
                        color: appController.autoJoining ? "#602A2A3A" : (startBtnMouse.containsMouse ? "#e0A78BFA" : "#c0A78BFA")
                        border.width: 1; border.color: appController.autoJoining ? "#404A4A5A" : (startBtnMouse.containsMouse ? "#ffffff" : App.Theme.primary)
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        MouseArea { id: startBtnMouse; anchors.fill: parent; hoverEnabled: !appController.autoJoining; cursorShape: appController.autoJoining ? Qt.ArrowCursor : Qt.PointingHandCursor; onClicked: { if (!appController.autoJoining) { appController.startAutoJoin(); joinPanelVisible = false } } }
                        Text { anchors.centerIn: parent; text: appController.autoJoining ? "正在挤服中..." : "开始挤服"; color: appController.autoJoining ? "#606A7A" : "#0a0a14"; font.pixelSize: 13; font.bold: true }
                    }
                }
            }
            }
        }
    }

    
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

    
    MouseArea {
        anchors.fill: parent
        visible: communityMenuVisible
        z: 499
        onClicked: closeCommunityMenu()
    }

    
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

    
    MouseArea {
        anchors.fill: parent
        visible: serverMenuVisible
        z: 499
        onClicked: closeServerMenu()
    }

    
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
        
        isUBServer = false
        ubPlayerData = null
        playerQuery.clearPlayers()
        playerListVisible = true
        
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

                            
                            Column {
                                Layout.fillWidth: true
                                spacing: 14
                                visible: isUBServer

                                
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
                                                id: ctCapsule
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
                                                    width: parent.width - 16
                                                    Text {
                                                        id: ctName
                                                        text: modelData.name || "未命名"
                                                        color: modelData.commander > 0 ? "#FFD700" : "#FFFFFF"
                                                        font.pixelSize: 12
                                                        elide: Text.ElideRight; maximumLineCount: 1
                                                        width: parent.width
                                                    }
                                                }
                                                MouseArea { id: plCtMouse; anchors.fill: parent; hoverEnabled: true }
                                            }
                                        }
                                    }
                                }

                                
                                
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
                                                id: tCapsule
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
                                                    width: parent.width - 16
                                                    Text {
                                                        id: tName
                                                        text: modelData.name || "未命名"
                                                        color: modelData.commander > 0 ? "#FFD700" : "#FFFFFF"
                                                        font.pixelSize: 12
                                                        elide: Text.ElideRight; maximumLineCount: 1
                                                        width: parent.width
                                                    }
                                                }
                                                MouseArea { id: plT2Mouse; anchors.fill: parent; hoverEnabled: true }
                                            }
                                        }
                                    }
                                }

                                
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
                                                id: obsCapsule
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
                                                    width: parent.width - 16
                                                    Text {
                                                        id: obsName
                                                        text: modelData.name || "未命名"
                                                        color: modelData.commander > 0 ? "#FFD700" : "#FFFFFF"
                                                        font.pixelSize: 12
                                                        elide: Text.ElideRight; maximumLineCount: 1
                                                        width: parent.width
                                                    }
                                                }
                                                MouseArea { id: plObsMouse; anchors.fill: parent; hoverEnabled: true }
                                            }
                                        }
                                    }
                                }

                                
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

    
    property bool sortDropdownOpen: false
    property real sortDropdownMask: 0
    property bool panelProtoDropdownOpen: false
    property real panelProtoDropdownMask: 0

    function toggleSortDropdown() {
        sortDropdownOpen = !sortDropdownOpen
        if (sortDropdownOpen) {
            var pos = sortDropBtn.mapToItem(serverListPage, 0, sortDropBtn.height - 2)
            sortDropdown.x = pos.x; sortDropdown.y = pos.y; sortDropdown.width = sortDropBtn.width
            sortDropdownMask = 0; sortDropdownAnim.to = 234; sortDropdownAnim.start()
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

    
    Rectangle {
        id: sortDropdown
        visible: sortDropdownOpen || sortDropdownMask > 0.5
        z: 102; height: 234; radius: 8
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
                        id: filterDelegate
                        width: parent.width; height: 30; radius: 6
                        color: filterItemMouse.containsMouse ? "#28252040" : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }
                        property bool checked: serverManager.filterOptions.indexOf(modelData) >= 0

                        Rectangle {
                            anchors.left: parent.left; anchors.leftMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16; height: 16; radius: 4
                            color: filterDelegate.checked ? App.Theme.primary : "transparent"
                            border.width: 2; border.color: filterDelegate.checked ? App.Theme.primary : App.Theme.textSecondary
                            Text { anchors.centerIn: parent; text: "✓"; color: "white"; font.pixelSize: 10; visible: filterDelegate.checked }
                        }

                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 26
                            anchors.right: parent.right; anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData
                            color: filterDelegate.checked ? App.Theme.primary : "#FFFFFF"
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: filterItemMouse
                            anchors.fill: parent; hoverEnabled: true
                            onClicked: {
                                var name = modelData
                                var arr = serverManager.filterOptions.slice()
                                var idx = arr.indexOf(name)
                                if (idx >= 0) arr.splice(idx, 1)
                                else arr.push(name)
                                serverManager.filterOptions = arr
                                appController.serverListFilterOptions = arr
                            }
                        }
                    }
                }
            }
        }
    }

    
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

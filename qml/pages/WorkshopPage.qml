import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import "qrc:/qml" as App

Rectangle {
    id: workshopPage
    property bool pageActive: false
    property bool showCard1: false
    property bool showCard2: false

    onPageActiveChanged: { if (!pageActive) { showCard1 = false; showCard2 = false } }

    Timer { interval: 200; repeat: false; running: pageActive; onTriggered: showCard1 = true }
    Timer { interval: 400; repeat: false; running: pageActive; onTriggered: showCard2 = true }

    color: "transparent"

    property string searchText: ""
    property var filteredMaps: []
    property bool pathInputVisible: false
    property bool pathInputRealVisible: false
    property string pathInputText: ""
    property var pathSuggestions: []
    property bool pathDropdownVisible: false
    property string ctxMapName: ""
    property string ctxMapId: ""
    property string ctxMapPath: ""
    property bool ctxMenuVisible: false
    property bool ctxMenuClosing: false
    property real ctxMenuX: 0
    property real ctxMenuY: 0

    
    property string detailMapName: ""
    property string detailMapId: ""
    property string detailMapPath: ""
    property string detailMapVpkName: ""
    property bool detailMapInstalled: false
    property bool detailVisible: false
    property bool detailClosing: false
    property bool workshopConnected: false

    function showCtxMenu(x, y) {
        ctxMenuX = Math.min(x, width - 215)
        ctxMenuY = Math.min(y, height - 170)
        ctxMenuClosing = false
        ctxMenuVisible = true
    }

    function closeCtxMenu() {
        if (!ctxMenuVisible || ctxMenuClosing) return
        ctxMenuClosing = true
        ctxMenuCloseTimer.restart()
    }

    Timer {
        id: ctxMenuCloseTimer
        interval: 160
        onTriggered: {
            ctxMenuVisible = false
            ctxMenuClosing = false
        }
    }

    
    function loadWorkshopPreview(workshopId) {
        if (!workshopId || workshopId.length === 0) return
        detailImg.source = ""
        wsDetailPlaceholder.visible = true
        var xhr = new XMLHttpRequest()
        xhr.open("POST", "https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/")
        xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText)
                    if (data.response && data.response.publishedfiledetails && data.response.publishedfiledetails.length > 0) {
                        var url = data.response.publishedfiledetails[0].preview_url
                        if (url && url.length > 0) {
                            detailImg.source = url
                        } else {
                            wsDetailPlaceholder.visible = true
                        }
                    }
                } catch(e) {}
            }
        }
        xhr.send("itemcount=1&publishedfileids[0]=" + workshopId)
    }

    onDetailVisibleChanged: {
        if (detailVisible) {
            detailImg.source = ""
            loadWorkshopPreview(detailMapId)
        }
    }

    onPathInputVisibleChanged: {
        if (pathInputVisible) {
            pathInputRealVisible = true
        } else {
            pathCloseTimer.start()
        }
    }

    function updatePathSuggestions() {
        var kw = pathField.text.trim().toLowerCase()
        var libs = workshopManager.libraryPaths
        var result = []
        for (var i = 0; i < libs.length; i++) {
            var fullPath = libs[i].replace(/\
            if (kw.length === 0 || fullPath.toLowerCase().indexOf(kw) >= 0) {
                result.push(fullPath)
            }
        }
        pathSuggestions = result
        pathDropdownVisible = result.length > 0 && pathField.activeFocus
    }
    function hidePathDropdown() { pathDropdownVisible = false }

    function updateFilter() {
        var list = workshopManager.maps
        var kw = searchText.trim().toLowerCase()
        if (kw.length === 0) {
            filteredMaps = list
            return
        }
        var result = []
        for (var i = 0; i < list.length; i++) {
            var m = list[i]
            if (m.name.toLowerCase().indexOf(kw) >= 0 ||
                m.workshopId.indexOf(kw) >= 0) {
                result.push(m)
            }
        }
        filteredMaps = result
    }

    Connections {
        target: workshopManager
        function onMapsChanged() { workshopPage.updateFilter() }
    }

    Component.onCompleted: updateFilter()

    ColumnLayout {
        id: mainCol
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        Text {
            Layout.fillWidth: true
            text: "创意工坊地图"
            font.family: App.Theme.fontFamily
            color: App.Theme.textPrimary
            font.pixelSize: 22
            font.bold: true
        }
        Text {
            Layout.fillWidth: true
            text: "共 " + workshopManager.totalCount + " 张 · 已安装 " + workshopManager.installedCount + " 张"
            color: "#FF9BA1B5"
            font.pixelSize: 12
        }

        RowLayout {
                id: staggerChild0
                
            Layout.fillWidth: true
            spacing: 8

            TextField {

                Layout.fillWidth: true
                Layout.preferredHeight: 36
                placeholderText: "搜索地图名或工坊ID..."
                color: "#FFFFFF"
                font.pixelSize: 13
                selectByMouse: true
                background: Rectangle {
                    color: "#601E1B2E"
                    radius: 8
                    border.width: 1
                    border.color: "#FF2D3245"
                }
                onTextChanged: {
                    workshopPage.searchText = text
                    workshopPage.updateFilter()
                }
            }

            Rectangle {
                Layout.preferredWidth: 80
                Layout.preferredHeight: 36
                radius: 8
                color: wsRefreshMouse.containsMouse ? "#d0252040" : "#b01E1B2E"
                border.width: 1
                border.color: wsRefreshMouse.containsMouse ? App.Theme.primary : "#FF2D3245"
                Behavior on color { ColorAnimation { duration: 150 } }
                Text {
                    anchors.centerIn: parent
                    text: workshopManager.scanning ? "扫描中..." : "刷新"
                    color: "#FFFFFF"
                    font.pixelSize: 13
                }
                MouseArea {
                    id: wsRefreshMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: workshopManager.refresh()
                }
            }

            Rectangle {
                Layout.preferredWidth: 80
                Layout.preferredHeight: 36
                radius: 8
                color: workshopConnected ? (wsConnectMouse.containsMouse ? "#30FF6644" : "#20FF4444") : (wsConnectMouse.containsMouse ? "#30A78BFA" : "#15A78BFA")
                border.width: 1
                border.color: workshopConnected ? "#FF4444" : "#FFA78BFA"
                Behavior on color { ColorAnimation { duration: 150 } }
                Text {
                    anchors.centerIn: parent
                    text: workshopConnected ? "断开" : "连接"
                    color: "#FFFFFF"
                    font.pixelSize: 13
                    font.bold: true
                }
                MouseArea {
                    id: wsConnectMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (!workshopConnected) {
                            workshopConnected = true
                            workshopManager.refresh()
                        } else {
                            workshopConnected = false
                            workshopManager.clearMaps()
                        }
                    }
                }
            }
        }

        RowLayout {
                id: staggerChild1
                opacity: showCard1 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            Layout.minimumHeight: 32
            Layout.maximumHeight: 32
            spacing: 6
            visible: workshopManager.primaryWorkshopPath.length > 0

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 8
                color: "#FF1E1B2E"
                border.width: 1
                border.color: "#FF2D3245"

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: Text.AlignVCenter
                    text: workshopManager.primaryWorkshopPath.replace(/\
                    color: "#FF9BA1B5"
                    font.pixelSize: 11
                    elide: Text.ElideMiddle
                }
            }

            Rectangle {
                Layout.preferredWidth: 72
                Layout.fillHeight: true
                radius: 8
                color: wsPathMouse.containsMouse ? "#d0252040" : "#b01E1B2E"
                border.width: 1
                border.color: wsPathMouse.containsMouse ? App.Theme.primary : "#FF2D3245"
                Behavior on color { ColorAnimation { duration: 150 } }
                scale: wsPathMouse.pressed ? 0.92 : 1.0
                Behavior on scale { NumberAnimation { duration: 100 } }
                Text {
                    anchors.centerIn: parent
                    text: "更改路径"
                    color: "#FFFFFF"
                    font.pixelSize: 12
                }
                MouseArea {
                    id: wsPathMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        workshopPage.pathInputText = workshopManager.primaryWorkshopPath.replace(/\
                        workshopPage.pathInputVisible = true
                        workshopPage.updatePathSuggestions()
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 72
                Layout.fillHeight: true
                radius: 8
                color: wsAutoMouse.containsMouse ? "#d0A78BFA" : "#b0A78BFA"
                border.width: 1
                border.color: wsAutoMouse.containsMouse ? "#FF00FFCC" : "#80A78BFA"
                Behavior on color { ColorAnimation { duration: 150 } }
                scale: wsAutoMouse.pressed ? 0.92 : 1.0
                Behavior on scale { NumberAnimation { duration: 100 } }
                Text {
                    anchors.centerIn: parent
                    text: workshopManager.scanning ? "检测中..." : "自动检测"
                    color: "#FF0a0f1a"
                    font.pixelSize: 12
                    font.bold: true
                }
                MouseArea {
                    id: wsAutoMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: workshopManager.refresh()
                }
            }
        }

        Rectangle {
                id: staggerChild2
                opacity: showCard2 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                

            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 10
            color: "#151E1B2E"
            border.width: 1
            border.color: "#15A78BFA"
            clip: true

            Flickable {
                id: wsFlick
                anchors.fill: parent
                anchors.margins: 6
                contentHeight: wsColumn.height + 8
                contentWidth: width
                clip: true
                boundsBehavior: Flickable.DragOverBounds

                Column {
                    id: wsColumn
                    width: wsFlick.width - 12
                    spacing: 5
                    topPadding: 4

                    Repeater {
                        model: workshopPage.filteredMaps

                        Rectangle {
                            width: wsColumn.width - 4
                            height: 52
                            radius: 8
                            color: wsItemHover.containsMouse ? "#28A78BFA" : (modelData.installed ? "#20A78BFA" : "#251E1B2E")
                            border.width: wsItemHover.containsMouse ? 2 : 1
                            border.color: wsItemHover.containsMouse ? "#FFA78BFA" : (modelData.installed ? "#40A78BFA" : "#15A78BFA")
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.width { NumberAnimation { duration: 120 } }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                width: 8; height: 8; radius: 4
                                color: modelData.installed ? "#FFA78BFA" : "#FF555555"
                            }

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 26
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 36
                                spacing: 2
                                Text {
                                    text: modelData.name
                                    color: "#FFFFFF"
                                    font.pixelSize: 12
                                    font.bold: true
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                                Text {
                                    text: "ID: " + modelData.workshopId + (modelData.installed ? "  ·  已安装" : "  ·  未安装")
                                    color: "#FF9BA1B5"
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }

                            
                            MouseArea {
                                id: wsItemHover
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onPressed: function(mouse) {
                                    if (mouse.button === Qt.RightButton) {
                                        mouse.accepted = true
                                        ctxMapName = modelData.name
                                        ctxMapId = modelData.workshopId
                                        ctxMapPath = modelData.path
                                        var globalPos = wsItemHover.mapToItem(workshopPage, mouse.x, mouse.y)
                                        showCtxMenu(globalPos.x, globalPos.y)
                                    }
                                }
                                onClicked: function(mouse) {
                                    if (mouse.button === Qt.LeftButton) {
                                        detailMapName = modelData.name
                                        detailMapId = modelData.workshopId
                                        detailMapPath = modelData.path
                                        detailMapVpkName = modelData.vpkName
                                        detailMapInstalled = modelData.installed
                                        detailVisible = true
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        visible: workshopPage.filteredMaps.length === 0
                        width: parent.width
                        spacing: 8
                        topPadding: 40

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: !workshopConnected ? "点击上方「连接」按钮加载创意工坊地图" : (workshopManager.scanning ? "正在扫描本地工坊..." : "暂无地图")
                            color: "#FF9BA1B5"
                            font.pixelSize: 13
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: !workshopConnected ? "本功能只读取Steam创意工坊地图列表，没有任何病毒软件窃取" : ""
                            color: "#FF6B7288"
                            font.pixelSize: 13
                        }
                    }
                }
            }

            
            Rectangle {
                anchors.right: parent.right; anchors.rightMargin: 2
                anchors.top: parent.top; anchors.topMargin: 4
                anchors.bottom: parent.bottom; anchors.bottomMargin: 4
                width: 5; radius: 2.5
                color: "#15A78BFA"
                visible: wsFlick.contentHeight > wsFlick.height + 1
            }

            
            Rectangle {
                anchors.right: parent.right; anchors.rightMargin: 2
                width: 5; radius: 2.5
                color: "#A0A78BFA"
                visible: wsFlick.contentHeight > wsFlick.height + 1
                height: Math.min(wsFlick.height - 8, Math.max(24, (wsFlick.height - 8) * (wsFlick.height - 8) / Math.max(1, wsFlick.contentHeight)))
                y: {
                    if (wsFlick.contentHeight <= wsFlick.height) return 4;
                    var scrollRange = wsFlick.contentHeight - wsFlick.height;
                    var thumbRange = (wsFlick.height - 8) - height;
                    return 4 + (wsFlick.contentY / scrollRange) * thumbRange;
                }
            }
        }
    }

    
    Rectangle {
        id: pathInputOverlay
        anchors.fill: parent
        color: "#80000000"
        visible: pathInputRealVisible
        opacity: pathInputVisible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        z: 100

        Timer {
            id: pathCloseTimer
            interval: 240
            onTriggered: pathInputRealVisible = false
        }

        MouseArea {
            anchors.fill: parent
            onClicked: pathInputVisible = false
        }

        Rectangle {
            id: pathInputDialog
            anchors.centerIn: parent
            width: 500
            height: 300
            radius: 12
            color: "#FF1e2235"
            border.width: 1
            border.color: "#FF2D3245"
            scale: pathInputVisible ? 1.0 : 0.88
            Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    text: "选择工坊地图路径"
                    color: "#FFFFFF"
                    font.pixelSize: 15
                    font.bold: true
                }

                TextField {
                    id: pathField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    text: workshopPage.pathInputText
                    color: "#FFFFFF"
                    font.pixelSize: 12
                    selectByMouse: true
                    background: Rectangle {
                        color: "#FF141825"
                        radius: 8
                        border.width: 1
                        border.color: pathField.activeFocus ? App.Theme.primary : "#FF2D3245"
                    }
                    onTextChanged: workshopPage.updatePathSuggestions()
                    onActiveFocusChanged: {
                        if (activeFocus) workshopPage.updatePathSuggestions()
                        else { pathDropHideTimer.restart() }
                    }
                    onAccepted: {
                        if (text.trim().length > 0) {
                            workshopManager.setCustomPath(text.trim())
                            workshopPage.pathInputVisible = false
                        }
                    }
                }

                Timer {
                    id: pathDropHideTimer
                    interval: 150
                    onTriggered: pathDropdownVisible = false
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 140
                    radius: 8
                    color: "#f01E1B2E"
                    border.width: 1
                    border.color: "#30A78BFA"
                    visible: pathDropdownVisible
                    clip: true

                    Flickable {
                        id: pathDropFlick
                        anchors.fill: parent
                        anchors.margins: 4
                        contentHeight: pathDropCol.height
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Column {
                            id: pathDropCol
                            width: pathDropFlick.width
                            spacing: 1
                            Repeater {
                                model: pathSuggestions
                                delegate: Rectangle {
                                    width: pathDropCol.width
                                    height: 32
                                    radius: 5
                                    color: pathDropItemMouse.containsMouse ? "#25A78BFA" : "transparent"
                                    Behavior on color { ColorAnimation { duration: 80 } }
                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData
                                        color: "#FFFFFF"
                                        font.pixelSize: 12
                                        elide: Text.ElideMiddle
                                        width: parent.width - 20
                                    }
                                    MouseArea {
                                        id: pathDropItemMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            pathField.text = modelData
                                            hidePathDropdown()
                                            pathField.focus = true
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: pathDropScrollbar
                        anchors.right: parent.right
                        anchors.rightMargin: 1
                        width: 3
                        radius: 1.5
                        color: "#40A78BFA"
                        visible: pathDropFlick.contentHeight > pathDropFlick.height + 1
                        height: Math.min(pathDropFlick.height - 8, Math.max(20, (pathDropFlick.height - 8) * (pathDropFlick.height - 8) / Math.max(1, pathDropFlick.contentHeight)))
                        y: {
                            if (pathDropFlick.contentHeight <= pathDropFlick.height) return 4;
                            var scrollRange = pathDropFlick.contentHeight - pathDropFlick.height;
                            var thumbRange = (pathDropFlick.height - 8) - pathDropScrollbar.height;
                            return 4 + (pathDropFlick.contentY / scrollRange) * thumbRange;
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignRight
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: 80
                        Layout.preferredHeight: 32
                        radius: 8
                        color: pathCancelMouse.containsMouse ? "#d0252040" : "#b01E1B2E"
                        border.width: 1
                        border.color: "#FF2D3245"
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text {
                            anchors.centerIn: parent
                            text: "取消"
                            color: "#FF9BA1B5"
                            font.pixelSize: 12
                        }
                        MouseArea {
                            id: pathCancelMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: pathInputVisible = false
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 80
                        Layout.preferredHeight: 32
                        radius: 8
                        color: pathOkMouse.containsMouse ? "#d0A78BFA" : "#b0A78BFA"
                        border.width: 1
                        border.color: "#80A78BFA"
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text {
                            anchors.centerIn: parent
                            text: "确定"
                            color: "#FF0a0f1a"
                            font.pixelSize: 12
                            font.bold: true
                        }
                        MouseArea {
                            id: pathOkMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                var p = pathField.text.trim()
                                if (p.length > 0) {
                                    workshopManager.setCustomPath(p)
                                    pathInputVisible = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    
    MouseArea {
        anchors.fill: parent
        z: 101
        visible: ctxMenuVisible
        onClicked: closeCtxMenu()
    }

    
    Rectangle {
        id: wsCtxMenu
        x: ctxMenuX
        y: ctxMenuY
        width: 210
        height: wsCtxCol.childrenRect.height + 8
        radius: 8
        color: "#FF1E1B2E"
        border.width: 1
        border.color: "#40A78BFA"
        visible: ctxMenuVisible
        opacity: ctxMenuVisible && !ctxMenuClosing ? 1.0 : 0.0
        scale: ctxMenuVisible && !ctxMenuClosing ? 1.0 : 0.85
        Behavior on opacity { NumberAnimation { duration: ctxMenuClosing ? 140 : 150; easing.type: ctxMenuClosing ? Easing.InCubic : Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: ctxMenuClosing ? 140 : 150; easing.type: ctxMenuClosing ? Easing.InCubic : Easing.OutCubic } }
        z: 102

        Column {
            id: wsCtxCol
            width: parent.width
            spacing: 0

            
            Rectangle {
                width: parent.width
                height: 38
                color: ctxItem1.containsMouse ? "#25A78BFA" : "transparent"
                Behavior on color { ColorAnimation { duration: 80 } }
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: "打开创意工坊地图"
                    color: "#FFFFFF"
                    font.pixelSize: 12
                }
                MouseArea {
                    id: ctxItem1
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        workshopManager.openWeb(ctxMapId)
                        closeCtxMenu()
                    }
                }
            }

            
            Rectangle {
                width: parent.width
                height: 38
                color: ctxItem2.containsMouse ? "#25A78BFA" : "transparent"
                Behavior on color { ColorAnimation { duration: 80 } }
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: "复制地图名称"
                    color: "#FFFFFF"
                    font.pixelSize: 12
                }
                MouseArea {
                    id: ctxItem2
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        workshopManager.copyName(ctxMapName)
                        closeCtxMenu()
                    }
                }
            }

            
            Rectangle {
                width: parent.width
                height: 38
                color: ctxItem3.containsMouse ? "#25A78BFA" : "transparent"
                Behavior on color { ColorAnimation { duration: 80 } }
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: "复制地图ID"
                    color: "#FFFFFF"
                    font.pixelSize: 12
                }
                MouseArea {
                    id: ctxItem3
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        workshopManager.copyId(ctxMapId)
                        closeCtxMenu()
                    }
                }
            }

            
            Rectangle {
                width: parent.width
                height: 38
                color: ctxItem4.containsMouse ? "#25A78BFA" : "transparent"
                Behavior on color { ColorAnimation { duration: 80 } }
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: "打开地图文件夹位置"
                    color: "#FFFFFF"
                    font.pixelSize: 12
                }
                MouseArea {
                    id: ctxItem4
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        workshopManager.openFolder(ctxMapPath)
                        closeCtxMenu()
                    }
                }
            }

            
            Rectangle {
                width: parent.width - 20
                height: 1
                color: "#20A78BFA"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            
            Rectangle {
                width: parent.width
                height: 38
                color: ctxItem5.containsMouse ? "#30FF4444" : "transparent"
                Behavior on color { ColorAnimation { duration: 80 } }
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: "删除地图并重启Steam"
                    color: "#FF8888"
                    font.pixelSize: 12
                }
                MouseArea {
                    id: ctxItem5
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        closeCtxMenu()
                        workshopManager.deleteMapAndRestartSteam(ctxMapPath)
                    }
                }
            }
        }
    }

    
    MouseArea {
        anchors.fill: parent
        z: 80
        visible: detailVisible
        onClicked: {
            if (!detailClosing) {
                detailClosing = true
                detailCloseTimer.restart()
            }
        }
    }

    Timer {
        id: detailCloseTimer
        interval: 200
        onTriggered: {
            detailVisible = false
            detailClosing = false
        }
    }

    
    Rectangle {
        id: detailPanel
        width: 620
        height: 280
        radius: 12
        color: "#FF1E1B2E"
        border.width: 1
        border.color: "#40A78BFA"
        anchors.centerIn: parent
        visible: detailVisible
        opacity: detailVisible && !detailClosing ? 1.0 : 0.0
        scale: detailVisible && !detailClosing ? 1.0 : 0.85
        Behavior on opacity { NumberAnimation { duration: detailClosing ? 180 : 200; easing.type: detailClosing ? Easing.InCubic : Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: detailClosing ? 180 : 220; easing.type: detailClosing ? Easing.InCubic : Easing.OutBack } }
        z: 81

        
        Rectangle {
            id: detailImgBox
            width: 320
            height: 180
            radius: 8
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.top: parent.top
            anchors.topMargin: 16
            color: "#FF0d1018"
            border.width: 1
            border.color: "#20A78BFA"
            clip: true

            Image {
                id: detailImg
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                mipmap: true
                asynchronous: true
                onStatusChanged: {
                    if (status === Image.Ready) wsDetailPlaceholder.visible = false
                    else if (status === Image.Error) wsDetailPlaceholder.visible = true
                }
            }
            Rectangle {
                id: wsDetailPlaceholder
                anchors.fill: parent
                color: "#FF0d1018"
                visible: true
                Text { anchors.centerIn: parent; text: "加载预览图..."; color: "#FF6B7288"; font.pixelSize: 12 }
            }

            Text {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: 8
                text: detailMapVpkName
                color: "#80FFFFFF"
                font.pixelSize: 10
            }
        }

        
        Column {
            anchors.left: detailImgBox.right
            anchors.leftMargin: 16
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.top: parent.top
            anchors.topMargin: 16
            spacing: 12

            
            Text {
                width: parent.width
                text: detailMapName
                color: "#FFFFFF"
                font.pixelSize: 18
                font.bold: true
                elide: Text.ElideRight
                wrapMode: Text.Wrap
                maximumLineCount: 2
            }

            
            Row {
                spacing: 6
                Rectangle {
                    width: 10; height: 10; radius: 5
                    color: detailMapInstalled ? "#FFA78BFA" : "#FF555555"
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: detailMapInstalled ? "已安装" : "未安装"
                    color: detailMapInstalled ? "#FFA78BFA" : "#FF888888"
                    font.pixelSize: 13
                }
            }

            
            Rectangle { width: parent.width; height: 1; color: "#15A78BFA" }

            
            Row {
                spacing: 8
                Text { text: "工坊ID:"; color: "#FF9BA1B5"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                Text { text: detailMapId; color: "#FFFFFF"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
            }

            
            Row {
                width: parent.width
                spacing: 8
                Text { text: "工坊地址:"; color: "#FF9BA1B5"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    id: detailUrlText
                    text: "https://steamcommunity.com/sharedfiles/filedetails/?id=" + detailMapId
                    color: "#FFA78BFA"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    width: parent.width - 70
                    anchors.verticalCenter: parent.verticalCenter
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: workshopManager.openWeb(detailMapId)
                        onEntered: detailUrlText.color = "#FF80FFE0"
                        onExited: detailUrlText.color = "#FFA78BFA"
                    }
                }
            }

            
            Row {
                spacing: 8
                Text { text: "地图文件:"; color: "#FF9BA1B5"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                Text { text: detailMapVpkName + ".vpk"; color: "#FFFFFF"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; width: 200 }
            }

            
            Column {
                width: parent.width
                spacing: 4
                Text { text: "安装路径:"; color: "#FF9BA1B5"; font.pixelSize: 12 }
                Text {
                    text: detailMapPath
                    color: "#FFFFFF"
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                    width: parent.width
                }
            }
        }

        
        Text {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            text: "点击空白处关闭"
            color: "#FF6B7288"
            font.pixelSize: 11
        }
    }

}
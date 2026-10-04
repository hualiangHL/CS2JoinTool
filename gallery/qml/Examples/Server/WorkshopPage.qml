import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import HuskarUI.Basic


Rectangle {
    id: workshopPage
    anchors.fill: parent
    color: 'transparent'

    property bool pageActive: false
    property bool animationsReady: true
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
        var libs = WorkshopManager.libraryPaths
        var result = []
        for (var i = 0; i < libs.length; i++) {
            var fullPath = libs[i].replace(/\//g, "\\") + "\\steamapps\\workshop\\content\\730"
            if (kw.length === 0 || fullPath.toLowerCase().indexOf(kw) >= 0) {
                result.push(fullPath)
            }
        }
        pathSuggestions = result
        pathDropdownVisible = result.length > 0 && pathField.activeFocus
    }
    function hidePathDropdown() { pathDropdownVisible = false }

    function updateFilter() {
        var list = WorkshopManager.maps
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
        target: WorkshopManager
        function onMapsChanged() { workshopPage.updateFilter() }
    }

    Component.onCompleted: updateFilter()

    Item {
        id: mainCol
        anchors.fill: parent
        anchors.margins: 16


        RowLayout {
            id: titleRow
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 10
            HusText {
                text: Lang.tr('创意工坊地图','Workshop Maps')
                color: HusTheme.Primary.colorTextBase
                font.pixelSize: 18
                font.weight: Font.DemiBold
            }
            Item { Layout.fillWidth: true; height: 1 }

            Text {
                Layout.maximumWidth: 300
                text: WorkshopManager.primaryWorkshopPath.replace(/\//g, "\\")
                color: HusTheme.Primary.colorTextSecondary
                font.pixelSize: 10
                elide: Text.ElideMiddle
                visible: false
            }
            HusText {
                text: Lang.tr('共 %1 张 · 已安装 %2 张','%1 total · %2 installed').arg(WorkshopManager.totalCount).arg(WorkshopManager.installedCount)
                color: HusTheme.Primary.colorTextSecondary
                font.pixelSize: 11
            }
        }


        RowLayout {
            id: toolRow
            anchors.top: titleRow.bottom
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.right: parent.right
            height: 36
            spacing: 8

            TextField {
                id: searchField
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                placeholderText: Lang.tr('搜索地图名或工坊ID...','Search map name or workshop ID...')
                placeholderTextColor: HusTheme.Primary.colorTextSecondary
                color: HusTheme.Primary.colorTextBase
                selectionColor: Qt.rgba(HusTheme.Primary.colorPrimary.r, HusTheme.Primary.colorPrimary.g, HusTheme.Primary.colorPrimary.b, 0.25)
                font.pixelSize: 12
                background: Rectangle {
                    color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.45)
                    radius: 8
                    border.width: 1
                    border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5)
                }
                onTextChanged: {
                    workshopPage.searchText = text
                    workshopPage.updateFilter()
                }
            }

            Rectangle {
                Layout.preferredWidth: refreshLabel.implicitWidth + 40
                Layout.preferredHeight: 36
                radius: 8

                color: !workshopConnected ? HusThemeFunctions.alpha(HusTheme.Primary.colorTextDisabled, 0.10)
                       : (wsRefreshMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.30)
                                                       : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.55))
                border.width: 1
                border.color: !workshopConnected ? HusThemeFunctions.alpha(HusTheme.Primary.colorTextDisabled, 0.30)
                             : (wsRefreshMouse.containsMouse ? HusTheme.Primary.colorPrimary
                                                             : HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5))
                Behavior on color { ColorAnimation { duration: 150 } }
                Text {
                    id: refreshLabel
                    anchors.centerIn: parent
                    text: WorkshopManager.scanning ? Lang.tr('扫描中...','Scanning...') : Lang.tr('刷新','Refresh')
                    color: !workshopConnected ? HusThemeFunctions.alpha(HusTheme.Primary.colorTextDisabled, 0.55)
                           : HusTheme.Primary.colorTextBase
                    font.pixelSize: 12
                }
                MouseArea {
                    id: wsRefreshMouse
                    anchors.fill: parent
                    enabled: workshopConnected
                    hoverEnabled: true
                    onClicked: WorkshopManager.refresh()
                }
            }

            Rectangle {
                Layout.preferredWidth: connectLabel.implicitWidth + 40
                Layout.preferredHeight: 36
                radius: 8
                color: workshopConnected ? (wsConnectMouse.containsMouse ? '#30FF6644' : '#20FF4444')
                                         : (wsConnectMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.25)
                                                                          : HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.12))
                border.width: 1
                border.color: workshopConnected ? '#FF4444' : HusTheme.Primary.colorPrimary
                Behavior on color { ColorAnimation { duration: 150 } }
                Text {
                    id: connectLabel
                    anchors.centerIn: parent
                    text: workshopConnected ? Lang.tr('断开','Disconnect') : Lang.tr('连接','Connect')
                    color: workshopConnected ? '#FFFFFF' : HusTheme.Primary.colorPrimary
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    id: wsConnectMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (!workshopConnected) {
                            workshopConnected = true
                            WorkshopManager.refresh()
                        } else {
                            workshopConnected = false
                            WorkshopManager.clearMaps()
                        }
                    }
                }
            }
        }


        RowLayout {
            id: pathCard
            anchors.top: toolRow.bottom
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.right: parent.right
            height: 30
            spacing: 10
            visible: workshopConnected

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 8
                color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.55)
                border.width: 1
                border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.6)

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: Text.AlignVCenter
                    text: WorkshopManager.primaryWorkshopPath.replace(/\//g, "\\")
                    color: HusTheme.Primary.colorTextSecondary
                    font.pixelSize: 13
                    elide: Text.ElideMiddle
                }
            }

            Rectangle {
                Layout.preferredWidth: pathLabel.implicitWidth + 40
                Layout.fillHeight: true
                radius: 8
                color: wsPathMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.30) : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.55)
                border.width: 1
                border.color: wsPathMouse.containsMouse ? HusTheme.Primary.colorPrimary : HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5)
                Behavior on color { ColorAnimation { duration: 150 } }
                Text {
                    id: pathLabel
                    anchors.centerIn: parent
                    text: Lang.tr('更改路径','Change Path')
                    color: HusTheme.Primary.colorTextBase
                    font.pixelSize: 12
                }
                MouseArea {
                    id: wsPathMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        workshopPage.pathInputText = WorkshopManager.primaryWorkshopPath.replace(/\//g, "\\")
                        workshopPage.pathInputVisible = true
                        workshopPage.updatePathSuggestions()
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: autoLabel.implicitWidth + 40
                Layout.fillHeight: true
                radius: 8
                color: wsAutoMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.85) : HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.7)
                border.width: 1
                border.color: HusTheme.Primary.colorPrimary
                Behavior on color { ColorAnimation { duration: 150 } }
                Text {
                    id: autoLabel
                    anchors.centerIn: parent
                    text: WorkshopManager.scanning ? Lang.tr('检测中...','Checking...') : Lang.tr('自动检测','Auto-Detect')
                    color: HusTheme.Primary.colorBgBase
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    id: wsAutoMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: WorkshopManager.refresh()
                }
            }
        }


        Rectangle {
            id: wsListRect
            anchors.top: workshopConnected ? pathCard.bottom : toolRow.bottom
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            radius: 10
            color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.25)
            border.width: 1
            border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.4)
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
                            color: wsItemHover.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.18)
                                   : (modelData.installed ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.14)
                                                          : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.5))
                            border.width: wsItemHover.containsMouse ? 2 : 1
                            border.color: wsItemHover.containsMouse ? HusTheme.Primary.colorPrimary
                                   : (modelData.installed ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.3)
                                                          : HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.4))
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.width { NumberAnimation { duration: 120 } }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                width: 8; height: 8; radius: 4
                                color: modelData.installed ? HusTheme.Primary.colorPrimary : HusTheme.Primary.colorTextSecondary
                            }


                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 26
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.name
                                color: HusTheme.Primary.colorTextBase
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                width: parent.width - 190
                            }


                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: qsTr('ID: %1%2').arg(modelData.workshopId).arg(modelData.installed ? Lang.tr(' · 已安装',' · Installed') : Lang.tr(' · 未安装',' · Not Installed'))
                                color: modelData.installed ? HusTheme.Primary.colorPrimary : HusTheme.Primary.colorTextSecondary
                                font.pixelSize: 11
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
                            text: !workshopConnected ? Lang.tr('点击上方「连接」按钮加载创意工坊地图','Click Connect above to load workshop maps.')
                                  : (WorkshopManager.scanning ? Lang.tr('正在扫描本地工坊...','Scanning local workshop...') : Lang.tr('暂无地图','No maps'))
                            color: HusTheme.Primary.colorTextSecondary
                            font.pixelSize: 13
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: Lang.tr('本功能只读取 Steam 创意工坊地图列表，不会修改任何游戏文件','This only reads your Steam workshop list; no game files are modified.')
                            color: HusThemeFunctions.alpha(HusTheme.Primary.colorTextSecondary, 0.7)
                            font.pixelSize: 12
                        }
                    }
                }
            }


            Rectangle {
                anchors.right: parent.right; anchors.rightMargin: 2
                anchors.top: parent.top; anchors.topMargin: 4
                anchors.bottom: parent.bottom; anchors.bottomMargin: 4
                width: 5; radius: 2.5
                color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.4)
                visible: wsFlick.contentHeight > wsFlick.height + 1
            }


            Rectangle {
                anchors.right: parent.right; anchors.rightMargin: 2
                width: 5; radius: 2.5
                color: HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.5)
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
        color: HusThemeFunctions.alpha('#000000', 0.5)
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
            width: 400
            height: 210
            radius: 10
            color: HusTheme.Primary.colorBgContainer
            border.width: 1
            border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5)
            scale: pathInputVisible ? 1.0 : 0.88
            Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: Lang.tr('选择工坊地图路径','Choose Workshop Map Path')
                    color: HusTheme.Primary.colorTextBase
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                TextField {
                    id: pathField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    text: workshopPage.pathInputText
                    color: HusTheme.Primary.colorTextBase
                    placeholderTextColor: HusTheme.Primary.colorTextSecondary
                    font.pixelSize: 12
                    selectByMouse: true
                    background: Rectangle {
                        color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgBase, 0.5)
                        radius: 6
                        border.width: 1
                        border.color: pathField.activeFocus ? HusTheme.Primary.colorPrimary : HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5)
                    }
                    onTextChanged: workshopPage.updatePathSuggestions()
                    onActiveFocusChanged: {
                        if (activeFocus) workshopPage.updatePathSuggestions()
                        else { pathDropHideTimer.restart() }
                    }
                    onAccepted: {
                        if (text.trim().length > 0) {
                            WorkshopManager.setCustomPath(text.trim())
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
                    Layout.preferredHeight: 90
                    radius: 6
                    color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.8)
                    border.width: 1
                    border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.2)
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
                                    height: 26
                                    radius: 4
                                    color: pathDropItemMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.16) : 'transparent'
                                    Behavior on color { ColorAnimation { duration: 80 } }
                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData
                                        color: HusTheme.Primary.colorTextBase
                                        font.pixelSize: 11
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
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignRight
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 26
                        radius: 6
                        color: pathCancelMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.25) : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.6)
                        border.width: 1
                        border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5)
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text {
                            anchors.centerIn: parent
                            text: Lang.tr('取消','Cancel')
                            color: HusTheme.Primary.colorTextSecondary
                            font.pixelSize: 11
                        }
                        MouseArea {
                            id: pathCancelMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: pathInputVisible = false
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 26
                        radius: 6
                        color: pathOkMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.85) : HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.7)
                        border.width: 1
                        border.color: HusTheme.Primary.colorPrimary
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text {
                            anchors.centerIn: parent
                            text: Lang.tr('确定','OK')
                            color: HusTheme.Primary.colorBgBase
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }
                        MouseArea {
                            id: pathOkMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                var p = pathField.text.trim()
                                if (p.length > 0) {
                                    WorkshopManager.setCustomPath(p)
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
        color: HusTheme.Primary.colorBgContainer
        border.width: 1
        border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.3)
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
                color: ctxItem1.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.16) : 'transparent'
                Behavior on color { ColorAnimation { duration: 80 } }
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: Lang.tr('打开创意工坊地图','Open Workshop Map')
                    color: HusTheme.Primary.colorTextBase
                    font.pixelSize: 12
                }
                MouseArea {
                    id: ctxItem1
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        WorkshopManager.openWeb(ctxMapId)
                        closeCtxMenu()
                    }
                }
            }


            Rectangle {
                width: parent.width
                height: 38
                color: ctxItem2.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.16) : 'transparent'
                Behavior on color { ColorAnimation { duration: 80 } }
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: Lang.tr('复制地图名称','Copy Map Name')
                    color: HusTheme.Primary.colorTextBase
                    font.pixelSize: 12
                }
                MouseArea {
                    id: ctxItem2
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        WorkshopManager.copyName(ctxMapName)
                        closeCtxMenu()
                    }
                }
            }


            Rectangle {
                width: parent.width
                height: 38
                color: ctxItem3.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.16) : 'transparent'
                Behavior on color { ColorAnimation { duration: 80 } }
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: Lang.tr('复制地图ID','Copy Map ID')
                    color: HusTheme.Primary.colorTextBase
                    font.pixelSize: 12
                }
                MouseArea {
                    id: ctxItem3
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        WorkshopManager.copyId(ctxMapId)
                        closeCtxMenu()
                    }
                }
            }


            Rectangle {
                width: parent.width
                height: 38
                color: ctxItem4.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.16) : 'transparent'
                Behavior on color { ColorAnimation { duration: 80 } }
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: Lang.tr('打开地图文件夹位置','Open Map Folder')
                    color: HusTheme.Primary.colorTextBase
                    font.pixelSize: 12
                }
                MouseArea {
                    id: ctxItem4
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        WorkshopManager.openFolder(ctxMapPath)
                        closeCtxMenu()
                    }
                }
            }


            Rectangle {
                width: parent.width - 20
                height: 1
                color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5)
                anchors.horizontalCenter: parent.horizontalCenter
            }


            Rectangle {
                width: parent.width
                height: 38
                color: ctxItem5.containsMouse ? '#30FF4444' : 'transparent'
                Behavior on color { ColorAnimation { duration: 80 } }
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: Lang.tr('删除地图并重启Steam','Delete map and restart Steam')
                    color: '#FF8888'
                    font.pixelSize: 12
                }
                MouseArea {
                    id: ctxItem5
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        closeCtxMenu()
                        WorkshopManager.deleteMapAndRestartSteam(ctxMapPath)
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
        color: HusTheme.Primary.colorBgContainer
        border.width: 1
        border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.3)
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
            color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgBase, 0.7)
            border.width: 1
            border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5)
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
                color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgBase, 0.7)
                visible: true
                Text { anchors.centerIn: parent; text: Lang.tr('加载预览图...','Loading preview...'); color: HusTheme.Primary.colorTextSecondary; font.pixelSize: 12 }
            }

            Text {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: 8
                text: detailMapVpkName
                color: HusThemeFunctions.alpha(HusTheme.Primary.colorTextBase, 0.5)
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
                color: HusTheme.Primary.colorTextBase
                font.pixelSize: 18
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                wrapMode: Text.Wrap
                maximumLineCount: 2
            }


            Row {
                spacing: 6
                Rectangle {
                    width: 10; height: 10; radius: 5
                    color: detailMapInstalled ? HusTheme.Primary.colorPrimary : HusTheme.Primary.colorTextSecondary
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: detailMapInstalled ? Lang.tr('已安装','Installed') : Lang.tr('未安装','Not Installed')
                    color: detailMapInstalled ? HusTheme.Primary.colorPrimary : HusTheme.Primary.colorTextSecondary
                    font.pixelSize: 13
                }
            }

            Rectangle { width: parent.width; height: 1; color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5) }


            Row {
                spacing: 8
                Text { text: Lang.tr('工坊ID:','Workshop ID:'); color: HusTheme.Primary.colorTextSecondary; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                Text { text: detailMapId; color: HusTheme.Primary.colorTextBase; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
            }


            Row {
                width: parent.width
                spacing: 8
                Text { text: Lang.tr('工坊地址:','Workshop URL:'); color: HusTheme.Primary.colorTextSecondary; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    id: detailUrlText
                    text: "https://steamcommunity.com/sharedfiles/filedetails/?id=" + detailMapId
                    color: HusTheme.Primary.colorPrimary
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    width: parent.width - 70
                    anchors.verticalCenter: parent.verticalCenter
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: WorkshopManager.openWeb(detailMapId)
                        onEntered: detailUrlText.color = HusTheme.Primary.colorPrimary
                        onExited: detailUrlText.color = HusTheme.Primary.colorPrimary
                    }
                }
            }


            Row {
                spacing: 8
                Text { text: Lang.tr('地图文件:','Map File:'); color: HusTheme.Primary.colorTextSecondary; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                Text { text: detailMapVpkName + ".vpk"; color: HusTheme.Primary.colorTextBase; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; width: 200 }
            }


            Column {
                width: parent.width
                spacing: 4
                Text { text: Lang.tr('安装路径:','Install Path:'); color: HusTheme.Primary.colorTextSecondary; font.pixelSize: 12 }
                Text {
                    text: detailMapPath
                    color: HusTheme.Primary.colorTextBase
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
            text: Lang.tr('点击空白处关闭','Click empty area to close')
            color: HusTheme.Primary.colorTextSecondary
            font.pixelSize: 11
        }
    }
}
